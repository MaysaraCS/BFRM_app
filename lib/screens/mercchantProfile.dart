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

  int _currentIndex = 4;           // page index in bottom‑bar

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  /* --------------------------------------------------------------------------
   *  API – get profile
   * ----------------------------------------------------------------------- */
  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _goToWelcome();        // token missing
      return;
    }

    final res = await http.get(
      Uri.parse(ProfileURL),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final responseData = json.decode(res.body);
      Login usernameData = Login.fromJson(responseData);

      setState(() {
        _restaurantCtrl.text = usernameData.restaurantName ?? '';
        _emailCtrl.text = usernameData.email ?? '';
        _phoneCtrl.text = usernameData.restaurantContact ?? '';
        _locationCtrl.text = usernameData.restaurantLocation ?? '';
        _logoUrl = usernameData.restaurantLogo;
        _loading = false;
      });
    } else {
      _showSnack('Failed to load profile');
      setState(() => _loading = false);
    }

  }

  /* --------------------------------------------------------------------------
   *  choose new logo
   * ----------------------------------------------------------------------- */
  Future<void> _pickLogo() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _logoFile = File(picked.path));
  }

  /* --------------------------------------------------------------------------
   *  PUT /profile   – send multipart when logo changed, JSON otherwise
   * ----------------------------------------------------------------------- */
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return _goToWelcome();

    http.Response res;

    if (_logoFile != null) {
      final req = http.MultipartRequest('PUT', Uri.parse(ProfileURL))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['restaurant_name'] = _restaurantCtrl.text
        ..fields['phone_number']    = _phoneCtrl.text
        ..fields['location']        = _locationCtrl.text
        ..fields['email']           = _emailCtrl.text
        ..files.add(
          await http.MultipartFile.fromPath('logo', _logoFile!.path),
        );

      final streamed = await req.send();
      res = await http.Response.fromStream(streamed);
    } else {
      res = await http.put(
        Uri.parse(ProfileURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'restaurant_name': _restaurantCtrl.text,
          'phone_number'   : _phoneCtrl.text,
          'location'       : _locationCtrl.text,
          'email'          : _emailCtrl.text,
        }),
      );
    }

    if (res.statusCode == 200) {
      _showSnack('Profile updated');
      _fetchProfile();      // refresh UI
    } else {
      _showSnack('Update failed');
    }
  }

  /* --------------------------------------------------------------------------
   *  POST /logout
   * ----------------------------------------------------------------------- */
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return _goToWelcome();

    await http.post(Uri.parse(logoutURL),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

    await prefs.remove('token');
    _goToWelcome();
  }

  void _goToWelcome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  WelcomePage()),
          (_) => false,
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /* --------------------------------------------------------------------------
   *  UI
   * ----------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final logoWidget = _logoFile != null
        ? Image.file(_logoFile!, height: 100, width: 100, fit: BoxFit.cover)
        : (_logoUrl != null && _logoUrl!.isNotEmpty)
        ? Image.network(
      'http://192.168.0.197:8080/storage/$_logoUrl',
      height: 100,
      width: 100,
      fit: BoxFit.cover,
    )
        : const Icon(Icons.person, size: 80, color: Colors.blue);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('lib/assets/logo.png', height: 60),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickLogo,
                  child: CircleAvatar(radius: 55, backgroundColor: Colors.grey[200], child: ClipOval(child: logoWidget)),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(onPressed: _saveProfile, child: const Text('Edit')),
                ),
                const SizedBox(height: 10),
                _buildField(_restaurantCtrl, 'Restaurant name'),
                const SizedBox(height: 10),
                _buildField(_emailCtrl, 'Type your email address', email: true),
                const SizedBox(height: 10),
                _buildField(_phoneCtrl, 'Phone number'),
                const SizedBox(height: 10),
                _buildField(_locationCtrl, 'Restaurant address'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordRecoveryPage())),
                    child: const Text('Change Password', style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == _currentIndex) return;
          final pages = [
            //const Merchanthomepage(usernameData: usernameData),
            const Report(),
            const Camera(),
             CouponListPage(),
            const MerchantProfile(),
          ];
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pages[index]));
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

  Widget _buildField(TextEditingController ctrl, String label, {bool email = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  @override
  void dispose() {
    _restaurantCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }
}
