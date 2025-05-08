import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../constant.dart';
import 'CustomerHomePage.dart';
import 'customerCoupon.dart';
import 'customerProfile.dart';

class Favlist extends StatefulWidget {
  const Favlist({Key? key}) : super(key: key);

  @override
  State<Favlist> createState() => _FavlistState();
}

class _FavlistState extends State<Favlist> {
  List<dynamic> _favorites = [];
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const Customerhomepage(),
    const Favlist(),
    CustomerCouponPage(),
    const Customerprofile(),
  ];

  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    // Load the token from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    if (_token != null) {
      _fetchFavorites();
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse(favoriteURL),
        headers: {
          'Authorization': 'Bearer $_token', // Pass the token in the headers
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            _favorites = responseData['favorites'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load favorites')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while fetching favorites')),
      );
    }
  }

  Future<void> _deleteFavorite(int favoriteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$favoriteURL/$favoriteId'),
        headers: {
          'Authorization': 'Bearer $_token', // Pass the token in the headers
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            _favorites.removeWhere((item) => item['id'] == favoriteId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorite list')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove from favorite list')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from favorite list')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while removing favorite')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int favoriteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Favorite'),
          content: const Text('Are you sure you want to delete this favorite?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFavorite(favoriteId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        flexibleSpace: Center(
          child: Image.asset(
            'lib/assets/logo.png',
            height: 80,
          ),
        ),
      ),
      body: _favorites.isEmpty
          ? const Center(child: Text('No favorites added yet'))
          : ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          final discount = favorite['discount']; // Access discount details
          return Card(
            margin: const EdgeInsets.all(12.0),
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
                      'http://192.168.0.197:8080/storage/${discount['photo']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount['description'] ?? 'No description',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Food Type: ${discount['food_type']}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(favorite['id']),
                  ),
                ],
              ),
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
    );
  }
}