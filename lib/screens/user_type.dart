import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/signup.dart';
import 'package:bfrm_app_flutter/screens/welcome_page.dart';

class User {
  String? role; // Add role property
  String? email; // Add email property
  String? password; // Add password property
  String? passwordConfirmation; // Add password_confirmation property

  User({
    this.role,
    this.email,
    this.password,
    this.passwordConfirmation,
  });
}


class UserTypePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WelcomePage()),
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Space between app bar and logo
          Center(
            child: Column(
              children: [
                Image.asset('lib/assets/logo.png', height: 80), // Replace with your logo
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Image
                Image.asset('lib/assets/user-1.png', height: 200),

                const SizedBox(height: 20),

                const Text(
                  'What type of user you are?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Regular Customer Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: 250, // Set custom width
                    child: ElevatedButton.icon(
                      onPressed: () {
                        User user = User(role: 'customer'); // Set role to customer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(user: user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person, size: 24),
                      label: const Text(
                        'Regular Customer',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Restaurant Owner Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: 250, // Set custom width
                    child: ElevatedButton.icon(
                      onPressed: () {
                        User user = User(role: 'merchant'); // Set role to merchant
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(user: user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant, size: 24),
                      label: const Text(
                        'Restaurant Owner',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
