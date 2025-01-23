import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/favList.dart';
import 'package:bfrm_app_flutter/screens/customerCoupon.dart';
import 'package:bfrm_app_flutter/screens/customerProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Add this import to handle JSON decoding

import '../constant.dart';

class Customerhomepage extends StatefulWidget {
  const Customerhomepage({super.key});

  @override
  State<Customerhomepage> createState() => _CustomerhomepageState();
}

class _CustomerhomepageState extends State<Customerhomepage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Customerhomepage(),
    const Favlist(),
    CustomerCouponPage(),
    const Customerprofile(),
  ];

  String? _token;
  List<dynamic> _discounts = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _fetchDiscounts();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _fetchDiscounts() async {
    final response = await http.get(Uri.parse('$discountURL'));
    if (response.statusCode == 200) {
      setState(() {
        _discounts = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load discounts')),
      );
    }
  }

  Future<void> _addToFavorites(int discountId) async {
    // Ensure the token is loaded
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    // Send the request with the token in headers
    final response = await http.post(
      Uri.parse('$favoriteURL'),
      body: json.encode({'discount_id': discountId}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token', // Pass the token in the Authorization header
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201 && responseData['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'] ?? 'Added to favorite list')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to favorite list')),
      );
    }
  }

  void _shareDiscount(String photo, String description) {
    Share.share('Check out this discount: $description\nPhoto: $photo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Customer Home',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _discounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _discounts.length,
        itemBuilder: (context, index) {
          final discount = _discounts[index];
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(discount['photo']),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    discount['description'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _addToFavorites(discount['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      onPressed: () =>
                          _shareDiscount(discount['photo'], discount['description']),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => _pages[index]),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: "Coupon",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
      // Add the logo here
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'lib/assets/logo.png', // Replace with the correct path to your logo.png
                height: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
