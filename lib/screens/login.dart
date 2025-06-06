import 'package:bfrm_app_flutter/model/Login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bfrm_app_flutter/screens/user_type.dart';
import 'package:bfrm_app_flutter/screens/signup.dart';
import 'package:bfrm_app_flutter/screens/CustomerHomePage.dart';
import 'package:bfrm_app_flutter/screens/Password_Recovery.dart';
import '../constant.dart';
import 'package:bfrm_app_flutter/screens/MerchantHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse(loginURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);

        // Show success message
        _showMessage(responseData['message']);

        // Get the user's role from `data`
        String userRole = responseData['data']['role'];

        // Create Login object from JSON response
        Login usernameData = Login.fromJson(responseData['data']);

        // ✅ FIX: Set the userId and authToken explicitly
        usernameData.userId = responseData['data']['id']?.toString() ??
            responseData['data']['user_id']?.toString() ??
            responseData['data']['_id']?.toString();
        usernameData.authToken = responseData['token'];

        // Debug print to check if userId is set
        print('User ID set to: ${usernameData.userId}');
        print('Auth Token set to: ${usernameData.authToken}');

        // Navigate to the appropriate home page
        if (userRole == 'customer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Customerhomepage(),
            ),
          );
        } else if (userRole == 'merchant') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Merchanthomepage(usernameData: usernameData),
            ),
          );
        }
      }
      else {
        // Show failure message
        _showMessage(responseData['message'] ?? "Login failed");
      }
    } catch (error) {
      print('Login error: $error'); // Add debug print
      _showMessage("An error occurred. Please try again later.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Logo
                Center(
                  child: Image.asset(
                    'lib/assets/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                // Login Image
                Center(
                  child: Image.asset(
                    'lib/assets/login.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                // Welcome Back
                Center(
                  child: const Text(
                    "WELCOME BACK!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Form Box
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Enter Your Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Enter Your Password",
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (value.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Forgot Password Text
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const PasswordRecoveryPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Login Button
                        ElevatedButton(
                          onPressed: _loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Login",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign-Up Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Do not have an account? ',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(
                              user: User(
                                email: "",
                                role: "",
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign-Up',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}