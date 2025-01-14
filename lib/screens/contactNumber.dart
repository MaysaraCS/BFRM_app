import 'package:flutter/material.dart';

import '../model/Login.dart';
import '../constant.dart';
import 'dart:convert';
import 'package:bfrm_app_flutter/screens/beaconOrder.dart';

import 'package:http/http.dart' as http;

import 'login.dart';

class Contactnumber extends StatefulWidget {
  final Login usernameData; // Assume you passed location in the previous page
  const Contactnumber({super.key, required this.usernameData});

  @override
  State<Contactnumber> createState() => _ContactnumberState();
}

class _ContactnumberState extends State<Contactnumber> {
  final TextEditingController _contactController = TextEditingController();

  Future<void> _submitRestaurantContact() async {
    final String restaurantContact = _contactController.text.trim();
    widget.usernameData.restaurantContact = restaurantContact;

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Merchanthomepage(),
    //   ),
    // );
    final Map<String, dynamic> requestData = {
      "email": widget.usernameData.email,
      "primary_goal": widget.usernameData.PrimGoal,
      "prefers_coupons": widget.usernameData.couponType,
      "location	": widget.usernameData.restaurantLocation,
      "logo	": widget.usernameData.restaurantLogo,
      "photo	": widget.usernameData.restaurantPhoto,
      "phone_number		": restaurantContact,
    };

    try {
      // Make the API call
      final response = await http.post(
        Uri.parse(businessRegistrationURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );
      final responseData = jsonDecode(response.body);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Data: ${responseData}');


      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['status'] == true) {
        // Successfully saved preferences
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant Registered successfully')),
        );

        // Navigate to CustomerHomepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Beaconorder()),
        );
      } else {
        // Handle API errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save information: ${response.body}')),
        );
      }
    } catch (error) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent widget resizing

      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
      body: Padding(
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
              height: 150, // Larger image
            ),
            const SizedBox(height: 20),
            const Text(
              "Business contact information !",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: "Type your Restaurant name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button wide
              child: ElevatedButton(
                onPressed: _submitRestaurantContact,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("NEXT", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
