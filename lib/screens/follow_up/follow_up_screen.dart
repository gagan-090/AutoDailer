// lib/screens/follow_up/follow_up_screen_basic.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/follow_up_provider.dart';
import '../../config/theme_config.dart';
import '../../models/follow_up_model.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FollowUpProvider>(context, listen: false).loadFollowUps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.schedule), text: 'Upcoming'),
            Tab(icon: Icon(Icons.history), text: 'Overdue'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<FollowUpProvider>(context, listen: false)
                  .loadFollowUps(refresh: true);
            },
          ),
        ],
      ),
      body: Consumer<FollowUpProvider>(
        builder: (context, followUpProvider, child) {
          if (followUpProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (followUpProvider.errorMessage != null) {
            return _buildErrorState(followUpProvider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTodayFollowUps(followUpProvider),
              _buildUpcomingFollowUps(followUpProvider),
              _buildOverdueFollowUps(followUpProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTodayFollowUps(FollowUpProvider provider) {
    final todayFollowUps = provider.todayFollowUps;

    if (todayFollowUps.isEmpty) {
      return _buildEmptyState(
        'No follow-ups today',
        'You\'re all caught up for today!',
        Icons.check_circle,
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFollowUps(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: todayFollowUps.length,
        itemBuilder: (context, index) {
          return _buildFollowUpCard(todayFollowUps[index], isToday: true);
        },
      ),
    );
  }

  Widget _buildUpcomingFollowUps(FollowUpProvider provider) {
    final upcomingFollowUps = provider.upcomingFollowUps;

    if (upcomingFollowUps.isEmpty) {
      return _buildEmptyState(
        'No upcoming follow-ups',
        'Schedule follow-ups to stay organized',
        Icons.schedule,
        Colors.blue,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFollowUps(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: upcomingFollowUps.length,
        itemBuilder: (context, index) {
          return _buildFollowUpCard(upcomingFollowUps[index]);
        },
      ),
    );
  }

  Widget _buildOverdueFollowUps(FollowUpProvider provider) {
    final overdueFollowUps = provider.overdueFollowUps;

    if (overdueFollowUps.isEmpty) {
      return _buildEmptyState(
        'No overdue follow-ups',
        'Great job staying on top of your follow-ups!',
        Icons.thumb_up,
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFollowUps(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: overdueFollowUps.length,
        itemBuilder: (context, index) {
          return _buildFollowUpCard(overdueFollowUps[index], isOverdue: true);
        },
      ),
    );
  }

  Widget _buildFollowUpCard(FollowUp followUp, {bool isToday = false, bool isOverdue = false}) {
    Color borderColor = Colors.grey[300]!;
    Color accentColor = ThemeConfig.primaryColor;

    if (isOverdue) {
      borderColor = Colors.red[300]!;
      accentColor = Colors.red;
    } else if (isToday) {
      borderColor = Colors.orange[300]!;
      accentColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with lead info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.1),
                  child: Icon(
                    isOverdue ? Icons.warning : Icons.person,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        followUp.lead.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        followUp.lead.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy - h:mm a').format(
                    DateTime.parse('${followUp.followUpDate.toString().split(' ')[0]} ${followUp.followUpTime}')
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),

            // Remarks (if available)
            if (followUp.remarks != null && followUp.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        followUp.remarks!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callLead(followUp),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Now'),
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
                    onPressed: () => _markAsCompleted(followUp),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Done'),
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
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FollowUpProvider provider) {
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
            'Failed to load follow-ups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              provider.loadFollowUps(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _callLead(FollowUp followUp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${followUp.lead.name}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAsCompleted(FollowUp followUp) async {
    final provider = Provider.of<FollowUpProvider>(context, listen: false);
    final success = await provider.markAsCompleted(followUp.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow-up with ${followUp.lead.name} marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}