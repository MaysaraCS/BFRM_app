import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class Redeemcoupon extends StatelessWidget {
  final dynamic coupon;

  const Redeemcoupon({Key? key, required this.coupon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
        // Removed title as requested
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 5),
            Center(
              child: Image.asset(
                'lib/assets/logo.png', // Keep the logo as requested
                height: 80,
              ),
            ),
            SizedBox(height: 20),
            // Coupon photo (made a bit bigger)
            if (coupon['photo'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  'http://192.168.8.112:8080/storage/${coupon['photo']}',
                  height: 180, // Increased height for better display
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Please scan the QR at the restaurant counter to get the offer',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // QR Code
            QrImageView(
              data: generateQrData(coupon),
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
      ),
      // Bottom navigation bar with icons
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set to 2 as it’s the third tab (assuming Coupon is third)
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blue,
        onTap: (index) {
          // You can navigate based on the index selected
          // Just add the logic for each page as needed
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite List",
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

  /// Function to generate QR code data
  String generateQrData(Map<String, dynamic> coupon) {
    return jsonEncode({
      "description": coupon['description'] ?? "No description",
      "percentage": coupon['percentage'] ?? "0",
      "expiry_date": coupon['expiry_date'] ?? "No expiry date",
    });
  }
}
