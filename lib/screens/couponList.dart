import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constant.dart';
import 'MerchantHomePage.dart';
import 'newCoupon.dart';
import 'newDiscount.dart';
import 'mercchantProfile.dart';
import 'camera.dart';
import 'report.dart';

class CouponListPage extends StatefulWidget {
  @override
  _CouponListPageState createState() => _CouponListPageState();
}

class _CouponListPageState extends State<CouponListPage> {
  List<dynamic> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final response = await http.get(Uri.parse(couponURL));
      if (response.statusCode == 200) {
        setState(() {
          _coupons = json.decode(response.body);
          // Sort coupons by recency (assuming 'created_at' is a timestamp field)
          _coupons.sort((a, b) => b['created_at'].compareTo(a['created_at']));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch coupons')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while fetching coupons')),
      );
    }
  }

  Future<void> _deleteCoupon(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.0.197:8080/api/coupons/$id'),
        headers: {'Content-Type': 'application/json'}, // Add headers if needed
      );
      if (response.statusCode == 200) {
        setState(() {
          _coupons.removeWhere((coupon) => coupon['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete coupon')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while deleting coupon')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Coupon'),
          content: Text('Are you sure you want to delete this coupon?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCoupon(id);
              },
            ),
          ],
        );
      },
    );
  }

  int _currentIndex = 3; // Set the default index to CouponListPage

  final List<Widget> _pages = [
    Merchanthomepage(),
    Report(),
    Camera(),
    CouponListPage(),
    Mercchantprofile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return Card(
                  margin: EdgeInsets.all(12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Image.network(
                            'http://192.168.0.197:8080/storage/${coupon['photo']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 100, color: Colors.grey);
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${coupon['percentage']}% off',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                coupon['description'],
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmationDialog(coupon['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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