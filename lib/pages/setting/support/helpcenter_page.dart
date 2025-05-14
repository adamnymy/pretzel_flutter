import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Support Options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactOption(
                  context,
                  'Email Support',
                  'Get help via email',
                  Icons.email_outlined,
                  () => _launchEmail(),
                ),
                const SizedBox(height: 12),
                _buildContactOption(
                  context,
                  'WhatsApp',
                  'Chat with support',
                  FontAwesomeIcons.whatsapp,
                  () => _launchWhatsApp(),
                ),
              ],
            ),
          ),

          const Divider(),

          // FAQ Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                _buildFAQItem(
                  context,
                  'How do I list a book for sale?',
                  '''To list a book:

1. Tap the "+" button in the navigation bar
2. Fill in the book details
3. Add photos of the book
4. Set your price
5. Tap "Post" to publish''',
                ),
                _buildFAQItem(
                  context,
                  'How do I contact a seller?',
                  'When viewing a book listing, tap the "Chat" button to start a conversation with the seller.',
                ),
                _buildFAQItem(
                  context,
                  'Is payment handled through the app?',
                  'No, payments are handled directly between buyers and sellers. We recommend meeting in person at a safe location.',
                ),
                _buildFAQItem(
                  context,
                  'How do I edit my listing?',
                  'Go to your profile, find the listing under "My Books", and tap "Edit" to make changes.',
                ),
                _buildFAQItem(
                  context,
                  'How do I delete my account?',
                  'Go to Settings in your profile and select "Delete Account". This action cannot be undone.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Poppins')),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: const TextStyle(fontFamily: 'Poppins', height: 1.5),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@pretzel.com',
      queryParameters: {'subject': 'Support Request'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappLaunchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/your_phone_number', // Replace with your support phone number
    );

    if (await canLaunchUrl(whatsappLaunchUri)) {
      await launchUrl(whatsappLaunchUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}
