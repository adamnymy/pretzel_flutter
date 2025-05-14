import 'package:flutter/material.dart';
import 'package:pretzel_apk/pages/wishlist/wishlist_page.dart';
import 'package:pretzel_apk/pages/home/home_page.dart';
import 'package:pretzel_apk/pages/sell/sell_page.dart';
import 'package:pretzel_apk/pages/notifications/notifications_page.dart';
import 'package:pretzel_apk/pages/profile/profile_page.dart';
import 'package:pretzel_apk/navbar/cart_page.dart';
import 'package:pretzel_apk/navbar/message_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pretzel_apk/pages/setting/setting_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  // List of pages for each tab
  final List<Widget> _pages = const [
    HomePage(),
    WishlistPage(),
    SizedBox(), // Placeholder for SellPage
    NotificationsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to SellPage as a modal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SellPage(),
          fullscreenDialog: true,
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8), // Light purple background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor: const Color(0xFFF6F2F8), // Matching background color
          toolbarHeight: 48.0,
          leadingWidth: 0, // Remove default leading space
          title:
              _selectedIndex == 0
                  ? Padding(
                    padding: const EdgeInsets.only(top: 2.0), // Reduced padding
                    child: Image.asset(
                      'assets/images/logo2.png',
                      height: 40, // Slightly reduced height
                      filterQuality: FilterQuality.high,
                    ),
                  )
                  : Text(
                    _getTitle(_selectedIndex),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
          actions: [
            // Show settings button only on profile page
            if (_selectedIndex == 4)
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 24, // Adjusted size
                ),
                padding: const EdgeInsets.all(8), // Added padding
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 24, // Adjusted size
              ),
              padding: const EdgeInsets.all(8), // Added padding
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.message_outlined,
                    size: 24, // Adjusted size
                  ),
                  padding: const EdgeInsets.all(8), // Added padding
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagePage(),
                        ),
                      ),
                ),
                // Adjust notification dot position
                Positioned(
                  right: 8,
                  top: 8,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseAuth.instance.currentUser != null
                            ? FirebaseFirestore.instance
                                .collection('chats')
                                .where(
                                  'participants',
                                  arrayContains:
                                      FirebaseAuth.instance.currentUser!.uid,
                                )
                                .where('unreadCount', isGreaterThan: 0)
                                .limit(1)
                                .snapshots()
                            : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: [
            _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
            _buildNavItem(
              Icons.bookmark_rounded, // Changed from favorite_rounded
              Icons.bookmark_outline, // Changed from favorite_outline
              'Wishlist', // Changed from 'Favorites'
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              label: 'Sell',
            ),
            _buildNavItem(
              Icons.notifications_rounded,
              Icons.notifications_outlined,
              'Updates',
            ),
            _buildNavItem(
              Icons.person_rounded,
              Icons.person_outline,
              'Profile',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(unselectedIcon),
      activeIcon: Icon(selectedIcon),
      label: label,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return 'Wishlist';
      case 2:
        return 'Add Book';
      case 3:
        return 'Updates';
      case 4:
        return 'Profile';
      default:
        return 'Home';
    }
  }
}
