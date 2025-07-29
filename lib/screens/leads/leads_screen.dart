// lib/screens/leads/leads_screen.dart - MODERN ELEGANT LEADS SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/lead_provider.dart';
import '../../providers/call_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leads available to call')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.spacingS),
              decoration: BoxDecoration(
                color: ThemeConfig.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
              ),
              child: const Icon(
                Icons.auto_mode_rounded,
                color: ThemeConfig.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: ThemeConfig.spacingM),
            Text(
              'Start Auto Dialer',
              style: TextStyle(
                color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to start auto-dialing ${leads.length} leads?',
              style: TextStyle(
                color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingL),
            Container(
              padding: const EdgeInsets.all(ThemeConfig.spacingL),
              decoration: BoxDecoration(
                color: ThemeConfig.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
                border: Border.all(
                  color: ThemeConfig.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: ThemeConfig.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: ThemeConfig.spacingS),
                      Text(
                        'Auto Dialer Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeConfig.spacingM),
                  Text(
                    '• Automatically dials leads in sequence\n'
                    '• Configurable delays between calls\n'
                    '• Auto-progression after dispositions\n'
                    '• Skip leads or pause anytime\n'
                    '• Real-time progress tracking',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      AutoDialerScreen(
                    initialLeads: leads,
                    startIndex: 0,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Auto Dialing'),
            style: ThemeConfig.primaryButtonStyle,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Leads'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          AnimationUtils.rippleEffect(
            onTap: _showFilterDialog,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.filter_list_rounded),
            ),
          ),
          AnimationUtils.rippleEffect(
            onTap: () {
              Provider.of<LeadProvider>(context, listen: false)
                  .loadLeads(refresh: true);
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: Consumer<LeadProvider>(
        builder: (context, leadProvider, child) {
          if (leadProvider.isLoading && leadProvider.leads.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.secondary,
              ),
            );
          }

          if (leadProvider.errorMessage != null) {
            return _buildErrorState(leadProvider);
          }

          return SafeArea(
            child: Column(
              children: [
                AnimationUtils.slideUp(
                  child: _buildSearchAndStats(leadProvider),
                  delay: const Duration(milliseconds: 100),
                ),
                Expanded(
                  child: _buildLeadsList(leadProvider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAnimatedFABs(),
    );
  }

  Widget _buildSearchAndStats(LeadProvider leadProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.spacingM),
      child: Column(
        children: [
          // Modern Search bar
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
              boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search leads...',
                hintStyle: TextStyle(color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? AnimationUtils.rippleEffect(
                        onTap: () {
                          _searchController.clear();
                          leadProvider.setSearchQuery('');
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ThemeConfig.spacingM,
                  vertical: ThemeConfig.spacingM,
                ),
              ),
              onChanged: (value) {
                leadProvider.setSearchQuery(value);
              },
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingM),
          // Modern Stats Chips
          Row(
            children: [
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 0,
                  child: _buildStatChip(
                    'Total',
                    leadProvider.filteredLeads.length,
                    ThemeConfig.infoColor,
                  ),
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingS),
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 1,
                  child: _buildStatChip(
                    'New',
                    leadProvider.getLeadsByStatus('new').length,
                    ThemeConfig.successColor,
                  ),
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingS),
              Expanded(
                child: AnimationUtils.staggeredListItem(
                  index: 2,
                  child: _buildStatChip(
                    'Callback',
                    leadProvider.getLeadsByStatus('callback').length,
                    ThemeConfig.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ThemeConfig.spacingS,
        horizontal: ThemeConfig.spacingM,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          AnimationUtils.animatedCounter(
            value: count,
            textStyle: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList(LeadProvider leadProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final leads = leadProvider.filteredLeads;

    if (leads.isEmpty) {
      return Center(
        child: AnimationUtils.slideUp(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
              ),
              const SizedBox(height: ThemeConfig.spacingL),
              Text(
                leadProvider.searchQuery.isNotEmpty ||
                        leadProvider.statusFilter.isNotEmpty
                    ? 'No leads match your filters'
                    : 'No leads assigned yet',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ThemeConfig.spacingM),
              ElevatedButton.icon(
                onPressed: () {
                  leadProvider.clearFilters();
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear filters'),
                style: ThemeConfig.primaryButtonStyle,
              ),
            ],
          ),
          delay: const Duration(milliseconds: 300),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => leadProvider.loadLeads(refresh: true),
      color: ThemeConfig.accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          ThemeConfig.spacingM,
          0,
          ThemeConfig.spacingM,
          100, // Extra padding for FABs
        ),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return AnimationUtils.staggeredListItem(
            index: index,
            delay: const Duration(milliseconds: 50),
            child: _buildEnhancedLeadCard(lead),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedLeadCard(Lead lead) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
      ),
      child: AnimationUtils.rippleEffect(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  LeadDetailScreen(lead: lead),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(ThemeConfig.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lead Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: lead.getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
                    ),
                    child: Center(
                      child: Text(
                        lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: lead.getStatusColor(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingM),
                  // Lead Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ThemeConfig.spacingXS),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                            ),
                            const SizedBox(width: ThemeConfig.spacingXS),
                            Flexible(
                              child: Text(
                                lead.phone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (lead.company != null) ...[
                          const SizedBox(height: ThemeConfig.spacingXS),
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 14,
                                color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                              ),
                              const SizedBox(width: ThemeConfig.spacingXS),
                              Flexible(
                                child: Text(
                                  lead.company!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingS,
                      vertical: ThemeConfig.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: lead.getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                      border: Border.all(
                        color: lead.getStatusColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lead.getStatusIcon(),
                          size: 12,
                          color: lead.getStatusColor(),
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        Text(
                          lead.statusDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            color: lead.getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Meta Info Row
              const SizedBox(height: ThemeConfig.spacingM),
              Row(
                children: [
                  if (lead.callCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeConfig.spacingS,
                        vertical: ThemeConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeConfig.infoColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(ThemeConfig.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_callback_rounded,
                            size: 12,
                            color: ThemeConfig.infoColor,
                          ),
                          const SizedBox(width: ThemeConfig.spacingXS),
                          Text(
                            '${lead.callCount} calls',
                            style: const TextStyle(
                              fontSize: 10,
                              color: ThemeConfig.infoColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ThemeConfig.spacingS),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingS,
                      vertical: ThemeConfig.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                        ),
                        const SizedBox(width: ThemeConfig.spacingXS),
                        Text(
                          _formatDate(lead.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notes Section
              if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                const SizedBox(height: ThemeConfig.spacingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ThemeConfig.spacingM),
                  decoration: BoxDecoration(
                    color: isDark ? ThemeConfig.darkBackgroundColor : ThemeConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  ),
                  child: Text(
                    lead.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: ThemeConfig.spacingL),

              // CRITICAL OVERFLOW FIX: Action Buttons with Flexible Layout
              Row(
                children: [
                  // Call Button (Primary)
                  Flexible(
                    flex: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makeDirectCall(lead),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Call'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConfig.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: ThemeConfig.spacingS),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(ThemeConfig.radiusS),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingS),
                  // WhatsApp Button
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _sendWhatsAppMessage(lead),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Chat'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeConfig.successColor,
                          side:
                              const BorderSide(color: ThemeConfig.successColor),
                          padding: const EdgeInsets.symmetric(
                              vertical: ThemeConfig.spacingS),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(ThemeConfig.radiusS),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingS),
                  // Update Status Button
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(lead),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Edit'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeConfig.primaryColor,
                          side:
                              const BorderSide(color: ThemeConfig.primaryColor),
                          padding: const EdgeInsets.symmetric(
                              vertical: ThemeConfig.spacingS),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(ThemeConfig.radiusS),
                          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: AnimationUtils.slideUp(
        child: Padding(
          padding: const EdgeInsets.all(ThemeConfig.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(ThemeConfig.spacingL),
                decoration: BoxDecoration(
                  color: ThemeConfig.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: ThemeConfig.errorColor,
                ),
              ),
              const SizedBox(height: ThemeConfig.spacingL),
              Text(
                'Failed to load leads',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                ),
              ),
              const SizedBox(height: ThemeConfig.spacingS),
              Text(
                leadProvider.errorMessage ?? 'Unknown error occurred',
                style: TextStyle(
                  color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ThemeConfig.spacingXL),
              ElevatedButton.icon(
                onPressed: () {
                  leadProvider.clearError();
                  leadProvider.loadLeads(refresh: true);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ThemeConfig.primaryButtonStyle,
              ),
            ],
          ),
        ),
        delay: const Duration(milliseconds: 300),
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

  // MODERN ANIMATED FABs
  Widget _buildAnimatedFABs() {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final leads = leadProvider.filteredLeads;
        final newLeads = leads.where((lead) => lead.status == 'new').toList();
        final callbackLeads =
            leads.where((lead) => lead.status == 'callback').toList();

        final fabItems = <FABItem>[];

        if (callbackLeads.isNotEmpty) {
          fabItems.add(FABItem(
            label: 'Callbacks',
            icon: const Icon(Icons.schedule_rounded),
            onPressed: () => _startAutoDialer(context, callbackLeads),
            backgroundColor: ThemeConfig.warningColor,
          ));
        }

        if (newLeads.isNotEmpty) {
          fabItems.add(FABItem(
            label: 'New',
            icon: const Icon(Icons.fiber_new_rounded),
            onPressed: () => _startAutoDialer(context, newLeads),
            backgroundColor: ThemeConfig.successColor,
          ));
        }

        if (leads.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: ThemeConfig.spacingM + kBottomNavigationBarHeight,
          right: ThemeConfig.spacingM,
          child: AnimatedFAB(
            items: fabItems,
            mainButton: const Icon(Icons.auto_mode_rounded),
            isExpanded: false,
            onToggle: () {
              _startAutoDialer(context, leads);
            },
          ),
        );
      },
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
