// merchant_profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../constant.dart';
import '../model/Login.dart';
import 'MerchantHomePage.dart';
import 'report.dart';
import 'camera.dart';
import 'couponList.dart';
import 'Password_Recovery.dart';
import 'welcome_page.dart';

class MerchantProfile extends StatefulWidget {
  const MerchantProfile({Key? key}) : super(key: key);

  @override
  State<MerchantProfile> createState() => _MerchantProfileState();
}

class _MerchantProfileState extends State<MerchantProfile> {
  final _formKey = GlobalKey<FormState>();

  final _restaurantCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  File? _logoFile;                 // new chosen image
  String? _logoUrl;                // current url from backend
  bool _loading = true;
  bool _isEditing = false;         // edit mode state
  bool _isSaving = false;          // saving state
  bool _hasChanges = false;        // track if user made changes

  int _currentIndex = 4;           // page index in bottom‑bar

  // Store original values to detect changes
  String _originalRestaurant = '';
  String _originalPhone = '';
  String _originalLocation = '';
  String? _originalLogoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();

    // Add listeners to detect changes
    _restaurantCtrl.addListener(_detectChanges);
    _phoneCtrl.addListener(_detectChanges);
    _locationCtrl.addListener(_detectChanges);
  }

  void _detectChanges() {
    setState(() {
      _hasChanges = _restaurantCtrl.text != _originalRestaurant ||
          _phoneCtrl.text != _originalPhone ||
          _locationCtrl.text != _originalLocation ||
          _logoFile != null;
    });
  }

  /* --------------------------------------------------------------------------
   *  API – get profile
   * ----------------------------------------------------------------------- */
  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _goToWelcome();        // token missing
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(ProfileURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);

        setState(() {
          _restaurantCtrl.text = responseData['restaurant_name'] ?? '';
          _emailCtrl.text = responseData['email'] ?? '';
          _phoneCtrl.text = responseData['phone_number'] ?? '';
          _locationCtrl.text = responseData['location'] ?? '';
          _logoUrl = responseData['logo'];

          // Store original values
          _originalRestaurant = _restaurantCtrl.text;
          _originalPhone = _phoneCtrl.text;
          _originalLocation = _locationCtrl.text;
          _originalLogoUrl = _logoUrl;

          _loading = false;
          _hasChanges = false;
        });
      } else if (res.statusCode == 401) {
        _goToWelcome(); // token expired
      } else {
        _showSnack('Failed to load profile: ${res.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e) {
      _showSnack('Network error: ${e.toString()}');
      setState(() => _loading = false);
    }
  }

  /* --------------------------------------------------------------------------
   *  choose new logo
   * ----------------------------------------------------------------------- */
  Future<void> _pickLogo() async {
    if (!_isEditing) {
      _showSnack('Please click Edit to change your logo');
      return;
    }

    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _logoFile = File(picked.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showSnack('Failed to pick image: ${e.toString()}');
    }
  }

  /* --------------------------------------------------------------------------
   *  Toggle edit mode
   * ----------------------------------------------------------------------- */
  void _toggleEditMode() {
    if (_isEditing && _hasChanges) {
      // Show confirmation dialog when canceling with unsaved changes
      _showCancelConfirmationDialog();
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          // Reset changes when canceling edit
          _resetChanges();
        }
      });
    }
  }

  void _resetChanges() {
    setState(() {
      _restaurantCtrl.text = _originalRestaurant;
      _phoneCtrl.text = _originalPhone;
      _locationCtrl.text = _originalLocation;
      _logoFile = null;
      _hasChanges = false;
    });
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isEditing = false;
                  _resetChanges();
                });
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /* --------------------------------------------------------------------------
   *  PUT /profile   – send multipart when logo changed, JSON otherwise
   * ----------------------------------------------------------------------- */
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      _showSnack('No changes to save');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return _goToWelcome();

    setState(() => _isSaving = true);

    try {
      http.Response res;

      if (_logoFile != null) {
        // Multipart request for logo upload
        final req = http.MultipartRequest('PUT', Uri.parse(ProfileURL))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['restaurant_name'] = _restaurantCtrl.text.trim()
          ..fields['phone_number'] = _phoneCtrl.text.trim()
          ..fields['location'] = _locationCtrl.text.trim();

        // Add logo file
        req.files.add(
          await http.MultipartFile.fromPath('logo', _logoFile!.path),
        );

        final streamed = await req.send();
        res = await http.Response.fromStream(streamed);
      } else {
        // JSON request for text fields only
        res = await http.put(
          Uri.parse(ProfileURL),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          body: json.encode({
            'restaurant_name': _restaurantCtrl.text.trim(),
            'phone_number': _phoneCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
          }),
        );
      }

      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);

        setState(() {
          _isEditing = false;
          _logoFile = null;
          _hasChanges = false;

          // Update original values
          _originalRestaurant = _restaurantCtrl.text;
          _originalPhone = _phoneCtrl.text;
          _originalLocation = _locationCtrl.text;

          // Update logo URL if it was changed
          if (responseData['data'] != null && responseData['data']['logo'] != null) {
            _logoUrl = responseData['data']['logo'];
            _originalLogoUrl = _logoUrl;
          }
        });

        _showSnack('Profile updated successfully', Colors.green);
      } else {
        final errorData = json.decode(res.body);
        String errorMessage = 'Update failed';

        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        } else if (errorData['messages'] != null) {
          errorMessage = errorData['messages'].toString();
        }

        _showSnack(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnack('Network error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /* --------------------------------------------------------------------------
   *  POST /logout
   * ----------------------------------------------------------------------- */
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return _goToWelcome();

    try {
      await http.post(
          Uri.parse(logoutURL),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          }
      );
    } catch (e) {
      // Even if logout request fails, we should still clear local storage
      print('Logout request failed: $e');
    }

    await prefs.remove('token');
    _goToWelcome();
  }

  void _goToWelcome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => WelcomePage()),
          (_) => false,
    );
  }

  void _showSnack(String msg, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: Duration(seconds: color == Colors.green ? 2 : 3),
        )
    );
  }

  /* --------------------------------------------------------------------------
   *  UI
   * ----------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final logoWidget = _logoFile != null
        ? Image.file(_logoFile!, height: 100, width: 100, fit: BoxFit.cover)
        : (_logoUrl != null && _logoUrl!.isNotEmpty && _logoUrl != 'N/A')
        ? Image.network(
      'http://192.168.0.197:8080/storage/$_logoUrl',
      height: 100,
      width: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.restaurant, size: 80, color: Colors.blue);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 100,
          width: 100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    )
        : const Icon(Icons.restaurant, size: 80, color: Colors.blue);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _isSaving ? null : _toggleEditMode,
              icon: Icon(Icons.close, color: Colors.red),
              label: Text('Cancel', style: TextStyle(color: Colors.red)),
            )
          else
            TextButton.icon(
              onPressed: _toggleEditMode,
              icon: Icon(Icons.edit, color: Colors.blue),
              label: Text('Edit', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo section
                const SizedBox(height: 20),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(child: logoWidget),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (_logoFile != null && _isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'New logo selected',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 30),

                // Form fields
                _buildField(
                  _restaurantCtrl,
                  'Restaurant Name',
                  icon: Icons.restaurant,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),

                _buildField(
                  _emailCtrl,
                  'Email Address',
                  icon: Icons.email,
                  enabled: false, // Email is never editable
                  email: true,
                ),
                const SizedBox(height: 16),

                _buildField(
                  _phoneCtrl,
                  'Phone Number',
                  icon: Icons.phone,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),

                _buildField(
                  _locationCtrl,
                  'Restaurant Address',
                  icon: Icons.location_on,
                  enabled: _isEditing,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Change Password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PasswordRecoveryPage())
                    ),
                    icon: Icon(Icons.lock, size: 16),
                    label: const Text('Change Password'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                ),

                const SizedBox(height: 30),

                // Save button (only show when editing and has changes)
                if (_isEditing && _hasChanges)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                      child: _isSaving
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
                          Text('Saving...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                          : Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                const SizedBox(height: 20),

                // Logout button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                    child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == _currentIndex) return;

          // Check if user has unsaved changes before navigating
          if (_isEditing && _hasChanges) {
            _showNavigationConfirmationDialog(index);
          } else {
            _navigateToPage(index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.discount), label: 'Coupon'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showNavigationConfirmationDialog(int targetIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isEditing = false;
                  _resetChanges();
                });
                _navigateToPage(targetIndex);
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _saveProfile();
                if (!_hasChanges) { // Only navigate if save was successful
                  _navigateToPage(targetIndex);
                }
              },
              child: const Text('Save & Continue'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(int index) {
    Widget destination;
    switch (index) {
      case 0:
      // Need to pass usernameData to MerchantHomePage
      // You might need to store this data differently
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Merchanthomepage()));
        return;
      case 1:
        destination = Report();
        break;
      case 2:
        destination = Camera();
        break;
      case 3:
        destination = CouponListPage();
        break;
      case 4:
        return; // Already on profile page
      default:
        return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  Widget _buildField(
      TextEditingController ctrl,
      String label, {
        bool email = false,
        bool enabled = true,
        IconData? icon,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey[600],
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: enabled ? Colors.blue : Colors.grey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: enabled ? Colors.grey[700] : Colors.grey[500],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _restaurantCtrl.removeListener(_detectChanges);
    _phoneCtrl.removeListener(_detectChanges);
    _locationCtrl.removeListener(_detectChanges);

    _restaurantCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }
}