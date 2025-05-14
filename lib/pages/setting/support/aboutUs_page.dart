import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/Pretzel.png'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pretzel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.2.10',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Our Story',
            'Developed by UiTM Kedah student for students, this app replaces disorganized group chats with a secure, course-specific textbook marketplace.',
          ),
          _buildSection(
            'Our Mission',
            'To transform the way students buy and sell textbooks by providing a user-friendly platform that offers affordable price.',
          ),
          _buildSection(
            'What We Offer',
            '• Clean and smooth UI/UX\n• Easy book listing and searching\n• Campus-focused buying and selling\n• Affordable textbook options',
          ),
          _buildSection(
            'Contact Us',
            'Email: support@pretzel.com\nLocation: UiTM Cawangan Kedah',
          ),
          const SizedBox(height: 16),
          Text(
            '© 2024 Pretzel. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
