// lib/screens/dashboard/dashboard_screen.dart - MODERN ELEGANT DASHBOARD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/theme_switch.dart';
import '../leads/leads_screen.dart';
import '../follow_up/follow_up_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const LeadsScreen(),
    const FollowUpScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.darkCardColor : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ThemeConfig.radiusL),
                topRight: Radius.circular(ThemeConfig.radiusL),
              ),
              boxShadow: isDark ? ThemeConfig.darkElevatedShadow : ThemeConfig.elevatedShadow,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ThemeConfig.radiusL),
                topRight: Radius.circular(ThemeConfig.radiusL),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor,
                unselectedItemColor: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                backgroundColor: isDark ? ThemeConfig.darkCardColor : Colors.white,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_rounded),
                    label: 'Leads',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule_rounded),
                    label: 'Follow-ups',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Dashboard Home Screen
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);
      leadProvider.loadLeads();
      leadProvider.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark ? ThemeConfig.darkBackgroundColor : ThemeConfig.backgroundColor,
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: isDark ? ThemeConfig.darkPrimaryColor : ThemeConfig.primaryColor,
            foregroundColor: isDark ? ThemeConfig.darkTextPrimary : Colors.white,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: ThemeSwitch(),
            ),
            actions: [
              AnimationUtils.rippleEffect(
                onTap: () {
                  final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                  leadProvider.loadLeads(refresh: true);
                  leadProvider.loadDashboard();
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.refresh_rounded),
                ),
              ),
            ],
          ),
          body: Consumer2<AuthProvider, LeadProvider>(
            builder: (context, authProvider, leadProvider, child) {
              return RefreshIndicator(
                onRefresh: () async {
                  await leadProvider.loadLeads(refresh: true);
                  await leadProvider.loadDashboard();
                },
                color: isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor,
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(ThemeConfig.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Card
                        AnimationUtils.slideUp(
                          child: _buildWelcomeCard(authProvider, isDark),
                          delay: const Duration(milliseconds: 100),
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingL),
                        
                        // Stats Cards
                        _buildStatsCards(leadProvider, isDark),
                        
                        const SizedBox(height: ThemeConfig.spacingL),
                        
                        // Quick Actions
                        AnimationUtils.slideUp(
                          child: _buildQuickActions(context, leadProvider, isDark),
                          delay: const Duration(milliseconds: 500),
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingL),
                        
                        // Lead Status Breakdown
                        AnimationUtils.slideUp(
                          child: _buildLeadStatusBreakdown(leadProvider, isDark),
                          delay: const Duration(milliseconds: 600),
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingL),
                        
                        // Recent Activity
                        AnimationUtils.slideUp(
                          child: _buildRecentActivity(leadProvider, isDark),
                          delay: const Duration(milliseconds: 700),
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingXL),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ThemeConfig.spacingL),
      decoration: BoxDecoration(
        gradient: isDark ? ThemeConfig.darkPrimaryGradient : ThemeConfig.primaryGradient,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: ThemeConfig.spacingXS),
                Text(
                  authProvider.userDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ThemeConfig.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConfig.spacingM,
                    vertical: ThemeConfig.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  ),
                  child: Text(
                    authProvider.agentDepartment,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(LeadProvider leadProvider, bool isDark) {
    final leads = leadProvider.leads;
    
    return Row(
      children: [
        Expanded(
          child: AnimationUtils.staggeredListItem(
            index: 0,
            child: _buildStatCard(
              'Total Leads',
              leads.length,
              Icons.people_rounded,
              ThemeConfig.infoColor,
              isDark,
            ),
          ),
        ),
        const SizedBox(width: ThemeConfig.spacingM),
        Expanded(
          child: AnimationUtils.staggeredListItem(
            index: 1,
            child: _buildStatCard(
              'New Leads',
              leadProvider.getLeadsByStatus('new').length,
              Icons.fiber_new_rounded,
              ThemeConfig.warningColor,
              isDark,
            ),
          ),
        ),
        const SizedBox(width: ThemeConfig.spacingM),
        Expanded(
          child: AnimationUtils.staggeredListItem(
            index: 2,
            child: _buildStatCard(
              'Converted',
              leadProvider.getLeadsByStatus('converted').length,
              Icons.check_circle_rounded,
              ThemeConfig.successColor,
              isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.spacingL),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.darkCardColor : ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ThemeConfig.spacingM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: ThemeConfig.spacingM),
          AnimationUtils.animatedCounter(
            value: value,
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LeadProvider leadProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
          ),
        ),
        const SizedBox(height: ThemeConfig.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Leads',
                Icons.people_rounded,
                isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor,
                () {
                  final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                  dashboardState?.setState(() {
                    dashboardState._selectedIndex = 1;
                  });
                },
                subtitle: '${leadProvider.leads.length} total',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: ThemeConfig.spacingM),
            Expanded(
              child: _buildActionButton(
                'Follow-ups',
                Icons.schedule_rounded,
                ThemeConfig.warningColor,
                () {
                  final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                  dashboardState?.setState(() {
                    dashboardState._selectedIndex = 2;
                  });
                },
                subtitle: 'View follow-ups',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, {String? subtitle, required bool isDark}) {
    return AnimationUtils.rippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
      child: Container(
        padding: const EdgeInsets.all(ThemeConfig.spacingL),
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.darkCardColor : ThemeConfig.cardColor,
          borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
          boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.spacingM),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: ThemeConfig.spacingM),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ThemeConfig.spacingXS),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadStatusBreakdown(LeadProvider leadProvider, bool isDark) {
    final stats = leadProvider.leadStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lead Status Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
          ),
        ),
        const SizedBox(height: ThemeConfig.spacingM),
        Container(
          padding: const EdgeInsets.all(ThemeConfig.spacingL),
          decoration: BoxDecoration(
            color: isDark ? ThemeConfig.darkCardColor : ThemeConfig.cardColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
            boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
          ),
          child: stats.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                      ),
                      const SizedBox(height: ThemeConfig.spacingM),
                      Text(
                        'No leads available',
                        style: TextStyle(color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: stats.entries.map((entry) {
                    final index = stats.keys.toList().indexOf(entry.key);
                    final statusDisplayNames = {
                      'new': 'New',
                      'contacted': 'Contacted',
                      'interested': 'Interested',
                      'not_interested': 'Not Interested',
                      'callback': 'Callback Later',
                      'wrong_number': 'Wrong Number',
                      'not_reachable': 'Not Reachable',
                      'converted': 'Converted',
                    };
                    
                    return AnimationUtils.staggeredListItem(
                      index: index,
                      delay: const Duration(milliseconds: 50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: ThemeConfig.spacingS),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: ThemeConfig.getStatusColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: ThemeConfig.spacingM),
                            Expanded(
                              child: Text(
                                statusDisplayNames[entry.key] ?? entry.key,
                                style: TextStyle(
                                  color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ThemeConfig.spacingS,
                                vertical: ThemeConfig.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConfig.getStatusColor(entry.key).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ThemeConfig.getStatusColor(entry.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(LeadProvider leadProvider, bool isDark) {
    final recentLeads = leadProvider.leads.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Leads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
          ),
        ),
        const SizedBox(height: ThemeConfig.spacingM),
        Container(
          decoration: BoxDecoration(
            color: isDark ? ThemeConfig.darkCardColor : ThemeConfig.cardColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
            boxShadow: isDark ? ThemeConfig.darkCardShadow : ThemeConfig.cardShadow,
          ),
          child: recentLeads.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(ThemeConfig.spacingXXL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: isDark ? ThemeConfig.darkTextTertiary : ThemeConfig.textTertiary,
                        ),
                        const SizedBox(height: ThemeConfig.spacingM),
                        Text(
                          'No leads available',
                          style: TextStyle(color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentLeads.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lead = entry.value;
                    
                    return AnimationUtils.staggeredListItem(
                      index: index,
                      delay: const Duration(milliseconds: 50),
                      child: AnimationUtils.rippleEffect(
                        onTap: () {
                          leadProvider.selectLead(lead);
                          final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                          dashboardState?.setState(() {
                            dashboardState._selectedIndex = 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(ThemeConfig.spacingM),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: lead.getStatusColor().withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
                                ),
                                child: Icon(
                                  lead.getStatusIcon(),
                                  color: lead.getStatusColor(),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: ThemeConfig.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: ThemeConfig.spacingXS),
                                    Text(
                                      lead.phone,
                                      style: TextStyle(
                                        color: isDark ? ThemeConfig.darkTextSecondary : ThemeConfig.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ThemeConfig.spacingS,
                                  vertical: ThemeConfig.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: lead.getStatusColor().withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
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
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }


}

