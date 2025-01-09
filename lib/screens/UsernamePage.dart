import 'dart:developer';

import 'package:bfrm_app_flutter/model/Login.dart';
import 'package:flutter/material.dart';
import 'cuisine_preferences_page.dart'; // Next page
import 'package:bfrm_app_flutter/screens/login.dart';
import 'package:http/http.dart' as http; // For making API requests
import 'dart:convert'; // For JSON encoding
import '../constant.dart'; // For customerpreferenceURL

class UsernamePage extends StatefulWidget {
  final Login usernameData;
  const UsernamePage({Key? key, required this.usernameData}) : super(key: key); // Update the constructor

  @override
  _UsernamePageState createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final TextEditingController _usernameController = TextEditingController();
  //final TextEditingController _emailController = TextEditingController();

  Future<void> _submitUsername() async {
    // if (_usernameController.text
    //     .trim()
    //     .isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please enter a username')),
    //   );
    //   return;
    // }
    //
    final String username = _usernameController.text.trim();
    //final String email = _emailController.text.trim();


    //
    // // Prepare the API request
    // final url = Uri.parse(customerpreferenceURL);
    // try {
    //   final response = await http.post(
    //     url,
    //     body: json.encode({
    //       'username': username,
    //       'email': '',
    //     }),
    //     headers: {'Content-Type': 'application/json'},
    //   );
    //
    //   print('Response status: ${response.statusCode}');
    //   print('Response body: ${response.body}');
    //   print('error in line 39');
    //   print('url:->>>>>${url}');
    //
    //   final responseData = jsonDecode(response.body);
    //   log(response.toString());
    //
    //   if (response.statusCode == 200 && responseData['success'] == true) {
    //     print('error in line 44');
    //
    //     final responseData = jsonDecode(response.body);
    //     print(responseData);
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => CuisinePreferencesPage(username: username),
    //       ),
    //     );
    //     print('error in line 54');
    //
    //   } else {
    //
    //     //inspect(response);
    //     print('error in line 57');
    //
    //     final errorMessage = jsonDecode(response.body)['message'] ??
    //         'Unknown error';
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to submit username: $errorMessage')),
    //     );
    //   }
    //   print('error in line 65');
    //
    // } catch (e) {
    //   print('error in line 68');
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error: $e')),
    //   );
    // }
    //Login loginData = Login();
    widget.usernameData.username = username;
    //loginData.email = email;


    Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CuisinePreferencesPage(usernameData:widget.usernameData),
              ),
            );
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
