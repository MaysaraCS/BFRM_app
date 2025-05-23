import 'package:flutter/material.dart';
import '../model/Login.dart';
import '../constant.dart';
import 'dart:convert';
import 'dart:io';
import 'package:bfrm_app_flutter/screens/beaconOrder.dart';
import 'package:bfrm_app_flutter/screens/MerchantHomePage.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class Contactnumber extends StatefulWidget {
  final Login usernameData;
  const Contactnumber({super.key, required this.usernameData});

  @override
  State<Contactnumber> createState() => _ContactnumberState();
}

class _ContactnumberState extends State<Contactnumber> {
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  // Function to validate phone number
  bool _validatePhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters for validation
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it's a valid Malaysian phone number format
    // Malaysian numbers: +60xxxxxxxxx or 60xxxxxxxxx or 0xxxxxxxxx
    RegExp malaysianPattern = RegExp(r'^(\+?60|0)[1-9]\d{7,9}$');

    return malaysianPattern.hasMatch(cleanNumber) && cleanNumber.length >= 10;
  }

  // Function to format phone number for storage
  String _formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Convert to international format
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '+60${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('60') && !cleanNumber.startsWith('+60')) {
      cleanNumber = '+$cleanNumber';
    } else if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+60$cleanNumber';
    }

    return cleanNumber;
  }

  Future<void> _submitRestaurantContact() async {
    final String restaurantContact = _contactController.text.trim();

    // Validate phone number
    if (restaurantContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your contact number')),
      );
      return;
    }

    if (!_validatePhoneNumber(restaurantContact)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Malaysian phone number')),
      );
      return;
    }

    // Format and save contact number
    final String formattedContact = _formatPhoneNumber(restaurantContact);
    widget.usernameData.restaurantContact = formattedContact;

    // Validate required business data
    if (widget.usernameData.email == null || widget.usernameData.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }

    if (widget.usernameData.restaurantName == null || widget.usernameData.restaurantName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant name is required')),
      );
      return;
    }

    if (widget.usernameData.restaurantLocation == null || widget.usernameData.restaurantLocation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant location is required')),
      );
      return;
    }

    if (widget.usernameData.primGoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary goals are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(businessRegistrationURL));

      // Add headers
      request.headers.addAll({
        "Accept": "application/json",
        // Add authentication token if you have it stored
        if (widget.usernameData.authToken != null)
          "Authorization": "Bearer ${widget.usernameData.authToken}",
      });

      // Add text fields (ensure all values are non-null strings)
      request.fields.addAll({
        "email": widget.usernameData.email ?? "",
        "restaurant_name": widget.usernameData.restaurantName ?? "",
        "primary_goal": widget.usernameData.primGoal.join(', '), // Convert list to string
        "other_goal": widget.usernameData.otherGoal ?? "",
        "location": widget.usernameData.restaurantLocation ?? "",
        "phone_number": formattedContact,
      });

      // Add logo file if it exists
      if (widget.usernameData.restaurantLogo != null &&
          widget.usernameData.restaurantLogo!.isNotEmpty) {
        try {
          // Assuming restaurantLogo is a file path
          File logoFile = File(widget.usernameData.restaurantLogo!);
          if (await logoFile.exists()) {
            var logoMultipartFile = await http.MultipartFile.fromPath(
              'logo',
              logoFile.path,
            );
            request.files.add(logoMultipartFile);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logo file not found')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading logo: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant logo is required')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add photo file if it exists
      if (widget.usernameData.restaurantPhoto != null &&
          widget.usernameData.restaurantPhoto!.isNotEmpty) {
        try {
          // Assuming restaurantPhoto is a file path
          File photoFile = File(widget.usernameData.restaurantPhoto!);
          if (await photoFile.exists()) {
            var photoMultipartFile = await http.MultipartFile.fromPath(
              'photo',
              photoFile.path,
            );
            request.files.add(photoMultipartFile);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo file not found')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading photo: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant photo is required')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Sending multipart request to: $businessRegistrationURL");
      print("Fields: ${request.fields}");
      print("Files: ${request.files.map((f) => f.field).toList()}");

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isLoading = false;
      });

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle redirect response (302)
      if (response.statusCode == 302) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required. Please login again.')),
        );

        // Navigate back to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true || responseData['message'] == 'Business registered successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant registered successfully!')),
          );

          // Clear the form data after successful registration
          widget.usernameData.clearBusinessData();

          // Navigate to Merchant Homepage
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Merchanthomepage(usernameData: widget.usernameData)),
            (route) => false,
          );
        } else {
          String errorMessage = responseData['message'] ?? 'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        final responseData = jsonDecode(response.body);
        String errorMessage = 'Validation error: ';

        if (responseData['errors'] != null) {
          List<String> errors = [];
          responseData['errors'].forEach((key, value) {
            if (value is List) {
              errors.addAll(value.cast<String>());
            }
          });
          errorMessage += errors.join(', ');
        } else {
          errorMessage += responseData['message'] ?? 'Please check your input';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied. Please ensure you have merchant privileges.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode} - ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      print('Network error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.png',
              height: 80,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'lib/assets/contactInfo.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              "Business Contact Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your restaurant's contact number",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Phone number input field
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Contact Number",
                hintText: "e.g., +60123456789 or 0123456789",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 10),

            // Helper text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accepted formats:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text('• +60123456789', style: TextStyle(fontSize: 12)),
                  Text('• 0123456789', style: TextStyle(fontSize: 12)),
                  Text('• 60123456789', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Summary of collected data
            if (widget.usernameData.restaurantName != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registration Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Restaurant: ${widget.usernameData.restaurantName}'),
                    Text('Location: ${widget.usernameData.restaurantLocation ?? "Not set"}'),
                    Text('Email: ${widget.usernameData.email}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRestaurantContact,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Registering...",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                )
                    : const Text(
                  "COMPLETE REGISTRATION",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}