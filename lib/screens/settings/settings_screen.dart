// lib/screens/settings/settings_screen.dart - COMPREHENSIVE SETTINGS SCREEN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _sectionsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _sectionsAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoDialerEnabled = true;
  bool _callRecordingEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';
  double _callVolume = 0.8;
  double _ringVolume = 0.9;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sectionsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    );
    _sectionsAnimation = CurvedAnimation(
      parent: _sectionsController,
      curve: Curves.easeOutCubic,
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _sectionsController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      appBar: _buildAnimatedAppBar(),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(ThemeConfig.spacingM),
                  child: Column(
                    children: [
                      // Header Section
                      AnimatedBuilder(
                        animation: _headerAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _headerAnimation.value,
                            child: Opacity(
                              opacity: _headerAnimation.value,
                              child: _buildHeaderSection(authProvider),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: ThemeConfig.spacingXL),
                      
                      // Settings Sections
                      AnimatedBuilder(
                        animation: _sectionsAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - _sectionsAnimation.value)),
                            child: Opacity(
                              opacity: _sectionsAnimation.value,
                              child: _buildSettingsSections(),
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
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      backgroundColor: ThemeConfig.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Settings',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ThemeConfig.primaryGradient,
        ),
      ),
      actions: [
        AnimationUtils.scaleIn(
          child: IconButton(
            icon: const Icon(Icons.restore_rounded),
            onPressed: () => _showResetDialog(),
            tooltip: 'Reset to defaults',
          ),
          delay: const Duration(milliseconds: 400),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ThemeConfig.spacingXL),
      decoration: BoxDecoration(
        color: ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
        boxShadow: ThemeConfig.elevatedShadow,
        border: Border.all(
          color: ThemeConfig.accentColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: ThemeConfig.accentGradient,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
              boxShadow: ThemeConfig.elevatedShadow,
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingL),
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textPrimary,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingS),
          Text(
            'Customize your experience',
            style: TextStyle(
              fontSize: 16,
              color: ThemeConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      children: [
        // Notifications Section
        AnimationUtils.staggeredListItem(
          index: 0,
          child: _buildSettingsSection(
            title: 'Notifications',
            icon: Icons.notifications_rounded,
            color: ThemeConfig.warningColor,
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications for new leads and calls',
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                title: 'Sound Alerts',
                subtitle: 'Play sound for notifications',
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Vibrate for incoming calls and notifications',
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // Audio Settings Section
        AnimationUtils.staggeredListItem(
          index: 1,
          child: _buildSettingsSection(
            title: 'Audio Settings',
            icon: Icons.volume_up_rounded,
            color: ThemeConfig.infoColor,
            children: [
              _buildSliderTile(
                title: 'Call Volume',
                subtitle: 'Adjust volume for calls',
                value: _callVolume,
                onChanged: (value) => setState(() => _callVolume = value),
              ),
              _buildSliderTile(
                title: 'Ring Volume',
                subtitle: 'Adjust volume for incoming calls',
                value: _ringVolume,
                onChanged: (value) => setState(() => _ringVolume = value),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // Dialer Settings Section
        AnimationUtils.staggeredListItem(
          index: 2,
          child: _buildSettingsSection(
            title: 'Dialer Settings',
            icon: Icons.phone_rounded,
            color: ThemeConfig.successColor,
            children: [
              _buildSwitchTile(
                title: 'Auto Dialer',
                subtitle: 'Enable automatic dialing for leads',
                value: _autoDialerEnabled,
                onChanged: (value) => setState(() => _autoDialerEnabled = value),
              ),
              _buildSwitchTile(
                title: 'Call Recording',
                subtitle: 'Record calls for quality assurance',
                value: _callRecordingEnabled,
                onChanged: (value) => setState(() => _callRecordingEnabled = value),
              ),
              _buildTapTile(
                title: 'Dialer Preferences',
                subtitle: 'Configure auto-dialer settings',
                icon: Icons.tune_rounded,
                onTap: () => _showDialerPreferences(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // Appearance Section
        AnimationUtils.staggeredListItem(
          index: 3,
          child: _buildSettingsSection(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            color: ThemeConfig.accentColor,
            children: [
              _buildDropdownTile(
                title: 'Theme',
                subtitle: 'Choose your preferred theme',
                value: _selectedTheme,
                items: ['Light', 'Dark', 'System'],
                onChanged: (value) => setState(() => _selectedTheme = value!),
              ),
              _buildDropdownTile(
                title: 'Language',
                subtitle: 'Select your preferred language',
                value: _selectedLanguage,
                items: ['English', 'Spanish', 'French', 'German'],
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // Privacy & Security Section
        AnimationUtils.staggeredListItem(
          index: 4,
          child: _buildSettingsSection(
            title: 'Privacy & Security',
            icon: Icons.security_rounded,
            color: ThemeConfig.primaryColor,
            children: [
              _buildTapTile(
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock_rounded,
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildTapTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                icon: Icons.verified_user_rounded,
                onTap: () => _showTwoFactorDialog(),
              ),
              _buildTapTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.policy_rounded,
                onTap: () => _showPrivacyPolicy(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // Support Section
        AnimationUtils.staggeredListItem(
          index: 5,
          child: _buildSettingsSection(
            title: 'Support',
            icon: Icons.help_rounded,
            color: ThemeConfig.errorColor,
            children: [
              _buildTapTile(
                title: 'Help Center',
                subtitle: 'Get help and find answers',
                icon: Icons.help_center_rounded,
                onTap: () => _showHelpCenter(),
              ),
              _buildTapTile(
                title: 'Contact Support',
                subtitle: 'Get in touch with our support team',
                icon: Icons.support_agent_rounded,
                onTap: () => _showContactSupport(),
              ),
              _buildTapTile(
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                icon: Icons.bug_report_rounded,
                onTap: () => _showBugReport(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // About Section
        AnimationUtils.staggeredListItem(
          index: 6,
          child: _buildSettingsSection(
            title: 'About',
            icon: Icons.info_rounded,
            color: ThemeConfig.textSecondary,
            children: [
              _buildTapTile(
                title: 'App Version',
                subtitle: 'Version 1.0.0 (Build 100)',
                icon: Icons.info_outline_rounded,
                onTap: () => _showVersionInfo(),
              ),
              _buildTapTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                icon: Icons.description_rounded,
                onTap: () => _showTermsOfService(),
              ),
              _buildTapTile(
                title: 'Licenses',
                subtitle: 'View open source licenses',
                icon: Icons.copyright_rounded,
                onTap: () => _showLicenses(),
              ),
            ],
          ),
        ),
      ],
    );
  } 
 Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
        boxShadow: ThemeConfig.cardShadow,
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ThemeConfig.spacingL),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ThemeConfig.radiusXL),
                topRight: Radius.circular(ThemeConfig.radiusXL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ThemeConfig.spacingS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: ThemeConfig.spacingM),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Section Content
          Padding(
            padding: const EdgeInsets.all(ThemeConfig.spacingL),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: ThemeConfig.spacingXS),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ThemeConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConfig.accentColor,
            activeTrackColor: ThemeConfig.accentColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(height: ThemeConfig.spacingXS),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ThemeConfig.textSecondary,
                    ),
                  ),
                ],
              ),
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
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.spacingM),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ThemeConfig.accentColor,
              inactiveTrackColor: ThemeConfig.accentColor.withValues(alpha: 0.2),
              thumbColor: ThemeConfig.accentColor,
              overlayColor: ThemeConfig.accentColor.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeConfig.textPrimary,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingXS),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: ThemeConfig.textSecondary,
            ),
          ),
          const SizedBox(height: ThemeConfig.spacingM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ThemeConfig.spacingM),
            decoration: BoxDecoration(
              color: ThemeConfig.backgroundColor,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              border: Border.all(
                color: ThemeConfig.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ThemeConfig.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ThemeConfig.accentColor,
                ),
                dropdownColor: ThemeConfig.cardColor,
                borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingM),
      child: AnimationUtils.rippleEffect(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ThemeConfig.spacingM),
          decoration: BoxDecoration(
            color: ThemeConfig.backgroundColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            border: Border.all(
              color: ThemeConfig.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ThemeConfig.spacingS),
                decoration: BoxDecoration(
                  color: ThemeConfig.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ThemeConfig.radiusS),
                ),
                child: Icon(
                  icon,
                  color: ThemeConfig.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: ThemeConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.textPrimary,
                      ),
                    ),
                    const SizedBox(height: ThemeConfig.spacingXS),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ThemeConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ThemeConfig.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog Methods
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _resetToDefaults();
              Navigator.pop(context);
            },
            style: ThemeConfig.errorButtonStyle,
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDialerPreferences() {
    Navigator.pushNamed(context, '/auto_dialer_settings');
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingM),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingM),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
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
              // Handle password change
              Navigator.pop(context);
              _showSuccessSnackBar('Password changed successfully');
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text('Two-factor authentication adds an extra layer of security to your account. Would you like to enable it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Two-factor authentication setup initiated');
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is where the privacy policy content would be displayed. '
            'It would include information about data collection, usage, '
            'and user rights regarding their personal information.',
          ),
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

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text('Opening help center...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you like to contact support?'),
            const SizedBox(height: ThemeConfig.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Opening email client...');
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Initiating chat...');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Bug Title',
                hintText: 'Brief description of the issue',
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingM),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of the bug',
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
              _showSuccessSnackBar('Bug report submitted successfully');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.0'),
            const Text('Build: 100'),
            const Text('Release Date: January 2025'),
            const SizedBox(height: ThemeConfig.spacingM),
            const Text('What\'s New:'),
            const Text('• Enhanced user interface'),
            const Text('• Improved performance'),
            const Text('• Bug fixes and stability improvements'),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is where the terms of service content would be displayed. '
            'It would include the legal terms and conditions for using the application.',
          ),
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

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Lead Management App',
      applicationVersion: '1.0.0',
    );
  }

  void _resetToDefaults() {
    setState(() {
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _darkModeEnabled = false;
      _autoDialerEnabled = true;
      _callRecordingEnabled = false;
      _selectedLanguage = 'English';
      _selectedTheme = 'Light';
      _callVolume = 0.8;
      _ringVolume = 0.9;
    });
    _showSuccessSnackBar('Settings reset to defaults');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConfig.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        ),
      ),
    );
  }
}