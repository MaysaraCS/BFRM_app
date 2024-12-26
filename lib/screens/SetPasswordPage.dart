import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/signup.dart';
import 'package:bfrm_app_flutter/screens/OTP_Verify.dart';
import 'package:bfrm_app_flutter/screens/login.dart';
import '../constant.dart';
import 'user_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SetYourPasswordPage extends StatefulWidget {
  final String email;
  final String role;

  const SetYourPasswordPage({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  _SetYourPasswordPageState createState() => _SetYourPasswordPageState();
}

class _SetYourPasswordPageState extends State<SetYourPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Collecting user input
    final String password = _passwordController.text;
    final String passwordConfirmation = _confirmPasswordController.text;

    try {
      // Preparing data for API
      final response = await http.post(
        Uri.parse(registerURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'role': widget.role,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      // Handle response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          // Navigate to OTP Verification Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(email: widget.email),
            ),
          );
        } else {
          _showMessage(responseData['message'] ?? 'Registration failed');
        }
      } else {
        _showMessage('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again.');
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SignUpPage(
                  user: User(email: widget.email, role: widget.role),
                ),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset('lib/assets/logo.png', height: 60),
              const SizedBox(height: 20),
              Image.asset('lib/assets/setPass.png', height: 150),
              const SizedBox(height: 20),
              const Text(
                'Set Your Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Type your password',
                  hintText: 'Must be at least 6 characters',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Your Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  } else if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
