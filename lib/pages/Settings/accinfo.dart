import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:new01/pages/theme_provider.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = 'Loading...';
  String email = 'Loading...';
  String phoneNumber = 'Loading...';
  String dob = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchAccountInfo();
  }

  Future<void> _fetchAccountInfo() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          setState(() {
            username = docSnapshot['username'] ?? 'Not Available';
            email = docSnapshot['email'] ?? 'Not Available';
            phoneNumber = docSnapshot['phone'] ?? 'Not Available';
            dob = docSnapshot['dob'] ?? 'Not Available';
          });
        } else {
          setState(() {
            username = 'Not Available';
            email = 'Not Available';
            phoneNumber = 'Not Available';
            dob = 'Not Available';
          });
        }
      } catch (e) {
        setState(() {
          username = 'Error fetching data';
          email = 'Error fetching data';
          phoneNumber = 'Error fetching data';
          dob = 'Error fetching data';
        });
      }
    }
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
          'Account Information',
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
                  // Account Info Card
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Username',
                            value: username,
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: email,
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'Phone Number',
                            value: phoneNumber,
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Date of Birth',
                            value: dob,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF323232).withOpacity(0.7),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF323232),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
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