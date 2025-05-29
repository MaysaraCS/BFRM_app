import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isLoading = false;
  int _currentIndex = 1;
  String? _authToken;

  // Colors for favorite cards (same as customer homepage)
  final List<List<Color>> _cardGradients = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E8E)], // Red gradient
    [Color(0xFF4ECDC4), Color(0xFF7BDDD8)], // Teal gradient
    [Color(0xFF45B7D1), Color(0xFF68C5E8)], // Blue gradient
    [Color(0xFFFA8072), Color(0xFFFFB07C)], // Orange gradient
    [Color(0xFF98D8C8), Color(0xFFB8E6D3)], // Green gradient
    [Color(0xFFDDA0DD), Color(0xFFE6B3E6)], // Purple gradient
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('token');
    });
    print('Auth token loaded: ${_authToken != null ? "Present" : "Missing"}');

    if (_authToken != null) {
      _fetchFavorites();
    }
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Fetching favorites from: $favoriteURL');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
        print('✅ Added auth header');
      } else {
        print('⚠️ No auth token available');
      }

      final response = await http.get(
        Uri.parse(favoriteURL),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          // Handle Laravel response format from FavoriteController
          if (responseData is Map && responseData.containsKey('data')) {
            _favorites = responseData['data'] ?? [];
          } else if (responseData is Map && responseData.containsKey('favorites')) {
            // Fallback for old response structure
            _favorites = responseData['favorites'] ?? [];
          } else if (responseData is List) {
            _favorites = responseData;
          } else {
            _favorites = [];
          }
        });

        print('✅ Successfully loaded ${_favorites.length} favorites');

        if (_favorites.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No favorites added yet'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${_favorites.length} favorites'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } else if (response.statusCode == 401) {
        print('❌ Authentication failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 403) {
        print('❌ Access forbidden');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Customer account required.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('❌ Failed to load favorites: ${response.statusCode}');

        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to load favorites';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load favorites: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('❌ Network error fetching favorites: $e');

      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
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

  Future<void> _deleteFavorite(int favoriteId) async {
    try {
      print('🗑️ Deleting favorite ID: $favoriteId');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await http.delete(
        Uri.parse('$favoriteURL/$favoriteId'),
        headers: headers,
      );

      print('📥 Delete response status: ${response.statusCode}');
      print('📥 Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          setState(() {
            _favorites.removeWhere((item) => item['id'] == favoriteId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Removed from favorites'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to remove from favorites'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to remove from favorites';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove from favorites: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error deleting favorite: $e');

      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int favoriteId, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Favorite'),
          content: Text('Remove "$description" from your favorites?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
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

  String _getMerchantName(Map<String, dynamic>? merchant) {
    if (merchant == null) return 'Restaurant';

    // Try different possible field names for restaurant name
    String? name = merchant['restaurant_name'] ??
        merchant['restaurantName'] ??
        merchant['business_name'] ??
        merchant['businessName'] ??
        merchant['name'] ??
        merchant['email']?.split('@')[0];

    print('🏪 Merchant data: $merchant');
    print('🏪 Extracted name: $name');

    return name ?? 'Restaurant';
  }

  void _shareDiscount(Map<String, dynamic> discount) {
    final description = discount['description'] ?? 'Amazing discount available!';
    final foodType = discount['food_type'] ?? 'Food';
    final merchantName = _getMerchantName(discount['merchant']);

    final shareText = '''
🎉 Check out this amazing discount! 

🍽️ $foodType at $merchantName
📝 $description

Download our app to discover more deals nearby!
    ''';

    Share.share(shareText);
  }

  String _getImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';

    if (photoPath.startsWith('http')) {
      return photoPath;
    }

    // Construct proper storage URL
    return 'http://192.168.0.197:8080/storage/$photoPath';
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex && index == 1) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const Customerhomepage();
        break;
      case 1:
        return;
      case 2:
        destination = CustomerCouponPage();
        break;
      case 3:
        destination = const Customerprofile();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ).then((_) {
      setState(() {
        _currentIndex = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Favorites',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_favorites.isNotEmpty)
              Text(
                '${_favorites.length} saved deals',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchFavorites,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFavorites,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo Section
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, size: 30),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Favorites Section Header
              if (!_isLoading && _favorites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Discounts',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_favorites.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isLoading && _favorites.isNotEmpty) const SizedBox(height: 15),

              // Favorites Display
              if (_isLoading)
                Container(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_favorites.isEmpty)
                Container(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start exploring deals and save\nyour favorites here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Customerhomepage()),
                            );
                          },
                          icon: Icon(Icons.explore),
                          label: Text('Discover Deals'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = _favorites[index];
                      final discount = favorite['discount']; // Access discount from favorite
                      final gradientColors = _cardGradients[index % _cardGradients.length];

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Food Type Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      discount['food_type'] ?? 'Food',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: gradientColors[0],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Discount Image
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _getImageUrl(discount['photo']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.fastfood,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Description
                                  Text(
                                    discount['description'] ?? 'Delicious Food Discount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 8),

                                  // Merchant Info
                                  if (discount['merchant'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.store,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _getMerchantName(discount['merchant']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Action Buttons
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _shareDiscount(discount),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.share,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _showDeleteConfirmationDialog(
                                        favorite['id'],
                                        discount['description'] ?? 'this discount'
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.favorite,
                                        size: 16,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Favorite Badge
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Saved',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 30),
            ],
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
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: "Coupons",
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