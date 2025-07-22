// lib/screens/dashboard/dashboard_screen.dart - CLEAN REBUILD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lead_provider.dart';
import '../../config/theme_config.dart';
import '../auth/login_screen.dart';
import '../leads/leads_screen.dart';
import '../follow_up/follow_up_screen.dart';

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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThemeConfig.primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Follow-ups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final leadProvider = Provider.of<LeadProvider>(context, listen: false);
              leadProvider.loadLeads(refresh: true);
              leadProvider.loadDashboard();
            },
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(authProvider),
                  
                  const SizedBox(height: 20),
                  
                  // Stats Cards
                  _buildStatsCards(leadProvider),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  _buildQuickActions(context, leadProvider),
                  
                  const SizedBox(height: 20),
                  
                  // Lead Status Breakdown
                  _buildLeadStatusBreakdown(leadProvider),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Activity
                  _buildRecentActivity(leadProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: ThemeConfig.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              authProvider.userDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.agentDepartment,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(LeadProvider leadProvider) {
    final leads = leadProvider.leads;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Leads',
            leads.length.toString(),
            Icons.people,
            ThemeConfig.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'New Leads',
            leadProvider.getLeadsByStatus('new').length.toString(),
            Icons.fiber_new,
            ThemeConfig.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Converted',
            leadProvider.getLeadsByStatus('converted').length.toString(),
            Icons.check_circle,
            ThemeConfig.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LeadProvider leadProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Leads',
                Icons.people,
                ThemeConfig.primaryColor,
                () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                subtitle: '${leadProvider.leads.length} total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Follow-ups',
                Icons.schedule,
                Colors.orange,
                () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                subtitle: 'View follow-ups',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, {String? subtitle}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadStatusBreakdown(LeadProvider leadProvider) {
    final stats = leadProvider.leadStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lead Status Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: stats.isEmpty
                ? const Center(
                    child: Text('No leads available'),
                  )
                : Column(
                    children: stats.entries.map((entry) {
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
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(statusDisplayNames[entry.key] ?? entry.key),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(LeadProvider leadProvider) {
    final recentLeads = leadProvider.leads.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Leads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: recentLeads.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No leads available'),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentLeads.map((lead) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: lead.getStatusColor().withOpacity(0.1),
                        child: Icon(
                          lead.getStatusIcon(),
                          color: lead.getStatusColor(),
                          size: 20,
                        ),
                      ),
                      title: Text(lead.name),
                      subtitle: Text(lead.phone),
                      trailing: Text(
                        lead.statusDisplay,
                        style: TextStyle(
                          color: lead.getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        leadProvider.selectLead(lead);
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'interested':
        return Colors.green;
      case 'not_interested':
        return Colors.red;
      case 'callback':
        return Colors.purple;
      case 'wrong_number':
        return Colors.grey;
      case 'not_reachable':
        return Colors.brown;
      case 'converted':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Access the parent widget's state
  void _navigateToTab(int index) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = index;
    });
  }

  // Fix the selectedIndex access
  int get _selectedIndex {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    return dashboardState?._selectedIndex ?? 0;
  }

  set _selectedIndex(int value) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = value;
    });
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: ThemeConfig.primaryColor,
                          child: Text(
                            authProvider.userDisplayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.userDisplayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authProvider.user?.username ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authProvider.agentDepartment,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help coming soon!')),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}