import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../authentication/auth_service.dart';
import '../authentication/forgot_password.dart';
import '../screens/history_screen.dart';
import '../authentication/change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user logged in"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("User data not found."),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final name =
              data["name"] ?? "User";

          final email =
              data["email"] ?? "";

          final generated =
              data["totalGenerated"] ?? 0;

          final scanned =
              data["totalScanned"] ?? 0;

          final verified =
              data["emailVerified"] ?? false;

          final initials = name
              .trim()
              .split(" ")
              .where((String e) => e.isNotEmpty)
              .take(2)
              .map((e) => e[0])
              .join()
              .toUpperCase();

          return SingleChildScrollView(
            // Added extra bottom padding so content clears the floating navigation bar
            padding: const EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: 120,
            ),
            child: Column(
              children: [

                CircleAvatar(
                  radius: 45,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 12),

                Chip(
                  avatar: Icon(
                    verified
                        ? Icons.verified
                        : Icons.error_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: verified
                      ? Colors.green
                      : Colors.red,
                  label: Text(
                    verified
                        ? "Email Verified"
                        : "Email Not Verified",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [

                        const Text(
                          "Statistics",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [

                            _StatCard(
                              title: "Generated",
                              value: generated.toString(),
                              icon: Icons.qr_code,
                            ),

                            Container(
                              height: 70,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),

                            _StatCard(
                              title: "Scanned",
                              value: scanned.toString(),
                              icon: Icons.qr_code_scanner,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Card(
                  child: Column(
                    children: [

                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.history),
                          ),
                          title: const Text(
                            "History",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            "View all scanned and generated QR codes",
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(
                          Icons.lock_reset,
                          color: Colors.blue,
                        ),
                        title: const Text("Change Password"),
                        subtitle: const Text("Update your account password securely"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.orange,
                        ),
                        title:
                        const Text("Logout"),
                        onTap: () async {
                          await AuthService
                              .instance
                              .logout();

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/login",
                                  (route) => false,
                            );
                          }
                        },
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text(
                          "Delete Account",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Delete Account"),
                              content: const Text(
                                "This action cannot be undone.\n\nAre you sure?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () async {
                                    // 1. Close the dialog first
                                    Navigator.pop(dialogContext);

                                    try {
                                      // 2. Perform account deletion via your AuthService
                                      await AuthService.instance.deleteAccount();

                                      // 3. Force route clearance to login screen
                                      if (context.mounted) {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          "/login",
                                              (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      // Handle potential errors (e.g., requires-recent-login)
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Failed to delete account: ${e.toString()}"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Icon(
          icon,
          size: 32,
          color: Colors.blue,
        ),

        const SizedBox(height: 8),

        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(title),
      ],
    );
  }
}