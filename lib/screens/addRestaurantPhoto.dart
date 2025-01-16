import 'package:flutter/material.dart';

import '../model/Login.dart';
import 'contactNumber.dart';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';



class Addrestaurantphoto extends StatefulWidget {
  final Login usernameData; // Assume you passed location in the previous page
  const Addrestaurantphoto({super.key, required this.usernameData});

  @override
  State<Addrestaurantphoto> createState() => _AddrestaurantphotoState();
}

class _AddrestaurantphotoState extends State<Addrestaurantphoto> {

  File? _selectedImage; // To store the selected image
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Store the selected file
      });
    }
  }
  // Function to handle "SAVE" button click
  Future<void> _submitRestaurantPhoto() async {
    if (_selectedImage != null) {
      widget.usernameData.restaurantPhoto = _selectedImage!.path;
      // Save file path to model

      //widget.usernameData.restaurantPhoto = _selectedImage!;
      // Navigate to the next page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Contactnumber(usernameData: widget.usernameData),
        ),
      );
    } else {
      // Show an error message if no image is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image before proceeding.')),
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
            // const SizedBox(height: 20),
            // Image.asset(
            //   'lib/assets/addResPhoto.png',
            //   height: 150, // Larger image
            // ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
              child: _selectedImage == null
                  ? const Icon(Icons.person, size: 80, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              "add restaurant photo !",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                backgroundColor: Colors.grey[200],
              ),
              icon: const Icon(Icons.photo_library, color: Colors.blue),
              label: const Text(
                "Open Gallery",
                style: TextStyle(color: Colors.black),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRestaurantPhoto,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("SAVE", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

