import 'package:flutter/material.dart';
import 'cuisine_preferences_page.dart'; // Next page
import 'package:bfrm_app_flutter/screens/login.dart';
import 'package:http/http.dart' as http; // For making API requests
import 'dart:convert'; // For JSON encoding
import '../constant.dart'; // For customerpreferenceURL

class UsernamePage extends StatefulWidget {
  @override
  _UsernamePageState createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final TextEditingController _usernameController = TextEditingController();

  Future<void> _submitUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    final String username = _usernameController.text.trim();

    // Prepare the API request
    final url = Uri.parse(customerpreferenceURL);
    try {
      final response = await http.post(
        url,
        body: json.encode({'username': username}),
        headers: {'Content-Type': 'application/json'},
      );


      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');


      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CuisinePreferencesPage(username: username),
          ),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit username: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'lib/assets/username.png',
              height: 150, // Larger image
            ),
            const SizedBox(height: 20),
            const Text(
              "Choose your own username!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Type your username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button wide
              child: ElevatedButton(
                onPressed: _submitUsername,
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
