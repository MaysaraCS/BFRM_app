import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For API requests
import 'dart:convert'; // For JSON encoding and decoding
import '../constant.dart'; // Assuming this contains customerpreferenceURL
import 'package:bfrm_app_flutter/screens/CouponPreferencePage.dart';

class CuisinePreferencesPage extends StatefulWidget {
  final String username; // Assume you passed username in the previous page
  const CuisinePreferencesPage({super.key, required this.username});

  @override
  State<CuisinePreferencesPage> createState() => _CuisinePreferencesPageState();
}

class _CuisinePreferencesPageState extends State<CuisinePreferencesPage> {
  // Checkbox values
  bool _isIndian = false;
  bool _isMalay = false;
  bool _isChinese = false;

  // TextField controller for "Others"
  final TextEditingController _othersController = TextEditingController();

  // Submit preferences to API
  Future<void> _submitPreferences() async {
    final selectedCuisines = <String>[];

    if (_isIndian) selectedCuisines.add('Indian');
    if (_isMalay) selectedCuisines.add('Malay');
    if (_isChinese) selectedCuisines.add('Chinese');
    if (_othersController.text.trim().isNotEmpty) {
      selectedCuisines.add(_othersController.text.trim());
    }

    if (selectedCuisines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one cuisine preference')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(customerpreferenceURL), // Assuming it's in constant.dart
        headers: {"Content-Type": "application/json"}, // Ensure JSON headers
        body: jsonEncode({
          'username': widget.username,
          'cuisines': selectedCuisines,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CouponPreferencePage(
              username: widget.username,  // Pass the username
              cuisinePreferences: selectedCuisines, // Pass the selected cuisine preferences
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Failed to connect to the server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.white, // White app bar for consistency
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        centerTitle: true,
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

              // Preference image
              Image.asset('lib/assets/pref1.png', height: 120), // Adjusted size
              const SizedBox(height: 20),

              const Text(
                "What type of cuisine do you prefer?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Cuisine preference checkboxes
              CheckboxListTile(
                title: const Text("Indian"),
                value: _isIndian,
                onChanged: (bool? value) {
                  setState(() {
                    _isIndian = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Malay"),
                value: _isMalay,
                onChanged: (bool? value) {
                  setState(() {
                    _isMalay = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Chinese"),
                value: _isChinese,
                onChanged: (bool? value) {
                  setState(() {
                    _isChinese = value!;
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

              // Submit button
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
                  "Next",
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
