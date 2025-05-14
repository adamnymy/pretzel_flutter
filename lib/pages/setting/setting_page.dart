import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pretzel_apk/pages/setting/account/edit_profile_page.dart';
import 'package:pretzel_apk/pages/setting/activity/mybooks_page.dart';
import 'package:pretzel_apk/pages/setting/support/helpcenter_page.dart';
import 'package:pretzel_apk/pages/wishlist/wishlist_page.dart';
import 'package:pretzel_apk/pages/setting/support/privacy_policy_page.dart';
import 'package:pretzel_apk/pages/setting/support/aboutUs_page.dart';
import 'package:pretzel_apk/pages/setting/activity/purchase_hist_page.dart';
import 'package:pretzel_apk/pages/setting/account/address_page.dart';
import 'package:pretzel_apk/pages/setting/account/payment_method_page.dart';
import 'package:pretzel_apk/auth/login_page.dart';
import 'package:pretzel_apk/pages/setting/activity/pending_books_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF6F2F8),
          title: const Text('Setting'), // Remove title since it's shown in body
        ),
      ),
      body: ListView(
        children: [
          _buildSection('Account', [
            _buildListTile(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.location_on_outlined,
              title: 'Address',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsPage(),
                    ),
                  ),
            ),
          ]),
          _buildSection('Activity', [
            _buildListTile(
              icon: Icons.pending_actions_outlined,
              title: 'Pending Books',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingBooksPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.history_outlined,
              title: 'Purchase History',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseHistoryPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.book_outlined,
              title: 'My Books',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyBooksPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.favorite_border_outlined,
              title: 'Wishlist',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WishlistPage(),
                    ),
                  ),
            ),
          ]),
          _buildSection('Support', [
            _buildListTile(
              icon: Icons.help_outline_outlined,
              title: 'Help Center',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  ),
            ),
            _buildListTile(
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ),
                  ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildListTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
    Color iconColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}
