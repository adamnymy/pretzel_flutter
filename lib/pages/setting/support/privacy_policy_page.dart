import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Last updated: May 7, 2025',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 24),
          _PolicySection(
            title: '1. Information We Collect',
            content: '''
We collect information that you provide directly to us, including:
• Name and contact information
• Profile information
• Book listing details
• Chat messages
• Transaction information''',
          ),
          _PolicySection(
            title: '2. How We Use Your Information',
            content: '''
We use the information we collect to:
• Provide and maintain the Pretzel service
• Process your transactions
• Send you notifications
• Improve our services
• Ensure platform security''',
          ),
          _PolicySection(
            title: '3. Information Sharing',
            content: '''
We do not sell your personal information. We may share your information only:
• With other users for transaction purposes
• With service providers
• To comply with legal obligations
• With your consent''',
          ),
          _PolicySection(
            title: '4. Data Security',
            content: '''
We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or destruction.''',
          ),
          _PolicySection(
            title: '5. Your Rights',
            content: '''
You have the right to:
• Access your personal information
• Update or correct your information
• Delete your account
• Opt-out of marketing communications''',
          ),
          _PolicySection(
            title: '6. Contact Us',
            content: '''
If you have questions about this Privacy Policy, please contact us at:
support@pretzel.com''',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}