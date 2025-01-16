import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constant.dart';

class NewDiscount extends StatefulWidget {
  const NewDiscount({super.key});

  @override
  State<NewDiscount> createState() => _NewDiscountState();
}

class _NewDiscountState extends State<NewDiscount> {
  File? _image;
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedFoodType;

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Function to post the data
  Future<void> _postDiscount() async {
    if (_image == null || _descriptionController.text.isEmpty || _selectedFoodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(discountURL), // Use the provided discountURL constant
    );

    // Attach the image file
    request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
    request.fields['description'] = _descriptionController.text;
    request.fields['food_type'] = _selectedFoodType!;

    final response = await request.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount posted successfully')),
      );
      Navigator.pop(context); // Go back after success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post discount')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        //title: const Text("New Discount Page"),
        //backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'lib/assets/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                  image: _image != null
                      ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _image == null
                    ? const Center(
                  child: Text(
                    "Add Photo +",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              hint: const Text("Select Food Type"),
              items: [
                "Malay Food",
                "Indian Food",
                "Chinese Food",
                "Western Food",
                "Nasi Arab"
              ]
                  .map((foodType) => DropdownMenuItem<String>(
                value: foodType,
                child: Text(foodType),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFoodType = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _postDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50), // Wide and tall button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
