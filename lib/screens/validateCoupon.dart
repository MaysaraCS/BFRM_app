import 'package:flutter/material.dart';
import 'dart:convert';

class ValidateCoupon extends StatelessWidget {
  final String scannedData;

  const ValidateCoupon({Key? key, required this.scannedData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? coupon;

    // Decode scanned QR data
    try {
      coupon = jsonDecode(scannedData);
    } catch (e) {
      coupon = null; // Handle invalid QR code data
    }

    bool isValid = coupon != null;
    bool isExpired = false;

    if (isValid && coupon!['expiry_date'] != null) {
      final expiryDate = DateTime.parse(coupon['expiry_date']);
      isExpired = DateTime.now().isAfter(expiryDate);
    }

    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
        // No title here
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'lib/assets/logo.png', // Move logo to the top
                height: 80,
              ),
            ),
            const SizedBox(height: 20),
            if (isValid && !isExpired) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 10),
              const Text(
                "Valid Coupon!",
                style: TextStyle(fontSize: 24, color: Colors.green),
              ),
              const SizedBox(height: 20),
              Text(
                "Description: ${coupon?['description'] ?? 'No description'}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Discount: ${coupon?['percentage'] ?? '0'}%",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Expires on: ${coupon?['expiry_date'] ?? 'No expiry date'}",
                style: const TextStyle(fontSize: 16),
              ),
            ] else if (isExpired) ...[
              const Icon(Icons.cancel, color: Colors.red, size: 100),
              const SizedBox(height: 10),
              const Text(
                "Coupon Expired",
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Text(
                "Expiry Date: ${coupon?['expiry_date'] ?? 'No expiry date'}",
                style: const TextStyle(fontSize: 16),
              ),
            ] else ...[
              const Icon(Icons.cancel, color: Colors.red, size: 100),
              const SizedBox(height: 10),
              const Text(
                "Invalid Coupon",
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Text(
                "Expiry Date: ${coupon?['expiry_date'] ?? 'No expiry date'}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set to 2 as it’s the third tab (assuming Coupon is third)
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blue,
        onTap: (index) {
          // Handle bottom navigation item tap
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Report",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: "Coupon",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
