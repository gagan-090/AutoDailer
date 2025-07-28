// lib/screens/leads/leads_screen.dart - REPLACE ORIGINAL FILE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/lead_provider.dart';
import '../../providers/call_provider.dart';
import '../../config/theme_config.dart';
import '../../models/lead_model.dart';
import 'lead_detail_screen.dart';
import '../dialer/auto_dialer_screen.dart';
import '../../services/whatsapp_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeadProvider>(context, listen: false).loadLeads();
    });
  }

  // Direct call functionality
  Future<void> _makeDirectCall(Lead lead) async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);

    try {
      final success = await callProvider.makeDirectCall(lead.phone);

      if (success && mounted) {
        // Show call started notification with quick action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.phone, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Calling ${lead.name}...'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Log Call',
              textColor: Colors.white,
              onPressed: () => _showQuickDispositionDialog(lead),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to make call: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAutoDialer(BuildContext context, List<Lead> leads) {
    if (leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leads available to call')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_mode, color: ThemeConfig.primaryColor),
            const SizedBox(width: 8),
            const Text('Start Auto Dialer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to start auto-dialing ${leads.length} leads?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Auto Dialer Features:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Automatically dials leads in sequence\n'
                    '• Configurable delays between calls\n'
                    '• Auto-progression after dispositions\n'
                    '• Skip leads or pause anytime\n'
                    '• Real-time progress tracking',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AutoDialerScreen(
                    initialLeads: leads,
                    startIndex: 0,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Auto Dialing'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leads'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LeadProvider>(context, listen: false)
                  .loadLeads(refresh: true);
            },
          ),
        ],
      ),
      body: Consumer<LeadProvider>(
        builder: (context, leadProvider, child) {
          if (leadProvider.isLoading && leadProvider.leads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (leadProvider.errorMessage != null) {
            return _buildErrorState(leadProvider);
          }

          return Column(
            children: [
              _buildSearchAndStats(leadProvider),
              Expanded(
                child: _buildLeadsList(leadProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<LeadProvider>(
        builder: (context, leadProvider, child) {
          final leads = leadProvider.filteredLeads;
          final newLeads = leads.where((lead) => lead.status == 'new').toList();
          final callbackLeads =
              leads.where((lead) => lead.status == 'callback').toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Auto Dialer FAB for All Leads
              if (leads.isNotEmpty)
                FloatingActionButton.extended(
                  onPressed: () => _startAutoDialer(context, leads),
                  backgroundColor: ThemeConfig.primaryColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_mode),
                  label: Text('Auto Dial (${leads.length})'),
                  heroTag: "auto_dial_all",
                ),

              if (newLeads.isNotEmpty) ...[
                const SizedBox(height: 12),
                // New Leads Only FAB
                FloatingActionButton.extended(
                  onPressed: () => _startAutoDialer(context, newLeads),
                  backgroundColor: ThemeConfig.successColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.fiber_new),
                  label: Text('New (${newLeads.length})'),
                  heroTag: "auto_dial_new",
                ),
              ],

              if (callbackLeads.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Callback Leads FAB
                FloatingActionButton.extended(
                  onPressed: () => _startAutoDialer(context, callbackLeads),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.schedule),
                  label: Text('Callbacks (${callbackLeads.length})'),
                  heroTag: "auto_dial_callback",
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndStats(LeadProvider leadProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search leads...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        leadProvider.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              leadProvider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'Total: ${leadProvider.filteredLeads.length}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  'New: ${leadProvider.getLeadsByStatus('new').length}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  'Callback: ${leadProvider.getLeadsByStatus('callback').length}',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLeadsList(LeadProvider leadProvider) {
    final leads = leadProvider.filteredLeads;

    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              leadProvider.searchQuery.isNotEmpty ||
                      leadProvider.statusFilter.isNotEmpty
                  ? 'No leads match your filters'
                  : 'No leads assigned yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                leadProvider.clearFilters();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => leadProvider.loadLeads(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return _buildEnhancedLeadCard(lead);
        },
      ),
    );
  }

  Widget _buildEnhancedLeadCard(Lead lead) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeadDetailScreen(lead: lead),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lead.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (lead.company != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lead.company!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lead.getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lead.getStatusColor().withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              lead.getStatusIcon(),
                              size: 14,
                              color: lead.getStatusColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lead.statusDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: lead.getStatusColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lead.callCount > 0) ...[
                            Icon(
                              Icons.phone_callback,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${lead.callCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(lead.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lead.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Enhanced Action buttons
              Row(
                children: [
                  // Call Button (Primary)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _makeDirectCall(lead),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendWhatsAppMessage(lead),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Update Status Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(lead),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(LeadProvider leadProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load leads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leadProvider.errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              leadProvider.clearError();
              leadProvider.loadLeads(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Send WhatsApp message to lead
  Future<void> _sendWhatsAppMessage(Lead lead) async {
    try {
      final success = await WhatsAppService.sendMessage(
        phoneNumber: lead.phone,
        message: WhatsAppService.getLeadMessage(
          leadName: lead.name,
          companyName: lead.company,
        ),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('WhatsApp opened for ${lead.name}'),
                ],
              ),
              backgroundColor: const Color(0xFF25D366),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open WhatsApp for ${lead.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateStatus(Lead lead) {
    showDialog(
      context: context,
      builder: (context) => _StatusUpdateDialog(lead: lead),
    );
  }

  void _showQuickDispositionDialog(Lead lead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickDispositionSheet(
        lead: lead,
        onDispositionSelected: (disposition, status) {
          Navigator.pop(context);
          _handleQuickDisposition(lead, disposition, status);
        },
      ),
    );
  }

  void _handleQuickDisposition(
      Lead lead, String disposition, String status) async {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);

    final success = await leadProvider.logCall(
      lead.id,
      disposition: disposition,
      leadStatus: status,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call logged for ${lead.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

// Quick Disposition Bottom Sheet
class _QuickDispositionSheet extends StatelessWidget {
  final Lead lead;
  final Function(String disposition, String status) onDispositionSelected;

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
          Row(
            children: [
              Icon(Icons.phone, color: ThemeConfig.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Log Call - ${lead.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick action buttons
          _buildQuickAction(
            'Interested',
            Icons.thumb_up,
            Colors.green,
            () => onDispositionSelected('interested', 'interested'),
          ),
          _buildQuickAction(
            'Not Interested',
            Icons.thumb_down,
            Colors.red,
            () => onDispositionSelected('not_interested', 'not_interested'),
          ),
          _buildQuickAction(
            'Callback Later',
            Icons.schedule,
            Colors.orange,
            () => onDispositionSelected('callback', 'callback'),
          ),
          _buildQuickAction(
            'Not Reachable',
            Icons.phone_disabled,
            Colors.grey,
            () => onDispositionSelected('not_reachable', 'not_reachable'),
          ),
          _buildQuickAction(
            'Wrong Number',
            Icons.error,
            Colors.brown,
            () => onDispositionSelected('wrong_number', 'wrong_number'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }
}

// Status Update Dialog
class _StatusUpdateDialog extends StatefulWidget {
  final Lead lead;

  const _StatusUpdateDialog({required this.lead});

  @override
  State<_StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<_StatusUpdateDialog> {
  String? _selectedStatus;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _statusOptions = [
    {'value': 'contacted', 'label': 'Contacted'},
    {'value': 'interested', 'label': 'Interested'},
    {'value': 'not_interested', 'label': 'Not Interested'},
    {'value': 'callback', 'label': 'Callback Later'},
    {'value': 'wrong_number', 'label': 'Wrong Number'},
    {'value': 'not_reachable', 'label': 'Not Reachable'},
    {'value': 'converted', 'label': 'Converted'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.lead.status;
    _notesController.text = widget.lead.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: ThemeConfig.primaryColor),
          const SizedBox(width: 8),
          Text('Update ${widget.lead.name}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status['value'],
                child: Text(status['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Add notes...',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateLead,
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConfig.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateLead() async {
    if (_selectedStatus == null) return;

    final leadProvider = Provider.of<LeadProvider>(context, listen: false);

    final success = await leadProvider.updateLeadStatus(
      widget.lead.id,
      _selectedStatus!,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leadProvider.errorMessage ?? 'Failed to update lead'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Filter Dialog
class _FilterDialog extends StatefulWidget {
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String _selectedStatus = '';

  final List<Map<String, String>> _statusOptions = [
    {'value': '', 'label': 'All Statuses'},
    {'value': 'new', 'label': 'New'},
    {'value': 'contacted', 'label': 'Contacted'},
    {'value': 'interested', 'label': 'Interested'},
    {'value': 'callback', 'label': 'Callback Later'},
    {'value': 'not_interested', 'label': 'Not Interested'},
    {'value': 'converted', 'label': 'Converted'},
    {'value': 'wrong_number', 'label': 'Wrong Number'},
    {'value': 'not_reachable', 'label': 'Not Reachable'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus =
        Provider.of<LeadProvider>(context, listen: false).statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.filter_list, color: ThemeConfig.primaryColor),
          const SizedBox(width: 8),
          const Text('Filter Leads'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _statusOptions.map((status) {
          return RadioListTile<String>(
            title: Text(status['label']!),
            value: status['value']!,
            groupValue: _selectedStatus,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
            activeColor: ThemeConfig.primaryColor,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Provider.of<LeadProvider>(context, listen: false)
                .setStatusFilter(_selectedStatus);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConfig.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
