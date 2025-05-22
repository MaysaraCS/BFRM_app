import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/newCoupon.dart';
import 'package:bfrm_app_flutter/screens/newDiscount.dart';
import 'package:bfrm_app_flutter/screens/editDiscount.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mercchantProfile.dart';
import 'camera.dart';
import 'report.dart';
import 'couponList.dart';

import '../constant.dart';

class Merchanthomepage extends StatefulWidget {
  const Merchanthomepage({super.key});

  @override
  State<Merchanthomepage> createState() => _MerchanthomepageState();
}

class _MerchanthomepageState extends State<Merchanthomepage> {
  int _currentIndex = 0; // Set the default index to
  List<dynamic> _discounts = [];

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    final response = await http.get(Uri.parse(discountURL));
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

  Future<void> _deleteDiscount(int id) async {
    final response = await http.delete(Uri.parse('http://192.168.0.197:8080/api/discounts/$id'));
    if (response.statusCode == 200) {
      setState(() {
        _discounts.removeWhere((discount) => discount['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete discount')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount'),
        content: const Text('Are you sure you want to delete this discount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDiscount(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  final List<Widget> _pages = [
    Merchanthomepage(),
    Report(),
    Camera(),
    CouponListPage(),
    MerchantProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'lib/assets/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewCoupon()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("New Coupon"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewDiscount()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("New Discount"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _discounts.isEmpty
                ? const Center(child: Text('No discounts available'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _discounts.length,
              itemBuilder: (context, index) {
                final discount = _discounts[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        //'http://192.168.8.112:8080/storage/${discount['photo']}',
                        discount['photo'], // Full photo URL
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          discount['description'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Food Type: ${discount['food_type']}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditDiscount(discount: discount),
                                ),
                              );
                              if (result == true) {
                                _fetchDiscounts(); // Refresh discounts after editing
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(discount['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
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
            icon: Icon(Icons.report),
            label: "Report",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera",
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
    );
  }
}
