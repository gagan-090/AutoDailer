// lib/screens/dialer/auto_dialer_screen.dart - FIXED COMPLETE VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/call_provider.dart';
import '../../providers/lead_provider.dart';
import '../../config/theme_config.dart';
import '../../models/lead_model.dart';
import '../../services/auto_dialer_service.dart';
import 'disposition_dialog.dart';

class AutoDialerScreen extends StatefulWidget {
  final List<Lead>? initialLeads;
  final int startIndex;

  const AutoDialerScreen({
    super.key,
    this.initialLeads,
    this.startIndex = 0,
  });

  @override
  State<AutoDialerScreen> createState() => _AutoDialerScreenState();
}

class _AutoDialerScreenState extends State<AutoDialerScreen> {
  final AutoDialerService _dialerService = AutoDialerService();
  List<Lead> _leads = [];
  
  // Stream subscriptions
  StreamSubscription<AutoDialerState>? _stateSubscription;
  StreamSubscription<AutoDialerEvent>? _eventSubscription;
  
  // Current state
  AutoDialerState _currentState = AutoDialerState(
    isActive: false,
    isCallInProgress: false,
    currentIndex: 0,
    totalLeads: 0,
    remainingLeads: 0,
    autoDialDelay: 10,
    autoRedialEnabled: true,
    callConnectionConfirmed: false,
    callDuration: null,
  );
  
  // Countdown timer for next call
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    _leads = widget.initialLeads ?? leadProvider.filteredLeads;
    
    // Listen to dialer service streams
    _stateSubscription = _dialerService.stateStream.listen(_onStateChanged);
    _eventSubscription = _dialerService.eventStream.listen(_onEvent);
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onStateChanged(AutoDialerState state) {
    setState(() {
      _currentState = state;
    });
  }

  void _onEvent(AutoDialerEvent event) {
    if (event is DialingStarted) {
      _showCallStartedSnackbar(event.lead);
    } else if (event is CallConnected) {
      _showCallConnectedDialog(event.lead);
    } else if (event is DialingFailed) {
      _showDialingFailedSnackbar(event.lead);
    } else if (event is LeadSkipped) {
      _showLeadSkippedSnackbar(event.lead);
    } else if (event is PreparingNextCall) {
      _startCountdown(event.delay);
    } else if (event is AllLeadsCompleted) {
      _showCompletionDialog();
    } else if (event is AutoDialerError) {
      _showErrorSnackbar(event.message);
    }
  }

  void _startCountdown(int seconds) {
    _countdownSeconds = seconds;
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Dialer'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _currentState.isActive ? _showStopConfirmation : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          if (_currentState.isCallInProgress) _buildCallStatusBanner(),
          Expanded(
            child: _currentState.currentLead != null
                ? _buildCurrentLeadCard(_currentState.currentLead!)
                : _buildCompletionState(),
          ),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildCallStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CALL IN PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calling ${_currentState.currentLead?.name ?? ""}...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _dialerService.confirmCallConnection(),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Connected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _dialerService.reportCallFailed(),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Failed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showDispositionDialog(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[100],
                  foregroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _currentState.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentState.currentIndex}/${_currentState.totalLeads}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Remaining',
                _currentState.remainingLeads.toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatItem(
                'Completed',
                _currentState.currentIndex.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Auto Delay',
                '${_currentState.autoDialDelay}s',
                Icons.timer,
                ThemeConfig.primaryColor,
              ),
            ],
          ),
          if (_countdownSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Next call in $_countdownSeconds seconds',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _countdownTimer?.cancel();
                      _countdownSeconds = 0;
                      _dialerService.dialCurrentLead();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Call Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLeadCard(Lead lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: lead.getStatusColor().withOpacity(0.1),
                    child: Icon(
                      lead.getStatusIcon(),
                      color: lead.getStatusColor(),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: ThemeConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lead.phone,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ThemeConfig.primaryColor,
                          ),
                        ),
                      ),
                      if (_currentState.isCallInProgress) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'CALLING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (lead.company != null) ...[
                    Text(
                      lead.company!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: lead.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lead.getStatusColor().withOpacity(0.3)),
                    ),
                    child: Text(
                      lead.statusDisplay,
                      style: TextStyle(
                        color: lead.getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lead Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Email', lead.email ?? 'Not provided'),
                  _buildInfoRow('Source', lead.source ?? 'Unknown'),
                  _buildInfoRow('Calls Made', lead.callCount.toString()),
                  _buildInfoRow('Last Call', lead.lastCallDisposition ?? 'None'),
                ],
              ),
            ),
          ),
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lead.notes!,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'All Leads Completed!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Great job! You\'ve completed all leads in the queue.',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_currentState.currentLead != null && _currentState.isActive) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _currentState.isCallInProgress
                      ? _showDispositionDialog
                      : _dialCurrentLead,
                  icon: Icon(
                    _currentState.isCallInProgress ? Icons.edit : Icons.phone,
                    size: 24,
                  ),
                  label: Text(
                    _currentState.isCallInProgress ? 'Update Disposition' : 'Call Now',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentState.isCallInProgress 
                        ? Colors.orange
                        : ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skipCurrentLead,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSettingsDialog,
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!_currentState.isActive) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _leads.isNotEmpty ? _startAutoDialing : null,
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: Text(
                    'Start Auto Dialing (${_leads.length} leads)',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'How Auto-Dialing Works',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Tap "Call Now" to open dialer with number\n'
                      '• Make your call manually\n'
                      '• Return to app and update disposition\n'
                      '• App will automatically move to next lead\n'
                      '• Configurable delay between calls',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 24),
                  label: const Text(
                    'Back to Leads',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Action methods
  void _startAutoDialing() {
    _dialerService.startAutoDialing(_leads, startIndex: widget.startIndex);
  }

  void _dialCurrentLead() {
    _dialerService.dialCurrentLead();
  }

  void _skipCurrentLead() {
    _dialerService.skipCurrentLead();
  }

  void _showDispositionDialog() {
    if (_currentState.currentLead != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DispositionDialog(
          lead: _currentState.currentLead!,
          onDispositionSaved: () {
            _dialerService.onDispositionSaved();
          },
        ),
      );
    }
  }

  void _showCallConnectedDialog(Lead lead) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Call Connected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connected to ${lead.name}'),
            const SizedBox(height: 16),
            const Text(
              'Please update the call disposition after your conversation.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDispositionDialog();
            },
            child: const Text('Update Disposition'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _AutoDialerSettingsDialog(
        currentDelay: _currentState.autoDialDelay,
        autoRedialEnabled: _currentState.autoRedialEnabled,
        onSettingsChanged: (delay, autoRedial) {
          _dialerService.setAutoDialDelay(delay);
          _dialerService.setAutoRedialEnabled(autoRedial);
        },
      ),
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Auto Dialer'),
        content: const Text(
          'Are you sure you want to stop the auto dialer? You can restart from where you left off later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dialerService.stopAutoDialing();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('All Leads Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Congratulations! You have successfully called all leads in the queue.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Session Summary',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Leads: ${_currentState.totalLeads}\n'
                    'Completed: ${_currentState.currentIndex}\n'
                    'Auto Delay Used: ${_currentState.autoDialDelay} seconds',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Leads'),
          ),
        ],
      ),
    );
  }

  // Snackbar methods
  void _showCallStartedSnackbar(Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Opening dialer for ${lead.name}...')),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Return',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showDialingFailedSnackbar(Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to call ${lead.name}')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLeadSkippedSnackbar(Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.skip_next, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Skipped ${lead.name}')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Settings Dialog
class _AutoDialerSettingsDialog extends StatefulWidget {
  final int currentDelay;
  final bool autoRedialEnabled;
  final Function(int delay, bool autoRedial) onSettingsChanged;

  const _AutoDialerSettingsDialog({
    required this.currentDelay,
    required this.autoRedialEnabled,
    required this.onSettingsChanged,
  });

  @override
  State<_AutoDialerSettingsDialog> createState() => _AutoDialerSettingsDialogState();
}

class _AutoDialerSettingsDialogState extends State<_AutoDialerSettingsDialog> {
  late int _selectedDelay;
  late bool _autoRedialEnabled;

  final List<int> _delayOptions = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _selectedDelay = widget.currentDelay;
    _autoRedialEnabled = widget.autoRedialEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: ThemeConfig.primaryColor),
          const SizedBox(width: 8),
          const Text('Auto Dialer Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.autorenew, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto Progression',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Automatically move to next lead after disposition',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoRedialEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoRedialEnabled = value;
                      });
                    },
                    activeColor: ThemeConfig.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_autoRedialEnabled) ...[
              const Text(
                'Auto Progression Delay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Time to wait before moving to the next lead:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ..._delayOptions.map((delay) {
                return RadioListTile<int>(
                  title: Text('$delay seconds'),
                  subtitle: Text(_getDelayDescription(delay)),
                  value: delay,
                  groupValue: _selectedDelay,
                  onChanged: (value) {
                    setState(() {
                      _selectedDelay = value!;
                    });
                  },
                  activeColor: ThemeConfig.primaryColor,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'With auto progression disabled, you\'ll need to manually move to the next lead.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingsChanged(_selectedDelay, _autoRedialEnabled);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getDelayDescription(int delay) {
    switch (delay) {
      case 5:
        return 'Very fast';
      case 10:
        return 'Fast (Recommended)';
      case 15:
        return 'Moderate';
      case 20:
        return 'Slow';
      case 30:
        return 'Very slow';
      default:
        return '';
    }
  }
}

