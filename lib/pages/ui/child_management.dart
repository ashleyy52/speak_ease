import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new01/pages/theme_provider.dart';

class ChildManagementPage extends StatefulWidget {
  const ChildManagementPage({super.key});

  @override
  State<ChildManagementPage> createState() => _ChildManagementPageState();
}

class _ChildManagementPageState extends State<ChildManagementPage> {
  bool _contentFilterEnabled = true;
  bool _timeRestrictionsEnabled = false;
  bool _parentalLockEnabled = true;
  String _parentalPin = '1234'; // Default PIN
  bool _isChangingPin = false;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  int _dailyTimeLimit = 60; // in minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contentFilterEnabled = prefs.getBool('content_filter_enabled') ?? true;
      _timeRestrictionsEnabled = prefs.getBool('time_restrictions_enabled') ?? false;
      _parentalLockEnabled = prefs.getBool('parental_lock_enabled') ?? true;
      _parentalPin = prefs.getString('parental_pin') ?? '1234';
      _dailyTimeLimit = prefs.getInt('daily_time_limit') ?? 60;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('content_filter_enabled', _contentFilterEnabled);
    await prefs.setBool('time_restrictions_enabled', _timeRestrictionsEnabled);
    await prefs.setBool('parental_lock_enabled', _parentalLockEnabled);
    await prefs.setString('parental_pin', _parentalPin);
    await prefs.setInt('daily_time_limit', _dailyTimeLimit);
  }

  void _showPinDialog(Function onCorrectPin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Parental PIN',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter 4-digit PIN',
          ),
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pinController.clear();
            },
            child: Text('Cancel', style: GoogleFonts.nunito()),
          ),
          TextButton(
            onPressed: () {
              if (_pinController.text == _parentalPin) {
                Navigator.pop(context);
                onCorrectPin();
                _pinController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: Text('Confirm', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
  }

  void _changePin() {
    setState(() {
      _isChangingPin = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Parental PIN',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter new 4-digit PIN',
              ),
              maxLength: 4,
            ),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm new PIN',
              ),
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _newPinController.clear();
              _confirmPinController.clear();
              setState(() {
                _isChangingPin = false;
              });
            },
            child: Text('Cancel', style: GoogleFonts.nunito()),
          ),
          TextButton(
            onPressed: () {
              if (_newPinController.text.length == 4 &&
                  _newPinController.text == _confirmPinController.text) {
                setState(() {
                  _parentalPin = _newPinController.text;
                  _isChangingPin = false;
                });
                _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully')),
                );
                _newPinController.clear();
                _confirmPinController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match or invalid format')),
                );
              }
            },
            child: Text('Save', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Child Management',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFCC80),
            ],
          ),
        ),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // Parental Controls Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parental Controls',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF323232),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Enable Parental Lock',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF323232),
                              ),
                            ),
                            subtitle: Text(
                              'Require PIN for changing settings',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            value: _parentalLockEnabled,
                            onChanged: (value) {
                              if (_parentalLockEnabled) {
                                _showPinDialog(() {
                                  setState(() {
                                    _parentalLockEnabled = value;
                                  });
                                  _saveSettings();
                                });
                              } else {
                                setState(() {
                                  _parentalLockEnabled = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.lock,
                            title: 'Change Parental PIN',
                            onTap: () {
                              if (_parentalLockEnabled) {
                                _showPinDialog(_changePin);
                              } else {
                                _changePin();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Controls Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Content Controls',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF323232),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Enable Content Filter',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF323232),
                              ),
                            ),
                            subtitle: Text(
                              'Block inappropriate content',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            value: _contentFilterEnabled,
                            onChanged: (value) {
                              if (_parentalLockEnabled) {
                                _showPinDialog(() {
                                  setState(() {
                                    _contentFilterEnabled = value;
                                  });
                                  _saveSettings();
                                });
                              } else {
                                setState(() {
                                  _contentFilterEnabled = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time Controls Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Controls',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF323232),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Enable Time Restrictions',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF323232),
                              ),
                            ),
                            subtitle: Text(
                              'Limit daily app usage time',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            value: _timeRestrictionsEnabled,
                            onChanged: (value) {
                              if (_parentalLockEnabled) {
                                _showPinDialog(() {
                                  setState(() {
                                    _timeRestrictionsEnabled = value;
                                  });
                                  _saveSettings();
                                });
                              } else {
                                setState(() {
                                  _timeRestrictionsEnabled = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          if (_timeRestrictionsEnabled) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Daily Time Limit (minutes)',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF323232),
                              ),
                            ),
                            Slider(
                              value: _dailyTimeLimit.toDouble(),
                              min: 15,
                              max: 180,
                              divisions: 11,
                              label: _dailyTimeLimit.toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _dailyTimeLimit = value.toInt();
                                });
                              },
                              onChangeEnd: (double value) {
                                _saveSettings();
                              },
                            ),
                            Text(
                              'Current limit: $_dailyTimeLimit minutes',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Child Profiles Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Child Profiles',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF323232),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTile(
                            icon: Icons.person_add,
                            title: 'Add Child Profile',
                            subtitle: 'Create a new profile for your child',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Feature coming soon')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF323232).withOpacity(0.7),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF323232),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 13,
          color: Colors.grey,
        ),
      )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.withOpacity(0.2),
      indent: 16,
      endIndent: 16,
    );
  }
}