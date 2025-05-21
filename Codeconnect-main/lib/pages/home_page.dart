import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nitd_code/pages/alumni_page/alumni_page.dart';
import 'package:nitd_code/pages/discussion_page/discussion_page.dart';
import 'package:nitd_code/pages/interview_page/interview_page.dart';
import 'package:nitd_code/pages/problems_page/problems_page.dart';
import 'package:nitd_code/pages/profile/profile_page.dart';
import 'package:nitd_code/pages/contest/user/contest_list_page.dart';
import 'package:nitd_code/pages/contest/admin/contest_admin_list_page.dart';
import 'package:nitd_code/ui/login_screen.dart';
import 'package:nitd_code/ui/pallete.dart';

class HomePage extends StatefulWidget {
  // final String userId;
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userImage;
  List<Widget> _pages = [];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed, please try again")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserImage();
    _initializePages();
  }

  void _fetchUserImage() async {
    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where("uid", isEqualTo: _auth.currentUser!.uid)
        .get();

    if (userQuery.docs.isNotEmpty) {
      DocumentSnapshot userDoc = userQuery.docs.first;
      setState(() {
        userImage = userDoc['profileImage'];
      });
    }
  }

  void _initializePages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _pages = [
        const ProfilePage(),
        const DiscussionPage(),
        const ScheduleInterviewPage(),
        // const CodeEditorPage(),
        ProblemsPage(userId: FirebaseAuth.instance.currentUser!.uid),
        user.email == "admin@gmail.com"
            ? const ContestAdminListPage()
            : ContestListPage(userId: user.uid),
        const AlumniPage(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.borderColor,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/images/logo2.jpg",
                width: 10,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: screenWidth <= 800
            ? null
            : Row(
                children: [
                  ..._buildNavButtons(),
                  const Spacer(),
                  Tooltip(
                    message: "Profile Page",
                    child: IconButton(
                      onPressed: () => _onNavItemTapped(0),
                      icon: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          userImage ??
                              'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: "Logout",
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Pallete.whiteColor),
                      onPressed: () => _handleLogout(context),
                    ),
                  ),
                ],
              ),
        actions: [
          if (screenWidth <= 800)
            Builder(
              builder: (context) => Row(
                children: [
                  IconButton(
                    onPressed: () => _onNavItemTapped(0),
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        userImage ??
                            'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu,
                        size: 28, color: Pallete.whiteColor),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _pages[_selectedIndex],
      drawer: screenWidth <= 800
          ? Drawer(
              backgroundColor: Pallete.borderColor,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Pallete.borderColor),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          "assets/images/logo.jpg",
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  _buildDrawerItem(Icons.person, 'Profile Page', 0),
                  _buildDrawerItem(Icons.forum, 'Discussion Forums', 1),
                  _buildDrawerItem(Icons.work, 'Interview Page', 2),
                  _buildDrawerItem(Icons.assignment, 'Problems Page', 3),
                  _buildDrawerItem(Icons.emoji_events, 'Contest Page', 4),
                  _buildDrawerItem(
                      Icons.connect_without_contact, 'Alumni Page', 5),
                  ListTile(
                    leading:
                        const Icon(Icons.logout, color: Pallete.whiteColor),
                    title: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 16, color: Pallete.whiteColor),
                    ),
                    onTap: () {
                      _handleLogout(context);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            )
          : null,
    );
  }

  List<Widget> _buildNavButtons() {
    return [
      _navButton("Discussion", 1),
      _navButton("Interview", 2),
      _navButton("Problems", 3),
      _navButton("Contest", 4),
      _navButton("Alumni", 5),
    ];
  }

  Widget _navButton(String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _onNavItemTapped(index),
            style: TextButton.styleFrom(
              foregroundColor:
                  isSelected ? Pallete.gradient1 : Pallete.whiteColor,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: Text(title),
          ),
          if (isSelected)
            Container(
              width: 40,
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Pallete.gradient1, Pallete.gradient2]),
              ),
            ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color:
              _selectedIndex == index ? Pallete.gradient2 : Pallete.whiteColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color:
              _selectedIndex == index ? Pallete.gradient1 : Pallete.whiteColor,
        ),
      ),
      onTap: () {
        _onNavItemTapped(index);
        Navigator.pop(context);
      },
    );
  }
}
