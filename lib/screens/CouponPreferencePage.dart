import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding and decoding
import 'package:bfrm_app_flutter/screens/DiningPreferencesPage.dart';
import '../constant.dart';
import '../model/Login.dart'; // Assuming this contains customerpreferenceURL

class CouponPreferencePage extends StatefulWidget {
  final Login usernameData; // Assume you passed username in the previous page
  const CouponPreferencePage({super.key, required this.usernameData});
  //final List<String> cuisinePreferences;



  @override
  State<CouponPreferencePage> createState() => _CouponPreferencePageState();
}

class _CouponPreferencePageState extends State<CouponPreferencePage> {
  // Checkbox values
  bool _isDiscount = false;
  bool _isCoupon = false;
  bool _isReward = false;

  // TextField controller for "Others"
  final TextEditingController _othersController = TextEditingController();

  // Submit preferences
  Future<void> _submitPreferences() async {
    final selectedPreferences = <String>[];

    if (_isDiscount) selectedPreferences.add('Discounts');
    if (_isCoupon) selectedPreferences.add('Coupons');
    if (_isReward) selectedPreferences.add('Rewards');
    if (_othersController.text.trim().isNotEmpty) {
      selectedPreferences.add(_othersController.text.trim());
    }

    if (selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one preference')),
      );
      return;
    }
    //
    // // Prepare data to send to the API
    // final Map<String, dynamic> requestData = {
    //   "username": widget.username,
    //   "couponPreferences": selectedPreferences,
    // };
    //
    // try {
    //   // Make the API call
    //   final response = await http.post(
    //     Uri.parse(customerpreferenceURL),
    //     headers: {"Content-Type": "application/json"},
    //     body: jsonEncode(requestData),
    //   );
    //
    //   final responseData = jsonDecode(response.body);
    //
    //   if (response.statusCode == 200 && responseData['status'] == true) {
    //     // Successfully saved preferences, now navigate to DiningPreferencesPage
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => DiningPreferencesPage(
    //           username: widget.username,  // Pass the username
    //           cuisinePreferences: widget.cuisinePreferences, // Pass the selected cuisine preferences
    //           prefersCoupons: _isCoupon, // Pass the prefersCoupons value
    //         ),
    //       ),
    //     );
    //   } else {
    //     // Handle API errors
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to save preferences: ${response.body}')),
    //     );
    //   }
    // } catch (error) {
    //   // Handle network or other errors
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error: $error')),
    //   );
    // }

    widget.usernameData.couponType = selectedPreferences;
    Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiningPreferencesPage(usernameData:widget.usernameData),
              ),
            );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Skip logic here
            },
            child: const Text(
              "Skip",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo at the top
              Image.asset('lib/assets/logo.png', height: 80),
              const SizedBox(height: 20),

              // Coupon Image
              Image.asset('lib/assets/pref2.png', height: 150), // Replace with your image
              const SizedBox(height: 20),

              const Text(
                "What are you interested in?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Interest options
              CheckboxListTile(
                title: const Text("Discounts"),
                value: _isDiscount,
                onChanged: (bool? value) {
                  setState(() {
                    _isDiscount = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Coupons"),
                value: _isCoupon,
                onChanged: (bool? value) {
                  setState(() {
                    _isCoupon = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Rewards"),
                value: _isReward,
                onChanged: (bool? value) {
                  setState(() {
                    _isReward = value!;
                  });
                },
              ),

              // TextField for "Others"
              const SizedBox(height: 10),
              TextField(
                controller: _othersController,
                decoration: InputDecoration(
                  labelText: "Others (please specify)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Next button
              ElevatedButton(
                onPressed: _submitPreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "NEXT",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
