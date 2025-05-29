import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/favList.dart';
import 'package:bfrm_app_flutter/screens/customerCoupon.dart';
import 'package:bfrm_app_flutter/screens/customerProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/ble_controller.dart';

class Customerhomepage extends StatefulWidget {
  const Customerhomepage({super.key});

  @override
  State<Customerhomepage> createState() => _CustomerhomepageState();
}

class _CustomerhomepageState extends State<Customerhomepage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  List<dynamic> _discounts = [];
  bool _isLoading = false;
  String? _authToken;

  // Get the BleController instance
  final BleController _bleController = Get.put(BleController());

  // Colors for discount cards (same as merchant homepage)
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
    WidgetsBinding.instance.addObserver(this);
    _loadToken();
    _initializeAndStartScan();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bleController.startScan();
      _fetchDiscounts();
    }
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('token');
    });
    print('Auth token loaded: ${_authToken != null ? "Present" : "Missing"}');
  }

  Future<void> _initializeAndStartScan() async {
    await _bleController.initNotifications();
    await _bleController.startScan();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the browse endpoint for customers
      final browseUrl = '$discountURL/browse';
      print('🔍 Fetching discounts from: $browseUrl');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add auth token if available
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
        print('✅ Added auth header');
      } else {
        print('⚠️ No auth token available');
      }

      final response = await http.get(
        Uri.parse(browseUrl),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          // Handle Laravel response format
          if (responseData is Map && responseData.containsKey('data')) {
            _discounts = responseData['data'] ?? [];
          } else if (responseData is List) {
            _discounts = responseData;
          } else {
            _discounts = [];
          }
        });

        print('✅ Successfully loaded ${_discounts.length} discounts');

        // Show result message
        if (_discounts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No discounts available'),
              backgroundColor: Colors.orange,
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
        print('❌ Failed to load discounts: ${response.statusCode}');

        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to load discounts';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load discounts: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('❌ Network error fetching discounts: $e');

      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter discounts based on nearby beacon devices
  List<dynamic> get _nearbyDiscounts {
    if (_discounts.isEmpty) return [];

    return _discounts.where((discount) {
      return _bleController.scannedBeaconIds.contains(discount['beacon_id']);
    }).toList();
  }

  Future<void> _addToFavorites(int discountId) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(favoriteURL),
        body: json.encode({'discount_id': discountId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      print('Favorite Response Status: ${response.statusCode}');
      print('Favorite Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to add to favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMerchantName(Map<String, dynamic>? merchant) {
    if (merchant == null) return 'Restaurant';

    // Try different possible field names for restaurant name
    // Based on your Laravel User model, it could be stored in various ways
    String? name = merchant['restaurant_name'] ??
        merchant['restaurantName'] ??
        merchant['business_name'] ??
        merchant['businessName'] ??
        merchant['name'] ??
        merchant['email']?.split('@')[0]; // Fallback to email username

    // Debug print to see what's actually in the merchant data
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
    if (index == _currentIndex && index == 0) return;

    Widget destination;
    switch (index) {
      case 0:
        return;
      case 1:
        destination = const Favlist();
        break;
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
        _currentIndex = 0;
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
              'Discover Deals',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Near You',
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
            onPressed: () {
              _bleController.startScan();
              _fetchDiscounts();
            },
          ),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async {
            _bleController.startScan();
            await _fetchDiscounts();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Banner
                if (_bleController.showNotificationBanner.value)
                  GestureDetector(
                    onTap: () {
                      _bleController.resetNotificationBanner();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CustomerCouponPage()),
                      );
                    },
                    child: Container(
                      color: Colors.yellow[100],
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'New coupon available! Tap to view.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),

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



                // Available Discounts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Discounts',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_nearbyDiscounts.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.bluetooth,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_nearbyDiscounts.length} nearby',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Discounts Display
                if (_isLoading)
                  Container(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_nearbyDiscounts.isEmpty)
                  Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _bleController.scannedBeaconIds.isEmpty
                                ? Icons.bluetooth_disabled
                                : Icons.store_mall_directory_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _bleController.scannedBeaconIds.isEmpty
                                ? 'No nearby stores detected'
                                : 'No discounts available nearby',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _bleController.scannedBeaconIds.isEmpty
                                ? 'Move closer to participating stores\nto discover amazing deals'
                                : 'Check back later for new deals\nfrom nearby merchants',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _bleController.startScan();
                              _fetchDiscounts();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Scan Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
                      itemCount: _nearbyDiscounts.length,
                      itemBuilder: (context, index) {
                        final discount = _nearbyDiscounts[index];
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
                                      onTap: () => _addToFavorites(discount['id']),
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
                                    SizedBox(width: 6),
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
                                  ],
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
        );
      }),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}