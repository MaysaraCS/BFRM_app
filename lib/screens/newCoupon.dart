import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

import 'couponList.dart';
import '../constant.dart';

class NewCoupon extends StatefulWidget {
  @override
  _NewCouponState createState() => _NewCouponState();
}

class _NewCouponState extends State<NewCoupon> {
  File? _image;
  String? _selectedPercentage;
  DateTime? _selectedDate;
  final _descriptionController = TextEditingController();
  final _beaconIdController = TextEditingController(); // New controller for Beacon ID

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _publishCoupon() async {
    if (_image == null ||
        _descriptionController.text.isEmpty ||
        _selectedPercentage == null ||
        _selectedDate == null ||
        _beaconIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(couponURL),
    );

    request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
    request.fields['description'] = _descriptionController.text;
    request.fields['percentage'] = _selectedPercentage!;
    request.fields['expiry_date'] = _selectedDate!.toIso8601String();
    request.fields['beacon_id'] = _beaconIdController.text;

    final response = await request.send();

    if (response.statusCode == 201) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CouponListPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon published successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to publish coupon')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures keyboard does not block input fields
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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
                  color: Colors.blue,
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
                    'Add Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return CupertinoPicker(
                      backgroundColor: Colors.white,
                      itemExtent: 32.0,
                      onSelectedItemChanged: (int index) {
                        setState(() {
                          _selectedPercentage = '${(index + 1) * 5}';
                        });
                      },
                      children: List.generate(20, (index) => Center(child: Text('${(index + 1) * 5}%'))),
                    );
                  },
                );
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: _boxDecoration(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedPercentage != null ? '$_selectedPercentage% off' : 'Select Percentage',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectExpiryDate,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: _boxDecoration(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select Expiry Date',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _beaconIdController,
              decoration: _inputDecoration('Beacon ID'),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _publishCoupon,
                style: _buttonStyle(),
                child: const Text(
                  'Publish',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Common styling for input fields
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styling for box elements (like Percentage & Expiry Date selection)
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  // Common button style
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
