import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bfrm_app_flutter/screens/SuccessPage.dart';
import '../constant.dart';
import '../model/Login.dart';
import 'package:bfrm_app_flutter/screens/SuccessMerchantPage.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email; // Email passed from the previous page

  const OTPVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOtp() async {
    final String otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('Sending OTP verification request...');
      print('Email: ${widget.email}');
      print('OTP: $otp');
      print('URL: $OTPURL');

      final response = await http.post(
        Uri.parse(OTPURL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email.toLowerCase().trim(),
          'otp': otp
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true) {
          // Get user role from the response data
          String userRole = responseData['data']['role'];

          print('User Role: $userRole');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified successfully!')),
          );

          Login loginData = Login();
          loginData.email = widget.email;

          if (userRole == 'customer') {
            // Navigate to the SuccessPage for customer
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuccessPage(usernameData: loginData)),
            );
          } else if (userRole == 'merchant') {
            // Navigate to the SuccessMerchantPage for merchant
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Successmerchantpage(usernameData: loginData)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unknown user role.')),
            );
          }
        } else {
          // Show the error message from the server
          String errorMessage = responseData['message'] ?? 'Invalid OTP';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        // Handle different status codes
        String errorMessage = 'Error verifying OTP. Status: ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            print('Error parsing error response: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print('Exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent widget resizing
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // Logo
            Center(
              child: Image.asset(
                'lib/assets/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 20),
            // OTP Image
            Center(
              child: Image.asset(
                'lib/assets/otp.png',
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'OTP Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            const Text(
              'Enter the 6-digit verification code sent to your email',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Debug info (remove in production)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
              // child: Column(
              //   children: [
              //     Text('Email: ${widget.email}', style: TextStyle(fontSize: 12)),
              //     Text('URL: $OTPURL', style: TextStyle(fontSize: 12)),
              //   ],
              // ),
            ),
            const SizedBox(height: 20),
            // OTP TextField
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6, // Set max length to 6 digits
              decoration: InputDecoration(
                labelText: 'Enter 6-digit OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                counterText: '', // Hide the counter text
              ),
            ),
            const SizedBox(height: 20),
            // Verify OTP Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Verify OTP',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Resend OTP option (optional)
            TextButton(
              onPressed: () {
                // Add resend OTP functionality here if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resend OTP functionality not implemented yet')),
                );
              },
              child: const Text(
                'Didn\'t receive OTP? Resend',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}