// lib/screens/dialer/auto_dialer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme_config.dart';

class AutoDialerSettingsScreen extends StatefulWidget {
  const AutoDialerSettingsScreen({super.key});

  @override
  State<AutoDialerSettingsScreen> createState() => _AutoDialerSettingsScreenState();
}

class _AutoDialerSettingsScreenState extends State<AutoDialerSettingsScreen> {
  // Settings variables
  int _dialDelay = 10; // seconds
  bool _autoProgression = true;
  bool _skipFailedCalls = true;
  bool _confirmBeforeCall = false;
  bool _playDialTone = true;
  int _retryAttempts = 2;
  bool _enableCallRecording = false;
  String _defaultDisposition = 'not_reachable';

  // Delay options
  final List<int> _delayOptions = [5, 10, 15, 20];
  final List<int> _retryOptions = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dialDelay = prefs.getInt('dial_delay') ?? 10;
      _autoProgression = prefs.getBool('auto_progression') ?? true;
      _skipFailedCalls = prefs.getBool('skip_failed_calls') ?? true;
      _confirmBeforeCall = prefs.getBool('confirm_before_call') ?? false;
      _playDialTone = prefs.getBool('play_dial_tone') ?? true;
      _retryAttempts = prefs.getInt('retry_attempts') ?? 2;
      _enableCallRecording = prefs.getBool('enable_call_recording') ?? false;
      _defaultDisposition = prefs.getString('default_disposition') ?? 'not_reachable';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dial_delay', _dialDelay);
    await prefs.setBool('auto_progression', _autoProgression);
    await prefs.setBool('skip_failed_calls', _skipFailedCalls);
    await prefs.setBool('confirm_before_call', _confirmBeforeCall);
    await prefs.setBool('play_dial_tone', _playDialTone);
    await prefs.setInt('retry_attempts', _retryAttempts);
    await prefs.setBool('enable_call_recording', _enableCallRecording);
    await prefs.setString('default_disposition', _defaultDisposition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Dialer Settings'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndClose,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialing Settings Section
            _buildSection(
              'Dialing Settings',
              Icons.phone,
              [
                _buildDialDelaySlider(),
                _buildSwitchTile(
                  'Auto Progression',
                  'Automatically move to next lead after disposition',
                  Icons.skip_next,
                  _autoProgression,
                  (value) => setState(() => _autoProgression = value),
                ),
                _buildSwitchTile(
                  'Skip Failed Calls',
                  'Automatically skip calls that fail to connect',
                  Icons.error_outline,
                  _skipFailedCalls,
                  (value) => setState(() => _skipFailedCalls = value),
                ),
                _buildSwitchTile(
                  'Confirm Before Call',
                  'Show confirmation dialog before each call',
                  Icons.help_outline,
                  _confirmBeforeCall,
                  (value) => setState(() => _confirmBeforeCall = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Audio Settings Section
            _buildSection(
              'Audio Settings',
              Icons.volume_up,
              [
                _buildSwitchTile(
                  'Play Dial Tone',
                  'Play sound when dialing numbers',
                  Icons.music_note,
                  _playDialTone,
                  (value) => setState(() => _playDialTone = value),
                ),
                _buildSwitchTile(
                  'Enable Call Recording',
                  'Record calls for quality assurance (where legal)',
                  Icons.record_voice_over,
                  _enableCallRecording,
                  (value) => setState(() => _enableCallRecording = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Retry Settings Section
            _buildSection(
              'Retry Settings',
              Icons.refresh,
              [
                _buildRetryDropdown(),
              ],
            ),

            const SizedBox(height: 24),

            // Default Disposition Section
            _buildSection(
              'Default Disposition',
              Icons.assignment,
              [
                _buildDefaultDispositionDropdown(),
              ],
            ),

            const SizedBox(height: 24),

            // Reset to Defaults
            Center(
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ThemeConfig.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ThemeConfig.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: ThemeConfig.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConfig.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDialDelaySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Dial Delay: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_dialDelay seconds',
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeConfig.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Time to wait between calls',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ThemeConfig.primaryColor,
              thumbColor: ThemeConfig.primaryColor,
              overlayColor: ThemeConfig.primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: _dialDelay.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '$_dialDelay seconds',
              onChanged: (value) {
                setState(() {
                  _dialDelay = value.round();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ThemeConfig.primaryColor.withOpacity(0.1),
            child: Icon(Icons.refresh, color: ThemeConfig.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Retry Attempts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Number of times to retry failed calls',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<int>(
            value: _retryAttempts,
            items: _retryOptions.map((attempts) {
              return DropdownMenuItem(
                value: attempts,
                child: Text('$attempts ${attempts == 1 ? 'time' : 'times'}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _retryAttempts = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultDispositionDropdown() {
    final dispositions = [
      {'value': 'not_reachable', 'label': 'Not Reachable'},
      {'value': 'busy', 'label': 'Busy'},
      {'value': 'voicemail', 'label': 'Voicemail'},
      {'value': 'wrong_number', 'label': 'Wrong Number'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ThemeConfig.primaryColor.withOpacity(0.1),
            child: Icon(Icons.assignment, color: ThemeConfig.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default for Failed Calls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Auto-assign this disposition to failed calls',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _defaultDisposition,
            items: dispositions.map((disposition) {
              return DropdownMenuItem(
                value: disposition['value'],
                child: Text(disposition['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _defaultDisposition = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all auto-dialer settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dialDelay = 10;
                _autoProgression = true;
                _skipFailedCalls = true;
                _confirmBeforeCall = false;
                _playDialTone = true;
                _retryAttempts = 2;
                _enableCallRecording = false;
                _defaultDisposition = 'not_reachable';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveAndClose() async {
    await _saveSettings();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}