// lib/screens/leads/leads_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lead_provider.dart';
import '../../config/theme_config.dart';
import '../../models/lead_model.dart';
import 'lead_detail_screen.dart';
import '../dialer/auto_dialer_screen.dart';

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
            Icon(Icons.play_arrow, color: ThemeConfig.primaryColor),
            const SizedBox(width: 8),
            const Text('Start Auto Dialer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to start calling ${leads.length} leads?'),
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
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'How it works:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• App will guide you through each lead\n'
                    '• Tap "Call Now" to open your phone dialer\n'
                    '• After each call, update the disposition\n'
                    '• Automatically moves to the next lead',
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
            child: const Text('Start Dialing'),
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Auto Dialer FAB
              FloatingActionButton.extended(
                onPressed: leads.isNotEmpty
                    ? () => _startAutoDialer(context, leads)
                    : null,
                backgroundColor:
                    leads.isNotEmpty ? ThemeConfig.primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.play_arrow),
                label: Text('Auto Dial (${leads.length})'),
                heroTag: "auto_dial",
              ),
              if (newLeads.isNotEmpty) ...[
                const SizedBox(height: 12),
                // New Leads Only FAB
                FloatingActionButton.extended(
                  onPressed: () => _startAutoDialer(context, newLeads),
                  backgroundColor: ThemeConfig.successColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.fiber_new),
                  label: Text('New Only (${newLeads.length})'),
                  heroTag: "new_leads",
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
          return _buildLeadCard(lead);
        },
      ),
    );
  }

  Widget _buildLeadCard(Lead lead) {
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
                        Text(
                          lead.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (lead.company != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            lead.company!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              Icons.phone,
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
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(lead),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(lead),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _makeCall(Lead lead) {
    // TODO: Implement calling functionality in Phase 3
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Feature'),
        content: Text(
            'Calling functionality will be implemented in Phase 3.\n\nFor now, you can manually call: ${lead.phone}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(Lead lead) {
    showDialog(
      context: context,
      builder: (context) => _StatusUpdateDialog(lead: lead),
    );
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
      title: Text('Update ${widget.lead.name}'),
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
          const SnackBar(content: Text('Lead updated successfully')),
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
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = Provider.of<LeadProvider>(context, listen: false).statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Leads'),
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
          child: const Text('Apply'),
        ),
      ],
    );
  }
}