import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new01/pages/Settings/passchange.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user signed in with email and password
    final isEmailSignIn = user?.providerData.any((info) => info.providerId == 'password') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (isEmailSignIn)
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage(),
                  ),
                );
              },
            ),
          const Divider(),
          // Future options can be added here
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Other Privacy Option (Coming Soon)'),
          ),
        ],
      ),
    );
  }
}