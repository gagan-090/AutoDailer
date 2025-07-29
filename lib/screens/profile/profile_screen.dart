// lib/screens/profile/profile_screen.dart - ENHANCED MODERN PROFILE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _optionsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _optionsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);
      leadProvider.loadDashboard();
    });
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _optionsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutBack,
    );
    _optionsAnimation = CurvedAnimation(
      parent: _optionsController,
      curve: Curves.easeOutCubic,
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _headerController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _statsController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _optionsController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark ? ThemeConfig.darkBackgroundColor : ThemeConfig.backgroundColor,
          body: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAnimatedAppBar(authProvider, isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(ThemeConfig.spacingM),
                    child: Column(
                      children: [
                        // Enhanced Profile Header
                        AnimatedBuilder(
                          animation: _headerAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _headerAnimation.value.clamp(0.0, 1.0),
                              child: Opacity(
                                opacity: _headerAnimation.value.clamp(0.0, 1.0),
                                child: _buildEnhancedProfileHeader(authProvider, isDark),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingXL),
                        
                        // Stats Section
                        AnimatedBuilder(
                          animation: _statsAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - _statsAnimation.value)),
                              child: Opacity(
                                opacity: _statsAnimation.value.clamp(0.0, 1.0),
                                child: _buildStatsSection(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingXL),
                        
                        // Activity Timeline
                        _buildActivityTimeline(),
                        
                        const SizedBox(height: ThemeConfig.spacingXL),
                        
                        // Enhanced Profile Options
                        AnimatedBuilder(
                          animation: _optionsAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - _optionsAnimation.value)),
                              child: Opacity(
                                opacity: _optionsAnimation.value.clamp(0.0, 1.0),
                                child: _buildEnhancedProfileOptions(context, authProvider),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: ThemeConfig.spacingXXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            );
          },
        ),
        floatingActionButton: _buildQuickActionsFAB(),
      );
    },
    );
  }

  Future<void> _refreshData() async {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    await leadProvider.loadDashboard();
  }

  Widget _buildAnimatedAppBar(AuthProvider authProvider, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? ThemeConfig.darkPrimaryColor : ThemeConfig.primaryColor,
      foregroundColor: isDark ? ThemeConfig.darkTextPrimary : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 300),
          child: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark ? ThemeConfig.darkPrimaryGradient : ThemeConfig.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AnimationUtils.scaleIn(
          child: IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditProfileDialog(),
          ),
          delay: const Duration(milliseconds: 600),
        ),
        AnimationUtils.scaleIn(
          child: IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareProfile(),
          ),
          delay: const Duration(milliseconds: 700),
        ),
      ],
    );
  }

  Widget _buildEnhancedProfileHeader(AuthProvider authProvider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ThemeConfig.spacingXL),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.darkCardColor : ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
        boxShadow: isDark ? ThemeConfig.darkElevatedShadow : ThemeConfig.elevatedShadow,
        border: Border.all(
          color: (isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Enhanced Profile Avatar with Status
          Stack(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: ThemeConfig.primaryGradient,
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
                      boxShadow: ThemeConfig.elevatedShadow,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        style: TextStyle(
                          fontSize: 48 * value,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        child: Text(
                          authProvider.userDisplayName.isNotEmpty
                              ? authProvider.userDisplayName.substring(0, 1).toUpperCase()
                              : 'U',
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: AnimationUtils.bounceIn(
                  delay: const Duration(milliseconds: 800),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ThemeConfig.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: ThemeConfig.spacingL),
          
          // Animated User Name
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Text(
                    authProvider.userDisplayName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? ThemeConfig.darkTextPrimary : ThemeConfig.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: ThemeConfig.spacingS),
          
          // Enhanced Username Badge
          AnimationUtils.slideInFromLeft(
            delay: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeConfig.spacingL,
                vertical: ThemeConfig.spacingS,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor).withValues(alpha: 0.1),
                    (isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                border: Border.all(
                  color: (isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    size: 16,
                    color: isDark ? ThemeConfig.darkAccentColor : ThemeConfig.accentColor,
                  ),
                  const SizedBox(width: ThemeConfig.spacingS),
                  Text(
                    authProvider.user?.username ?? '',
                    style: const TextStyle(
                      color: ThemeConfig.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: ThemeConfig.spacingL),
          
          // Department with Icon
          AnimationUtils.slideInFromRight(
            delay: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeConfig.spacingL,
                vertical: ThemeConfig.spacingM,
              ),
              decoration: BoxDecoration(
                color: ThemeConfig.backgroundColor,
                borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(ThemeConfig.spacingS),
                    decoration: BoxDecoration(
                      color: ThemeConfig.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 20,
                      color: ThemeConfig.infoColor,
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingM),
                  Text(
                    authProvider.agentDepartment,
                    style: const TextStyle(
                      color: ThemeConfig.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer2<LeadProvider, CallProvider>(
      builder: (context, leadProvider, callProvider, child) {
        final dashboardData = leadProvider.dashboardData;
        final summary = dashboardData?.summary;
        
        final stats = [
          StatItem(
            icon: Icons.phone_rounded,
            label: 'Calls Made',
            value: summary?.weekCalls ?? 0,
            color: ThemeConfig.successColor,
            trend: '+${((summary?.todayCalls ?? 0) * 100 / (summary?.weekCalls ?? 1)).toStringAsFixed(0)}%',
          ),
          StatItem(
            icon: Icons.people_rounded,
            label: 'Leads',
            value: summary?.totalLeads ?? 0,
            color: ThemeConfig.infoColor,
            trend: '+${((summary?.newLeads ?? 0) * 100 / (summary?.totalLeads ?? 1)).toStringAsFixed(0)}%',
          ),
          StatItem(
            icon: Icons.trending_up_rounded,
            label: 'Conversion',
            value: (summary?.conversionRate ?? 0).round(),
            color: ThemeConfig.accentColor,
            trend: '+${((summary?.convertedLeads ?? 0) * 100 / (summary?.contactedLeads ?? 1)).toStringAsFixed(0)}%',
            suffix: '%',
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(ThemeConfig.spacingL),
          decoration: BoxDecoration(
            color: ThemeConfig.cardColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
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
                      color: ThemeConfig.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: ThemeConfig.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingM),
                  const Text(
                    'Performance Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeConfig.spacingL),
              // Responsive layout for stats
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final cardWidth = (screenWidth - (ThemeConfig.spacingS * (stats.length - 1))) / stats.length;
                  
                  if (cardWidth < 100) {
                    // Use horizontal scroll for very small screens
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: stats.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stat = entry.value;
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: ThemeConfig.spacingS),
                            child: AnimationUtils.staggeredListItem(
                              index: index,
                              delay: const Duration(milliseconds: 200),
                              child: _buildStatCard(stat),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    // Use flexible layout for larger screens
                    return Row(
                      children: stats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stat = entry.value;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index < stats.length - 1 ? ThemeConfig.spacingS : 0,
                            ),
                            child: AnimationUtils.staggeredListItem(
                              index: index,
                              delay: const Duration(milliseconds: 200),
                              child: _buildStatCard(stat),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.spacingM),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        border: Border.all(
          color: stat.color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(ThemeConfig.spacingS),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 20,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingS),
          FittedBox(
            child: AnimationUtils.animatedCounter(
              value: stat.value,
              suffix: stat.suffix,
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 10,
              color: ThemeConfig.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConfig.spacingXS,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: ThemeConfig.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusXS),
            ),
            child: Text(
              stat.trend,
              style: const TextStyle(
                fontSize: 8,
                color: ThemeConfig.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final dashboardData = leadProvider.dashboardData;
        final recentCalls = dashboardData?.recentCalls ?? [];
        
        // Convert recent calls to activity items
        final activities = recentCalls.take(3).map((call) {
          final timeDiff = DateTime.now().difference(call.callDate);
          String timeAgo;
          if (timeDiff.inMinutes < 60) {
            timeAgo = '${timeDiff.inMinutes} min ago';
          } else if (timeDiff.inHours < 24) {
            timeAgo = '${timeDiff.inHours} hour${timeDiff.inHours > 1 ? 's' : ''} ago';
          } else {
            timeAgo = '${timeDiff.inDays} day${timeDiff.inDays > 1 ? 's' : ''} ago';
          }
          
          IconData icon;
          Color color;
          String title;
          
          switch (call.disposition) {
            case 'interested':
              icon = Icons.thumb_up_rounded;
              color = ThemeConfig.successColor;
              title = 'Lead interested';
              break;
            case 'not_interested':
              icon = Icons.thumb_down_rounded;
              color = ThemeConfig.errorColor;
              title = 'Not interested';
              break;
            case 'callback':
              icon = Icons.schedule_rounded;
              color = ThemeConfig.warningColor;
              title = 'Callback scheduled';
              break;
            case 'converted':
              icon = Icons.check_circle_rounded;
              color = ThemeConfig.accentColor;
              title = 'Lead converted';
              break;
            default:
              icon = Icons.phone_rounded;
              color = ThemeConfig.infoColor;
              title = 'Call completed';
          }
          
          return ActivityItem(
            icon: icon,
            title: title,
            subtitle: '${call.leadName} - ${call.disposition}',
            time: timeAgo,
            color: color,
          );
        }).toList();
        
        // If no recent calls, show placeholder
        if (activities.isEmpty) {
          activities.addAll([
            ActivityItem(
              icon: Icons.timeline_rounded,
              title: 'No recent activity',
              subtitle: 'Start making calls to see your activity here',
              time: 'Now',
              color: ThemeConfig.textSecondary,
            ),
          ]);
        }

        return Container(
          padding: const EdgeInsets.all(ThemeConfig.spacingL),
          decoration: BoxDecoration(
            color: ThemeConfig.cardColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
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
                      color: ThemeConfig.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      color: ThemeConfig.warningColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingM),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeConfig.spacingL),
              ...activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return AnimationUtils.staggeredListItem(
                  index: index,
                  delay: const Duration(milliseconds: 150),
                  child: _buildActivityItem(activity, index == activities.length - 1),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(ActivityItem activity, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: ThemeConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ThemeConfig.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: ThemeConfig.spacingS),
          Text(
            activity.time,
            style: const TextStyle(
              fontSize: 12,
              color: ThemeConfig.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProfileOptions(BuildContext context, AuthProvider authProvider) {
    final options = [
      ProfileOption(
        icon: Icons.person_rounded,
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        color: ThemeConfig.accentColor,
        onTap: () => _showEditProfileDialog(),
      ),
      ProfileOption(
        icon: Icons.settings_rounded,
        title: 'Settings',
        subtitle: 'App preferences and configuration',
        color: ThemeConfig.infoColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
      ),
      ProfileOption(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        subtitle: 'Manage your notification preferences',
        color: ThemeConfig.warningColor,
        onTap: () => _showNotificationSettings(context),
      ),
      ProfileOption(
        icon: Icons.security_rounded,
        title: 'Privacy & Security',
        subtitle: 'Manage your account security',
        color: ThemeConfig.primaryColor,
        onTap: () => _showSecuritySettings(context),
      ),
      ProfileOption(
        icon: Icons.help_rounded,
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        color: ThemeConfig.successColor,
        onTap: () => _showHelpDialog(context),
      ),
      ProfileOption(
        icon: Icons.logout_rounded,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        color: ThemeConfig.errorColor,
        onTap: () => _showLogoutDialog(context, authProvider),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: ThemeConfig.spacingM, bottom: ThemeConfig.spacingL),
          child: Text(
            'Account Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textPrimary,
            ),
          ),
        ),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          
          return AnimationUtils.staggeredListItem(
            index: index,
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
              child: _buildEnhancedProfileOptionTile(option),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEnhancedProfileOptionTile(ProfileOption option) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimationUtils.rippleEffect(
            onTap: () {
              option.onTap();
            },
            borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
            child: Container(
              padding: const EdgeInsets.all(ThemeConfig.spacingL),
              decoration: BoxDecoration(
                color: ThemeConfig.cardColor,
                borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                boxShadow: ThemeConfig.cardShadow,
                border: Border.all(
                  color: option.color.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'option_${option.title}',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            option.color.withValues(alpha: 0.1),
                            option.color.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
                        border: Border.all(
                          color: option.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        option.icon,
                        color: option.color,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ThemeConfig.spacingXS),
                        Text(
                          option.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ThemeConfig.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(ThemeConfig.spacingS),
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: option.color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsFAB() {
    return AnimationUtils.floatingAnimation(
      child: FloatingActionButton.extended(
        onPressed: () => _showQuickActionsBottomSheet(),
        backgroundColor: ThemeConfig.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.flash_on_rounded),
        label: const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
        ),
      ),
    );
  }

  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: ThemeConfig.cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ThemeConfig.radiusXL),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: ThemeConfig.spacingM),
              decoration: BoxDecoration(
                color: ThemeConfig.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(ThemeConfig.spacingL),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ThemeConfig.spacingL),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: ThemeConfig.spacingM,
                  mainAxisSpacing: ThemeConfig.spacingM,
                  childAspectRatio: 1.2,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.call_rounded,
                      title: 'Make Call',
                      color: ThemeConfig.successColor,
                      onTap: () {
                        Navigator.pop(context);
                        _showFeatureComingSoon(context, 'Quick Call', Icons.call_rounded, ThemeConfig.successColor);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.person_add_rounded,
                      title: 'Add Lead',
                      color: ThemeConfig.infoColor,
                      onTap: () {
                        Navigator.pop(context);
                        _showFeatureComingSoon(context, 'Add Lead', Icons.person_add_rounded, ThemeConfig.infoColor);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.analytics_rounded,
                      title: 'View Stats',
                      color: ThemeConfig.warningColor,
                      onTap: () {
                        Navigator.pop(context);
                        _showStatsDetail();
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.refresh_rounded,
                      title: 'Sync Data',
                      color: ThemeConfig.accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        _performDataSync();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimationUtils.rippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.spacingL),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingM),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Dialog Methods
  void _showEditProfileDialog() {
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
                Icons.person_rounded,
                color: ThemeConfig.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: ThemeConfig.spacingM),
            const Text('Edit Profile'),
          ],
        ),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  void _showNotificationSettings(BuildContext context) {
    _showFeatureComingSoon(context, 'Notifications', Icons.notifications_rounded, ThemeConfig.warningColor);
  }

  void _showSecuritySettings(BuildContext context) {
    _showFeatureComingSoon(context, 'Privacy & Security', Icons.security_rounded, ThemeConfig.primaryColor);
  }

  void _showHelpDialog(BuildContext context) {
    _showFeatureComingSoon(context, 'Help & Support', Icons.help_rounded, ThemeConfig.successColor);
  }

  void _showFeatureComingSoon(BuildContext context, String title, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: ThemeConfig.spacingM),
            Text('$title coming soon!'),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 20),
            SizedBox(width: ThemeConfig.spacingM),
            Text('Profile sharing coming soon!'),
          ],
        ),
        backgroundColor: ThemeConfig.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        ),
      ),
    );
  }

  void _showStatsDetail() {
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
                color: ThemeConfig.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: ThemeConfig.warningColor,
                size: 20,
              ),
            ),
            const SizedBox(width: ThemeConfig.spacingM),
            const Text('Detailed Stats'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Calls', '247', ThemeConfig.successColor),
            _buildStatRow('Successful Calls', '189', ThemeConfig.accentColor),
            _buildStatRow('Conversion Rate', '23%', ThemeConfig.warningColor),
            _buildStatRow('Average Call Duration', '4:32', ThemeConfig.infoColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeConfig.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ThemeConfig.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _performDataSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: ThemeConfig.spacingM),
            Text('Syncing data...'),
          ],
        ),
        backgroundColor: ThemeConfig.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: ThemeConfig.spacingM),
                Text('Data synced successfully!'),
              ],
            ),
            backgroundColor: ThemeConfig.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            ),
          ),
        );
      }
    });
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
                color: ThemeConfig.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: ThemeConfig.errorColor,
                size: 20,
              ),
            ),
            const SizedBox(width: ThemeConfig.spacingM),
            const Text(
              'Logout',
              style: TextStyle(
                color: ThemeConfig.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: TextStyle(
            color: ThemeConfig.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConfig.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
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
              }
            },
            style: ThemeConfig.errorButtonStyle,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Data Classes
class ProfileOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class StatItem {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String trend;
  final String? suffix;

  StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.trend,
    this.suffix,
  });
}

class ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}  
