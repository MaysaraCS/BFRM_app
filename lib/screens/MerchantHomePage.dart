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
import '../model/Login.dart';

import '../constant.dart';

class Merchanthomepage extends StatefulWidget {
  final Login? usernameData;

  const Merchanthomepage({super.key, this.usernameData});

  @override
  State<Merchanthomepage> createState() => _MerchanthomepageState();
}

class _MerchanthomepageState extends State<Merchanthomepage> {
  int _currentIndex = 0;
  List<dynamic> _discounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading discounts')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDiscount(int id) async {
    try {
      final response = await http.delete(
          Uri.parse('http://192.168.0.197:8080/api/discounts/$id')
      );
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting discount')),
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

  void _navigateToPage(int index) {
    if (index == _currentIndex && index == 0) return; // Don't navigate if already on home page

    Widget destination;
    switch (index) {
      case 0:
        return; // Already on home page
      case 1:
      // Report page without usernameData
        destination = Report();
        break;
      case 2:
      // Camera page without usernameData
        destination = Camera();
        break;
      case 3:
      // Pass usernameData to CouponListPage
        destination = CouponListPage(usernameData: widget.usernameData);
        break;
      case 4:
      // MerchantProfile page without usernameData
        destination = MerchantProfile();
        break;
      default:
        return;
    }

    // Use Navigator.push instead of pushReplacement to maintain navigation stack
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ).then((_) {
      // Reset the current index to home when returning
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Welcome${widget.usernameData?.username != null ? ', ${widget.usernameData!.username}' : ''}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
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
                    color: Colors.grey[200],
                    child: const Icon(Icons.business, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (widget.usernameData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewCoupon(usernameData: widget.usernameData!),
                        ),
                      ).then((_) {
                        // Refresh data when returning from NewCoupon
                        _fetchDiscounts();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please login first')),
                      );
                    }
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
                    ).then((_) {
                      // Refresh discounts when returning from NewDiscount
                      _fetchDiscounts();
                    });
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

            // Show loading or discounts
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_discounts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No discounts available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          child: Image.network(
                            discount['photo'], // Full photo URL
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            discount['description'] ?? 'No description',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Food Type: ${discount['food_type'] ?? 'N/A'}',
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToPage(index);
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