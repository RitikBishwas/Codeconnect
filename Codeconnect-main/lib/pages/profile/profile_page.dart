import 'package:flutter/material.dart';
import 'package:nitd_code/models/user_model.dart';
import 'package:nitd_code/pages/profile/edit_profile_page.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<UserModel?> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is logged in");
        return null;
      }

      // Get user document from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid) // Query for matching UID
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        return UserModel.fromFirestore(userDoc.data() as Map<String, dynamic>);
      } else {
        print("User not found in Firestore!");
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor, // Base dark theme
      body: FutureBuilder<UserModel?>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Loading state
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load user data"));
          }

          UserModel user = snapshot.data!; // Loaded user data
          return Stack(
            children: [
              // Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Pallete.gradient1,
                      Pallete.gradient2,
                      Pallete.gradient3,
                    ],
                  ),
                ),
                height: 200,
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        child: SizedBox(height: 0)),

                    // Profile Section
                    Center(
                      child: Column(
                        children: [
                          // Profile Image with Glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Pallete.gradient2.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              // backgroundColor: Pallete.gradient2,
                              backgroundImage: NetworkImage(user.profileImage ??
                                  'https://cdn-icons-png.flaticon.com/512/149/149071.png'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Details Section
                    SizedBox(
                      height: 410, // Limit the height
                      child: Container(
                        width: 600,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.4), // Glassmorphism Effect
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ListView(
                          children: [
                            ProfileInfoTile(
                                icon: Icons.email,
                                title: 'Email',
                                subtitle: user.email),
                            ProfileInfoTile(
                                icon: Icons.school,
                                title: 'School/College',
                                subtitle: user.school),
                            ProfileInfoTile(
                                icon: Icons.phone,
                                title: 'Contact Number',
                                subtitle: user.contactNumber),
                            ProfileInfoTile(
                                icon: Icons.location_on,
                                title: 'Location',
                                subtitle: user.location),
                            ProfileInfoTile(
                              icon: Icons.calendar_month_rounded,
                              title: 'Batch',
                              // subtitle: user.year
                              subtitle: (user.year.isEmpty)
                                  ? 'Not provided'
                                  : user.year,
                            ),
                            ProfileInfoTile(
                                icon: Icons.business_rounded,
                                title: 'Company',
                                subtitle: (user.company?.isEmpty ?? true)
                                    ? 'Not provided'
                                    : user.company ?? 'Not provided'),
                            ProfileInfoTile(
                                icon: Icons.link,
                                title: 'GitHub',
                                subtitle: (user.github_url?.isEmpty ?? true)
                                    ? 'Not provided'
                                    : user.github_url ?? 'Not provided'),
                            ProfileInfoTile(
                                icon: Icons.link,
                                title: 'LinkedIn',
                                subtitle: (user.linkedin_url?.isEmpty ?? true)
                                    ? 'Not provided'
                                    : user.linkedin_url ?? 'Not provided'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Profile Button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        final updatedData = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(user: user),
                          ),
                        );

                        // Check if updatedData is returned and update the state
                        if (updatedData != null && mounted) {
                          setState(() {
                            user = updatedData;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.gradient2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        shadowColor: Pallete.gradient2.withOpacity(0.5),
                        elevation: 10,
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Profile Info Tile (Dark Theme)
class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Pallete.gradient2),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
