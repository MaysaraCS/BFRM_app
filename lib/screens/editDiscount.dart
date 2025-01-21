import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constant.dart';

class EditDiscount extends StatefulWidget {
  final Map<String, dynamic> discount;

  const EditDiscount({required this.discount, Key? key}) : super(key: key);

  @override
  State<EditDiscount> createState() => _EditDiscountState();
}

class _EditDiscountState extends State<EditDiscount> {
  File? _image;
  late TextEditingController _descriptionController;
  String? _selectedFoodType;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.discount['description']);
    _selectedFoodType = widget.discount['food_type'];
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Function to update the discount
  Future<void> _updateDiscount() async {
    if (_descriptionController.text.isEmpty || _selectedFoodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$discountURL/${widget.discount['id']}?_method=PUT'),
    );

    // Attach the image file if a new one is selected
    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
    }
    request.fields['description'] = _descriptionController.text;
    request.fields['food_type'] = _selectedFoodType!;

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update discount')),
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
                      : widget.discount['photo'] != null
                      ? DecorationImage(
                    image: NetworkImage(widget.discount['photo']),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _image == null && widget.discount['photo'] == null
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
                onPressed: _updateDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50), // Wide and tall button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
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
