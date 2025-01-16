import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditDiscount extends StatefulWidget {
  final Map<String, dynamic> discount;

  const EditDiscount({super.key, required this.discount});

  @override
  State<EditDiscount> createState() => _EditDiscountState();
}

class _EditDiscountState extends State<EditDiscount> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _foodTypeController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.discount['description']);
    _foodTypeController = TextEditingController(text: widget.discount['food_type']);
  }

  Future<void> _updateDiscount() async {
    if (_formKey.currentState!.validate()) {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://192.168.8.112:8080/api/discounts/${widget.discount['id']}'),
      );

      request.fields['description'] = _descriptionController.text;
      request.fields['food_type'] = _foodTypeController.text;

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _image!.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update discount')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Discount')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _foodTypeController,
                decoration: const InputDecoration(labelText: 'Food Type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a food type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Choose Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateDiscount,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
