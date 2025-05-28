import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:bfrm_app_flutter/controllers/ble_controller.dart';
import 'dart:convert';
import '../model/Login.dart';
import 'couponList.dart';
import '../constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewCoupon extends StatefulWidget {
  final Login usernameData; // Add Login model to get merchant ID

  const NewCoupon({Key? key, required this.usernameData}) : super(key: key);

  @override
  _NewCouponState createState() => _NewCouponState();
}

class _NewCouponState extends State<NewCoupon> {
  File? _image;
  String? _selectedPercentage;
  DateTime? _selectedDate;
  String? _selectedBeaconId;
  final _descriptionController = TextEditingController();
  final BleController _bleController = Get.put(BleController());
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeBle();
  }

  Future<void> _initializeBle() async {
    await _bleController.initNotifications();
  }

  // Method to ensure we have proper authentication data
  Future<bool> _ensureAuthenticationData() async {
    // Check if we have the essential data
    if (widget.usernameData.userId != null &&
        widget.usernameData.userId!.isNotEmpty &&
        widget.usernameData.authToken != null &&
        widget.usernameData.authToken!.isNotEmpty) {
      print('✅ Authentication data is already present');
      return true;
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
        widget.usernameData.authToken = savedToken;
        widget.usernameData.userId = savedUserId;
        widget.usernameData.email = savedEmail ?? widget.usernameData.email;
        widget.usernameData.userRole = savedRole ?? widget.usernameData.userRole;

        print('✅ Authentication data restored from SharedPreferences');
        print('✅ User ID: ${widget.usernameData.userId}');
        print('✅ Auth Token: Present');
        return true;
      }
    } catch (e) {
      print('❌ Error restoring authentication data: $e');
    }

    print('❌ Could not restore authentication data');
    return false;
  }

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

  Future<void> _startBeaconScan() async {
    setState(() {
      _isScanning = true;
      _selectedBeaconId = null;
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
                                content: Text('Beacon device selected successfully'),
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

  Future<void> _publishCoupon() async {
    // ✅ NEW: Ensure we have proper authentication data
    bool hasAuthData = await _ensureAuthenticationData();
    if (!hasAuthData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // More comprehensive validation
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_selectedPercentage == null || _selectedPercentage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a percentage')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    if (_selectedBeaconId == null || _selectedBeaconId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a beacon device')),
      );
      return;
    }

    // ✅ UPDATED: More robust user ID check
    if (widget.usernameData.userId == null || widget.usernameData.userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please login again.')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(couponURL),
      );

      // ✅ UPDATED: Add proper headers including authentication
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        if (widget.usernameData.authToken != null && widget.usernameData.authToken!.isNotEmpty)
          'Authorization': 'Bearer ${widget.usernameData.authToken!}',
      });

      // ✅ UPDATED: Debug print the data being sent
      print('📤 Publishing coupon with data:');
      print('User ID: ${widget.usernameData.userId}');
      print('Description: ${_descriptionController.text.trim()}');
      print('Percentage: $_selectedPercentage');
      print('Expiry Date: ${_selectedDate!.toIso8601String()}');
      print('Beacon ID: $_selectedBeaconId');
      print('Auth Token: ${widget.usernameData.authToken != null ? "Present" : "Missing"}');

      // Safely add fields with null checks
      request.fields['merchant_id'] = widget.usernameData.userId!;
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['percentage'] = _selectedPercentage!;
      request.fields['expiry_date'] = _selectedDate!.toIso8601String();
      request.fields['beacon_id'] = _selectedBeaconId!;

      // Add image file
      try {
        request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
        print('✅ Image file added successfully');
      } catch (e) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading image file: ${e.toString()}')),
        );
        return;
      }

      print('📤 Sending coupon request to: $couponURL');
      print('📤 Request fields: ${request.fields}');
      print('📤 Request headers: ${request.headers}');

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseString');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon published successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to coupon list
        if (Navigator.canPop(context)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CouponListPage(usernameData: widget.usernameData)),
          );
        }
      } else if (response.statusCode == 401) {
        // ✅ NEW: Handle authentication errors specifically
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 422) {
        // ✅ NEW: Handle validation errors
        String errorMessage = 'Validation error occurred';
        try {
          final responseData = json.decode(responseString);
          if (responseData['errors'] != null) {
            // Extract validation errors
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
        String errorMessage = 'Failed to publish coupon';

        // Try to parse error message from response
        try {
          final responseData = json.decode(responseString);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          // Use default error message with status code
          errorMessage = 'Failed to publish coupon (Error: ${response.statusCode})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ Error publishing coupon: $e'); // For debugging

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('New Coupon'),
        centerTitle: true,
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

            // ✅ NEW: Debug info panel (remove in production)
            if (widget.usernameData.userId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Status:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text('User ID: ${widget.usernameData.userId}', style: TextStyle(fontSize: 10)),
                    Text('Auth Token: ${widget.usernameData.authToken != null ? "Present" : "Missing"}', style: TextStyle(fontSize: 10)),
                    Text('Email: ${widget.usernameData.email ?? "Not set"}', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
              maxLines: 3,
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
            // Beacon Selection Section
            Container(
              width: double.infinity,
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedBeaconId != null
                              ? 'Beacon: ${_selectedBeaconId!.substring(0, 8)}...'
                              : 'Select Beacon Device',
                          style: TextStyle(
                            color: _selectedBeaconId != null ? Colors.black : Colors.black54,
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        _selectedBeaconId!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                label: Text(_isScanning ? 'Scanning...' : 'Scan for Beacons'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _publishCoupon,
                style: _buttonStyle(),
                child: const Text(
                  'Publish Coupon',
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

  // Common styling for box elements
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}