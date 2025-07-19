// lib/screens/dialer/auto_dialer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/lead_provider.dart';
import '../../config/theme_config.dart';
import '../../models/lead_model.dart';
import '../../services/dialer_service.dart';
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
  List<Lead> _leads = [];
  int _currentIndex = 0;
  bool _isDialing = false;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    _leads = widget.initialLeads ?? leadProvider.filteredLeads;
    _currentIndex = widget.startIndex;
  }

  Lead? get currentLead => _currentIndex < _leads.length ? _leads[_currentIndex] : null;
  int get remainingLeads => _leads.length - _currentIndex;
  double get progress => _leads.isNotEmpty ? _currentIndex / _leads.length : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Dialer'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _showStopConfirmation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          _buildProgressHeader(),
          
          // Current Lead or Completion
          Expanded(
            child: currentLead != null
                ? _buildCurrentLeadCard(currentLead!)
                : _buildCompletionState(),
          ),
          
          // Control Buttons
          _buildControlButtons(),
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
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/${_leads.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Remaining',
                remainingLeads.toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatItem(
                'Completed',
                _currentIndex.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Progress',
                '${(progress * 100).toStringAsFixed(0)}%',
                Icons.trending_up,
                ThemeConfig.primaryColor,
              ),
            ],
          ),
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
          // Lead Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Lead Avatar and Status
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
                  
                  // Lead Name
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Phone Number
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
                  
                  const SizedBox(height: 12),
                  
                  // Company (if available)
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
                  
                  // Status Badge
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
          
          // Lead Details
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
          
          // Notes (if available)
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
          
          // Call Timer (if call is active)
          if (_callStartTime != null) ...[
            const SizedBox(height: 16),
            _buildCallTimer(),
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

  Widget _buildCallTimer() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_in_talk, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Call Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                if (_callStartTime == null) return const Text('00:00');
                
                final duration = DateTime.now().difference(_callStartTime!);
                final minutes = duration.inMinutes;
                final seconds = duration.inSeconds % 60;
                final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                
                return Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                );
              },
            ),
          ],
        ),
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
            'Great job! You\'ve called all leads in the queue.',
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
            if (currentLead != null) ...[
              // Primary Call Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _callStartTime != null
                      ? _markCallEnded
                      : () => _makeCall(currentLead!),
                  icon: Icon(
                    _callStartTime != null ? Icons.call_end : Icons.phone,
                    size: 24,
                  ),
                  label: Text(
                    _callStartTime != null ? 'End Call' : 'Call Now',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _callStartTime != null 
                        ? Colors.red 
                        : ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Secondary Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skipLead,
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
                      onPressed: () => _showQuickDisposition(currentLead!),
                      icon: const Icon(Icons.edit),
                      label: const Text('Quick Update'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Back Button when completed
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

  void _makeCall(Lead lead) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: ThemeConfig.primaryColor),
            const SizedBox(width: 8),
            const Text('Make Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Call ${lead.name}?'),
            const SizedBox(height: 8),
            Text(
              lead.phone,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will open your phone dialer. Tap "End Call" when finished.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Make the actual call using dialer service
      final dialerService = DialerService();
      final success = await dialerService.makeCall(lead.phone);
      
      if (success) {
        // Mark call as started
        setState(() {
          _callStartTime = DateTime.now();
          _isDialing = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _markCallEnded() {
    setState(() {
      _callStartTime = null;
      _isDialing = false;
    });

    // Show disposition dialog
    if (currentLead != null) {
      _showDispositionDialog(currentLead!);
    }
  }

  void _skipLead() {
    setState(() {
      _currentIndex++;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead skipped')),
    );
  }

  void _showDispositionDialog(Lead lead) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DispositionDialog(
        lead: lead,
        onDispositionSaved: _onDispositionSaved,
      ),
    );
  }

  void _onDispositionSaved() {
    // Move to next lead after disposition is saved
    setState(() {
      _currentIndex++;
    });
  }

  void _showQuickDisposition(Lead lead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickDispositionSheet(
        lead: lead,
        onDispositionSelected: (disposition) {
          Navigator.pop(context);
          _handleQuickDisposition(lead, disposition);
        },
      ),
    );
  }

  void _handleQuickDisposition(Lead lead, String disposition) async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    
    // Map disposition to lead status
    final statusMap = {
      'interested': 'interested',
      'not_interested': 'not_interested',
      'callback': 'callback',
      'not_reachable': 'not_reachable',
    };
    
    final success = await callProvider.logCallDisposition(
      leadId: lead.id,
      disposition: disposition,
      newLeadStatus: statusMap[disposition],
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lead updated as ${statusMap[disposition]}')),
      );
      
      // Move to next lead
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _showStopConfirmation(BuildContext context) {
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
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Quick Disposition Bottom Sheet
class _QuickDispositionSheet extends StatelessWidget {
  final Lead lead;
  final Function(String) onDispositionSelected;

  const _QuickDispositionSheet({
    required this.lead,
    required this.onDispositionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Update - ${lead.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick action buttons
          _buildQuickAction(
            'Interested',
            Icons.thumb_up,
            Colors.green,
            () => onDispositionSelected('interested'),
          ),
          _buildQuickAction(
            'Not Interested',
            Icons.thumb_down,
            Colors.red,
            () => onDispositionSelected('not_interested'),
          ),
          _buildQuickAction(
            'Callback Later',
            Icons.schedule,
            Colors.orange,
            () => onDispositionSelected('callback'),
          ),
          _buildQuickAction(
            'Not Reachable',
            Icons.phone_disabled,
            Colors.grey,
            () => onDispositionSelected('not_reachable'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}