// lib/screens/dialer/auto_dialer_screen.dart - MODERN ELEGANT AUTO DIALER
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/lead_provider.dart';
import '../../providers/follow_up_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';
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
      backgroundColor: ThemeConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Auto Dialer'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimationUtils.rippleEffect(
            onTap: _showSettingsDialog,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.settings_rounded),
            ),
          ),
          AnimationUtils.rippleEffect(
            onTap:
                _currentState.isActive ? () => _showStopConfirmation() : null,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                Icons.stop_rounded,
                color: _currentState.isActive ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Progress Header
            AnimationUtils.slideUp(
              child: _buildProgressHeader(),
              delay: const Duration(milliseconds: 100),
            ),

            // Call Status Banner
            if (_currentState.isCallInProgress)
              AnimationUtils.slideUp(
                child: _buildCallStatusBanner(),
                delay: const Duration(milliseconds: 200),
              ),

            // Main Content
            Expanded(
              child: _currentState.currentLead != null
                  ? AnimationUtils.slideUp(
                      child: _buildCurrentLeadCard(_currentState.currentLead!),
                      delay: const Duration(milliseconds: 300),
                    )
                  : AnimationUtils.slideUp(
                      child: _buildCompletionState(),
                      delay: const Duration(milliseconds: 300),
                    ),
            ),

            // Modern Control Buttons
            AnimationUtils.slideUp(
              child: _buildControlButtons(),
              delay: const Duration(milliseconds: 400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallStatusBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeConfig.spacingM),
      padding: const EdgeInsets.all(ThemeConfig.spacingL),
      decoration: BoxDecoration(
        gradient: ThemeConfig.successGradient,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        boxShadow: ThemeConfig.elevatedShadow,
      ),
      child: Column(
        children: [
          // Call Status Header
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
              const SizedBox(width: ThemeConfig.spacingS),
              const Text(
                'CALL IN PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingS),
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

          const SizedBox(height: ThemeConfig.spacingS),

          Text(
            'Calling ${_currentState.currentLead?.name ?? ""}...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: ThemeConfig.spacingL),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AnimationUtils.rippleEffect(
                  onTap: () => _dialerService.confirmCallConnection(),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingM,
                      vertical: ThemeConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: ThemeConfig.successColor,
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: ThemeConfig.successColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingS),
              Expanded(
                child: AnimationUtils.rippleEffect(
                  onTap: () => _dialerService.reportCallFailed(),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingM,
                      vertical: ThemeConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                      border: Border.all(
                        color: ThemeConfig.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: ThemeConfig.errorColor,
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        const Text(
                          'Failed',
                          style: TextStyle(
                            color: ThemeConfig.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingS),
              Expanded(
                child: AnimationUtils.rippleEffect(
                  onTap: () => _showDispositionDialog(),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingM,
                      vertical: ThemeConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                      border: Border.all(
                        color: ThemeConfig.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: ThemeConfig.warningColor,
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        const Text(
                          'Update',
                          style: TextStyle(
                            color: ThemeConfig.warningColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      margin: const EdgeInsets.all(ThemeConfig.spacingM),
      padding: const EdgeInsets.all(ThemeConfig.spacingL),
      decoration: BoxDecoration(
        color: ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        boxShadow: ThemeConfig.cardShadow,
      ),
      child: Column(
        children: [
          // Progress Bar with Counter
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: ThemeConfig.secondaryColor,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _currentState.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: ThemeConfig.accentGradient,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConfig.spacingM,
                  vertical: ThemeConfig.spacingS,
                ),
                decoration: BoxDecoration(
                  color: ThemeConfig.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                ),
                child: Text(
                  '${_currentState.currentIndex}/${_currentState.totalLeads}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ThemeConfig.accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ThemeConfig.spacingL),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 0,
                  child: _buildStatItem(
                    'Remaining',
                    _currentState.remainingLeads,
                    Icons.schedule_rounded,
                    ThemeConfig.warningColor,
                  ),
                ),
              ),
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 1,
                  child: _buildStatItem(
                    'Completed',
                    _currentState.currentIndex,
                    Icons.check_circle_rounded,
                    ThemeConfig.successColor,
                  ),
                ),
              ),
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 2,
                  child: _buildStatItem(
                    'Auto Delay',
                    _currentState.autoDialDelay,
                    Icons.timer_rounded,
                    ThemeConfig.infoColor,
                  ),
                ),
              ),
            ],
          ),

          // Countdown Timer
          if (_countdownSeconds > 0) ...[
            const SizedBox(height: ThemeConfig.spacingL),
            AnimationUtils.scaleIn(
              child: Container(
                padding: const EdgeInsets.all(ThemeConfig.spacingM),
                decoration: BoxDecoration(
                  color: ThemeConfig.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                  border: Border.all(
                    color: ThemeConfig.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ThemeConfig.spacingS),
                      decoration: BoxDecoration(
                        color: ThemeConfig.warningColor.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(ThemeConfig.radiusS),
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: ThemeConfig.warningColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: ThemeConfig.spacingM),
                    Expanded(
                      child: Text(
                        'Next call in $_countdownSeconds seconds',
                        style: const TextStyle(
                          color: ThemeConfig.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimationUtils.rippleEffect(
                      onTap: () {
                        _countdownTimer?.cancel();
                        _countdownSeconds = 0;
                        _dialerService.dialCurrentLead();
                      },
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConfig.spacingM,
                          vertical: ThemeConfig.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConfig.warningColor,
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.radiusS),
                        ),
                        child: const Text(
                          'Call Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ThemeConfig.spacingS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: ThemeConfig.spacingS),
          AnimationUtils.animatedCounter(
            value: value,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ThemeConfig.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLeadCard(Lead lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConfig.spacingM),
      child: Column(
        children: [
          // Main Lead Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ThemeConfig.spacingXL),
            decoration: BoxDecoration(
              color: ThemeConfig.cardColor,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
              boxShadow: ThemeConfig.elevatedShadow,
            ),
            child: Column(
              children: [
                // Lead Avatar with Status Badge
                Stack(
                  children: [
                    AnimationUtils.bounceIn(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              lead.getStatusColor(),
                              lead.getStatusColor().withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  lead.getStatusColor().withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            lead.name.isNotEmpty
                                ? lead.name[0].toUpperCase()
                                : 'L',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      delay: const Duration(milliseconds: 200),
                    ),

                    // Status Badge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConfig.spacingS,
                          vertical: ThemeConfig.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: lead.getStatusColor(),
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.radiusS),
                          boxShadow: ThemeConfig.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              lead.getStatusIcon(),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: ThemeConfig.spacingXS),
                            Text(
                              lead.statusDisplay.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: ThemeConfig.spacingL),

                // Lead Name
                Text(
                  lead.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: ThemeConfig.spacingM),

                // Phone Number with Call Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeConfig.spacingL,
                        vertical: ThemeConfig.spacingM,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeConfig.backgroundColor,
                        borderRadius:
                            BorderRadius.circular(ThemeConfig.radiusL),
                        border: Border.all(
                          color: ThemeConfig.accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        lead.phone,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (_currentState.isCallInProgress) ...[
                      const SizedBox(width: ThemeConfig.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConfig.spacingM,
                          vertical: ThemeConfig.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConfig.successColor,
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.radiusS),
                          boxShadow: ThemeConfig.cardShadow,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: ThemeConfig.spacingXS),
                            Text(
                              'CALLING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                if (lead.company != null) ...[
                  const SizedBox(height: ThemeConfig.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingM,
                      vertical: ThemeConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: ThemeConfig.infoColor,
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        Text(
                          lead.company!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ThemeConfig.infoColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: ThemeConfig.spacingL),

          // Lead Information Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ThemeConfig.spacingL),
            decoration: BoxDecoration(
              color: ThemeConfig.cardColor,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
              boxShadow: ThemeConfig.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lead Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: ThemeConfig.spacingL),
                _buildInfoRow('Email', lead.email ?? 'Not provided'),
                _buildInfoRow('Source', lead.source ?? 'Unknown'),
                _buildInfoRow('Calls Made', lead.callCount.toString()),
                _buildInfoRow('Last Call', lead.lastCallDisposition ?? 'None'),
              ],
            ),
          ),

          // Notes Card
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: ThemeConfig.spacingL),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ThemeConfig.spacingL),
              decoration: BoxDecoration(
                color: ThemeConfig.cardColor,
                borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                boxShadow: ThemeConfig.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ThemeConfig.spacingS),
                        decoration: BoxDecoration(
                          color:
                              ThemeConfig.warningColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.radiusS),
                        ),
                        child: const Icon(
                          Icons.note_rounded,
                          size: 16,
                          color: ThemeConfig.warningColor,
                        ),
                      ),
                      const SizedBox(width: ThemeConfig.spacingM),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeConfig.spacingM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(ThemeConfig.spacingM),
                    decoration: BoxDecoration(
                      color: ThemeConfig.backgroundColor,
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: Text(
                      lead.notes!,
                      style: const TextStyle(
                        color: ThemeConfig.textSecondary,
                        height: 1.5,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeConfig.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ThemeConfig.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConfig.textPrimary,
                fontWeight: FontWeight.w500,
              ),
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
            if (_currentState.currentLead != null &&
                _currentState.isActive) ...[
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
                    _currentState.isCallInProgress
                        ? 'Update Disposition'
                        : 'Call Now',
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
              // ADDED: Always show disposition button when active
              if (!_currentState.isCallInProgress) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _showDispositionDialog,
                    icon: const Icon(Icons.edit_note, size: 24),
                    label: const Text(
                      'Update Disposition',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // NEW: Schedule Follow-up Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showScheduleFollowUpDialog,
                  icon: const Icon(Icons.schedule, size: 24),
                  label: const Text(
                    'Schedule Follow-up',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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

  // NEW: Schedule Follow-up Dialog
  void _showScheduleFollowUpDialog() {
    if (_currentState.currentLead == null) return;

    final lead = _currentState.currentLead!;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final TextEditingController remarksController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: const Icon(Icons.schedule, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Follow-up',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      lead.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Selection
                const Text(
                  'Follow-up Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Selection
                const Text(
                  'Follow-up Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Remarks
                const Text(
                  'Follow-up Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add notes for the follow-up call...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Options
                const Text(
                  'Quick Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Tomorrow 10 AM'),
                      onPressed: () {
                        setState(() {
                          selectedDate =
                              DateTime.now().add(const Duration(days: 1));
                          selectedTime = const TimeOfDay(hour: 10, minute: 0);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Next Week'),
                      onPressed: () {
                        setState(() {
                          selectedDate =
                              DateTime.now().add(const Duration(days: 7));
                          selectedTime = const TimeOfDay(hour: 10, minute: 0);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Next Month'),
                      onPressed: () {
                        setState(() {
                          selectedDate =
                              DateTime.now().add(const Duration(days: 30));
                          selectedTime = const TimeOfDay(hour: 10, minute: 0);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Save follow-up
                await _saveFollowUp(
                  lead,
                  selectedDate,
                  selectedTime,
                  remarksController.text.trim(),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Save Follow-up Method
  Future<void> _saveFollowUp(
      Lead lead, DateTime date, TimeOfDay time, String remarks) async {
    try {
      final followUpDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Format time for API (HH:mm format)
      final timeString =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      // Use your follow-up provider to create follow-up
      final followUpProvider =
          Provider.of<FollowUpProvider>(context, listen: false);

      final success = await followUpProvider.createFollowUp(
        leadId: lead.id,
        followUpDate: followUpDateTime,
        followUpTime: timeString,
        remarks:
            remarks.isEmpty ? 'Follow-up scheduled from auto dialer' : remarks,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Follow-up scheduled for ${lead.name} on ${date.day}/${date.month}/${date.year} at ${time.format(context)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Refresh follow-ups list
        await followUpProvider.loadFollowUps(refresh: true);
      } else if (mounted) {
        final errorMsg = followUpProvider.errorMessage ??
            'Failed to schedule follow-up. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
            const Text(
                'Congratulations! You have successfully called all leads in the queue.'),
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
  State<_AutoDialerSettingsDialog> createState() =>
      _AutoDialerSettingsDialogState();
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
