import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../providers/theme_provider.dart';
import '../providers/text_size_provider.dart';
import 'login_screen.dart';
import 'sources_screen.dart';
import 'reading_history_screen.dart';
import 'offline_articles_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'User';
  String? _userEmail;
  bool _isGuest = false;
  double _textSize = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPreferences();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    final isGuest = await AuthService.isGuest();
    setState(() {
      _userName = name;
      _userEmail = email;
      _isGuest = isGuest;
    });
  }

  Future<void> _loadPreferences() async {
    final textSize = await PreferencesService.getTextSize();
    setState(() {
      _textSize = textSize;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ...existing code...

  void _showTextSizePicker() {
    double tempTextSize = _textSize;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Text Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Preview Text',
                  style: TextStyle(fontSize: 16 * tempTextSize),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: tempTextSize,
                  min: 0.8,
                  max: 1.4,
                  divisions: 3,
                  label: PreferencesService.getTextSizeName(tempTextSize),
                  onChanged: (value) {
                    setDialogState(() {
                      tempTextSize = value;
                    });
                  },
                ),
                Text(PreferencesService.getTextSizeName(tempTextSize)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
                  await textSizeProvider.setTextScale(tempTextSize);
                  setState(() => _textSize = tempTextSize);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Text size changed to ${PreferencesService.getTextSizeName(tempTextSize)}')),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userEmail != null)
                        Text(
                          _userEmail!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (_isGuest)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Guest User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Appearance Section
          _SectionTitle(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),

          const Divider(),

          // ...existing code...

          // Preferences Section
          _SectionTitle(title: 'Preferences'),
          // ...existing code...
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text Size'),
            subtitle: Text(PreferencesService.getTextSizeName(_textSize)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTextSizePicker(),
          ),

          const Divider(),

          // About Section
          _SectionTitle(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'News App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.newspaper, size: 48),
                children: [
                  const Text('A modern news application built with Flutter.'),
                  const SizedBox(height: 8),
                  const Text('Powered by News API'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'News Now Privacy Policy\n\n'
                      'We value your privacy and are committed to protecting your personal data.\n\n'
                      '1. Data Collection\n'
                      'We collect minimal data necessary to provide our services.\n\n'
                      '2. Data Usage\n'
                      'Your data is used solely for app functionality and personalization.\n\n'
                      '3. Data Security\n'
                      'We implement industry-standard security measures.\n\n'
                      '4. Third-party Services\n'
                      'We use Firebase for authentication and NewsAPI for news content.\n\n'
                      'Last updated: November 2025',
                      style: TextStyle(fontSize: 14),
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Terms of Service'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'News Now Terms of Service\n\n'
                      'By using this app, you agree to the following terms:\n\n'
                      '1. Acceptance of Terms\n'
                      'By accessing News Now, you accept these terms in full.\n\n'
                      '2. Use of Service\n'
                      'You agree to use the service for lawful purposes only.\n\n'
                      '3. User Accounts\n'
                      'You are responsible for maintaining account security.\n\n'
                      '4. Content\n'
                      'News content is provided by third-party sources.\n\n'
                      '5. Limitation of Liability\n'
                      'We are not liable for any damages arising from app usage.\n\n'
                      'Last updated: November 2025',
                      style: TextStyle(fontSize: 14),
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
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _logout,
          ),

          const SizedBox(height: 20),
          
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
