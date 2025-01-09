import 'package:bfrm_app_flutter/model/Login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding and decoding
import 'package:bfrm_app_flutter/screens/CustomerHomePage.dart';
import '../constant.dart'; // Assuming this contains customerpreferenceURL


class DiningPreferencesPage extends StatefulWidget {
  final Login usernameData;
  const DiningPreferencesPage({super.key, required this.usernameData});

  // final List<String> cuisinePreferences;
  // final bool prefersCoupons;

  // const DiningPreferencesPage({
  //   Key? key,
  //   required this.usernameData,
  //   required this.cuisinePreferences,
  //   required this.prefersCoupons,
  // }) : super(key: key);

  @override
  State<DiningPreferencesPage> createState() => _DiningPreferencesPageState();
}

class _DiningPreferencesPageState extends State<DiningPreferencesPage> {
  // Checkbox values
  bool _isDaily = false;
  bool _isWeekly = false;
  bool _isOccasionally = false;

  // TextField controller for "Others"
  final TextEditingController _othersController = TextEditingController();

  // API URL

  // Submit preferences
  Future<void> _submitPreferences() async {
    final selectedPreferences = <String>[];

    if (_isDaily) selectedPreferences.add('Daily');
    if (_isWeekly) selectedPreferences.add('Weekly');
    if (_isOccasionally) selectedPreferences.add('Occasionally');
    if (_othersController.text.trim().isNotEmpty) {
      selectedPreferences.add(_othersController.text.trim());
    }

    if (selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option')),
      );
      return;
    }

    // Prepare data to send to the API
    final Map<String, dynamic> requestData = {
      "username": widget.usernameData.username,
      "cuisine_preferences": widget.usernameData.cuisneType,
      "prefers_coupons": widget.usernameData.couponType,
      "dining_preferences": selectedPreferences,
      "email": widget.usernameData.email,
      "interests" : widget.usernameData.couponType,
    };
    print(requestData);

    try {
      // Make the API call
      final response = await http.post(
        Uri.parse(customerpreferenceURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );
      final responseData = jsonDecode(response.body);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Data: ${responseData}');


      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        // Successfully saved preferences
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );

        // Navigate to CustomerHomepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Customerhomepage()),
        );
      } else {
        // Handle API errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: ${response.body}')),
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

              // Image
              Image.asset('lib/assets/pref3.png', height: 150), // Replace with your image
              const SizedBox(height: 20),

              const Text(
                "How often do you go to restaurants?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Options
              CheckboxListTile(
                title: const Text("Daily"),
                value: _isDaily,
                onChanged: (bool? value) {
                  setState(() {
                    _isDaily = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Weekly"),
                value: _isWeekly,
                onChanged: (bool? value) {
                  setState(() {
                    _isWeekly = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Occasionally"),
                value: _isOccasionally,
                onChanged: (bool? value) {
                  setState(() {
                    _isOccasionally = value!;
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

              // Save button
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
                  "Save",
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