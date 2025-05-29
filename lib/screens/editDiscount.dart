import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:bfrm_app_flutter/controllers/ble_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant.dart';
import '../model/Login.dart';

class EditDiscount extends StatefulWidget {
  final Map<String, dynamic> discount;
  final Login? usernameData; // Add Login model for authentication

  const EditDiscount({
    required this.discount,
    this.usernameData,
    Key? key
  }) : super(key: key);

  @override
  State<EditDiscount> createState() => _EditDiscountState();
}

class _EditDiscountState extends State<EditDiscount> {
  File? _image;
  late TextEditingController _descriptionController;
  String? _selectedFoodType;
  String? _selectedBeaconId;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isScanning = false;

  final BleController _bleController = Get.put(BleController());

  // Complete food type options matching NewDiscount
  final List<String> _foodTypes = [
    "Malay Food",
    "Indian Food",
    "Chinese Food",
    "Western Food",
    "Nasi Arab",
    "Japanese Food",
    "Korean Food",
    "Thai Food",
    "Italian Food",
    "Mexican Food"
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeBle();
  }

  void _initializeFields() {
    _descriptionController = TextEditingController(
        text: widget.discount['description'] ?? ''
    );
    _selectedFoodType = widget.discount['food_type'];
    _selectedBeaconId = widget.discount['beacon_id'];

    // Handle image URL - construct proper URL if needed
    if (widget.discount['photo'] != null && widget.discount['photo'].isNotEmpty) {
      String photoPath = widget.discount['photo'];
      if (photoPath.startsWith('http')) {
        _currentImageUrl = photoPath;
      } else {
        // Construct full URL using your storage structure
        _currentImageUrl = 'http://192.168.0.197:8080/storage/$photoPath';
      }
    }
  }

  Future<void> _initializeBle() async {
    await _bleController.initNotifications();
  }

  // Method to ensure we have proper authentication data (similar to NewDiscount)
  Future<Login?> _ensureAuthenticationData() async {
    Login? authData = widget.usernameData;

    // Check if we have the essential data
    if (authData?.userId != null &&
        authData!.userId!.isNotEmpty &&
        authData.authToken != null &&
        authData.authToken!.isNotEmpty) {
      print('✅ Authentication data is already present');
      return authData;
    }

    print('⚠️ Missing authentication data, attempting to restore from SharedPreferences');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Try to restore from SharedPreferences
      String? savedToken = prefs.getString('token');
      String? savedUserId = prefs.getString('user_id');
      String? savedEmail = prefs.getString('user_email');
      String? savedRole = prefs.getString('user_role');

      if (savedToken != null && savedUserId != null) {
        // Create new Login object with restored data
        Login restoredAuth = Login(
          authToken: savedToken,
          userId: savedUserId,
          email: savedEmail ?? '',
          userRole: savedRole ?? '',
        );

        print('✅ Authentication data restored from SharedPreferences');
        print('✅ User ID: ${restoredAuth.userId}');
        print('✅ Auth Token: Present');
        return restoredAuth;
      }
    } catch (e) {
      print('❌ Error restoring authentication data: $e');
    }

    print('❌ Could not restore authentication data');
    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _startBeaconScan() async {
    setState(() {
      _isScanning = true;
    });

    // Clear previous scan results
    _bleController.scannedBeaconIds.clear();

    // Start scanning
    await _bleController.startScan();

    // Show bottom sheet with scanning results
    _showBeaconSelectionBottomSheet();
  }

  void _showBeaconSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Beacon Device',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isScanning = false;
                      });
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Obx(() => _bleController.isScanning.value
                  ? Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Scanning for beacon devices...'),
                ],
              )
                  : Row(
                children: [
                  Icon(Icons.bluetooth_searching, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Scan completed'),
                ],
              )),
              SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final beaconIds = _bleController.scannedBeaconIds;

                  if (beaconIds.isEmpty && !_bleController.isScanning.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No beacon devices found.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _bleController.startScan();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Scan Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: beaconIds.length,
                    itemBuilder: (context, index) {
                      final beaconId = beaconIds[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                          ),
                          title: Text(
                            'Beacon Device',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            beaconId,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            setState(() {
                              _selectedBeaconId = beaconId;
                              _isScanning = false;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Beacon device updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isScanning = false;
      });
    });
  }

  Future<void> _updateDiscount() async {
    // Ensure we have proper authentication data
    Login? authData = await _ensureAuthenticationData();
    if (authData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_selectedFoodType == null || _selectedFoodType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food type')),
      );
      return;
    }

    if (_selectedBeaconId == null || _selectedBeaconId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a beacon device')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use PUT method for update (Laravel RESTful convention)
      final request = http.MultipartRequest(
        'POST', // Using POST with _method=PUT for Laravel
        Uri.parse('$discountURL/${widget.discount['id']}?_method=PUT'),
      );

      // Add proper headers including authentication
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer ${authData.authToken!}',
      });

      // Debug print the data being sent
      print('📤 Updating discount with data:');
      print('Discount ID: ${widget.discount['id']}');
      print('Description: ${_descriptionController.text.trim()}');
      print('Food Type: $_selectedFoodType');
      print('Beacon ID: $_selectedBeaconId');
      print('New Image: ${_image != null ? "Yes" : "No"}');

      // Add fields
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['food_type'] = _selectedFoodType!;
      request.fields['beacon_id'] = _selectedBeaconId!;

      // Add image file if new one is selected
      if (_image != null) {
        try {
          request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
          print('✅ New image file added successfully');
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reading image file: ${e.toString()}')),
          );
          return;
        }
      }

      print('📤 Sending update request to: $discountURL/${widget.discount['id']}');
      print('📤 Request fields: ${request.fields}');

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseString');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 422) {
        // Handle validation errors
        String errorMessage = 'Validation error occurred';
        try {
          final responseData = json.decode(responseString);
          if (responseData['errors'] != null) {
            List<String> errors = [];
            responseData['errors'].forEach((key, value) {
              if (value is List) {
                errors.addAll(value.cast<String>());
              }
            });
            errorMessage = errors.join(', ');
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          // Use default error message
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        String errorMessage = 'Failed to update discount';

        try {
          final responseData = json.decode(responseString);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          errorMessage = 'Failed to update discount (Error: ${response.statusCode})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating discount: $e');

      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid server response';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Edit Discount'),
        centerTitle: true,
        elevation: 0,
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  image: _image != null
                      ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                      : _currentImageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(_currentImageUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _image == null && _currentImageUrl == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    if (_image == null && _currentImageUrl != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tap to change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Field
            TextField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description'),
              maxLines: 3,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),

            // Food Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              decoration: _inputDecoration('Food Type'),
              hint: Text('Select Food Type'),
              items: _foodTypes.map((String foodType) {
                return DropdownMenuItem<String>(
                  value: foodType,
                  child: Text(foodType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFoodType = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Current Beacon Selection Section
            Container(
              width: double.infinity,
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Beacon Device',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_selectedBeaconId != null)
                                Text(
                                  'ID: ${_selectedBeaconId!.substring(0, 12)}...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedBeaconId != null)
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Icon(Icons.bluetooth_searching, color: Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_selectedBeaconId != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Beacon ID:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedBeaconId!,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scan Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _startBeaconScan,
                icon: _isScanning
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.bluetooth_searching),
                label: Text(_isScanning ? 'Scanning...' : 'Change Beacon Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Update Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateDiscount,
                style: _buttonStyle(),
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Updating...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Update Discount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Common styling for box elements
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
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
      elevation: 2,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}