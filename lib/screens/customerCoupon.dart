import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bfrm_app_flutter/screens/redeemCoupon.dart';
import 'package:bfrm_app_flutter/controllers/ble_controller.dart';

import '../constant.dart';

class CustomerCouponPage extends StatefulWidget {
  @override
  _CustomerCouponPageState createState() => _CustomerCouponPageState();
}

class _CustomerCouponPageState extends State<CustomerCouponPage> with WidgetsBindingObserver {
  List<dynamic> _coupons = [];
  String? _selectedPercentageFilter;
  String? _authToken;
  final BleController _bleController = Get.put(BleController());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAuthToken();
    _initializeAndStartScan();
  }

  Future<void> _loadAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('token');
    });
    print('Auth token loaded: ${_authToken != null ? "Present" : "Missing"}');
  }

  Future<void> _initializeAndStartScan() async {
    await _bleController.initNotifications();
    await _bleController.startScan();
    _fetchCoupons();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bleController.startScan();
      _fetchCoupons();
    }
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Make sure your constant.dart has the correct URL
      // couponURL should be something like: 'http://192.168.0.197:8080/api/coupons'
      final browseUrl = '$couponURL/browse';
      print('Fetching from: $browseUrl');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add auth token if available
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
        print('Added auth header with token: ${_authToken!.substring(0, 10)}...');
      } else {
        print('WARNING: No auth token available');
      }

      print('Headers: $headers');

      final response = await http.get(
        Uri.parse(browseUrl),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          // Handle Laravel response format
          if (responseData is Map && responseData.containsKey('data')) {
            _coupons = responseData['data'] ?? [];
          } else if (responseData is List) {
            _coupons = responseData;
          } else {
            _coupons = [];
          }
          _isLoading = false;
        });

        print('Successfully loaded ${_coupons.length} coupons');
      } else if (response.statusCode == 401) {
        print('Authentication failed - token may be invalid or expired');
        // Handle token refresh or redirect to login
        setState(() {
          _isLoading = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed. Please login again.')),
        );
      } else if (response.statusCode == 403) {
        print('Access forbidden - user may not have customer role');
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access denied. Customer account required.')),
        );
      } else {
        print('Failed to load coupons: ${response.statusCode}');
        print('Error response: ${response.body}');
        setState(() {
          _isLoading = false;
        });

        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to load coupons';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load coupons: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Network error fetching coupons: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: Please check your connection')),
      );
    }
  }

  List<dynamic> get _filteredCoupons {
    final nearbyBeaconCoupons = _coupons.where((coupon) {
      return _bleController.scannedBeaconIds.contains(coupon['beacon_id']);
    }).toList();

    if (_selectedPercentageFilter == null) {
      return nearbyBeaconCoupons;
    } else {
      return nearbyBeaconCoupons.where((coupon) {
        return coupon['percentage'].toString() == _selectedPercentageFilter;
      }).toList();
    }
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton("All", null),
          _buildFilterButton("10%", "10"),
          _buildFilterButton("20%", "20"),
          _buildFilterButton("30%", "30"),
          _buildFilterButton("40%", "40"),
          _buildFilterButton("50%", "50"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String? percentage) {
    final isSelected = _selectedPercentageFilter == percentage;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPercentageFilter = percentage;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Coupon', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _bleController.startScan();
              _fetchCoupons();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'lib/assets/logo.png',
              height: 80,
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 10),
          Obx(() => _bleController.isScanning.value
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                Text('Scanning for nearby coupons...'),
              ],
            ),
          )
              : SizedBox()),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Obx(() {
              final filteredCoupons = _filteredCoupons;
              return filteredCoupons.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _bleController.scannedBeaconIds.isEmpty
                          ? 'No nearby beacon devices detected.\nMove closer to a store to see available coupons.'
                          : _selectedPercentageFilter == null
                          ? 'No coupons available from nearby stores.'
                          : 'No ${_selectedPercentageFilter}% coupons available nearby.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Total coupons: ${_coupons.length}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      'Nearby beacons: ${_bleController.scannedBeaconIds.length}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _bleController.startScan();
                        _fetchCoupons();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Scan Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredCoupons.length,
                itemBuilder: (context, index) {
                  final coupon = filteredCoupons[index];
                  return Card(
                    margin: EdgeInsets.all(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: NetworkImage(
                                  'http://192.168.0.197:8080/storage/${coupon['photo']}',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${coupon['percentage']}% off',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  coupon['description'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Expires: ${coupon['expiry_date'].toString().split('T')[0]}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Redeemcoupon(
                                      coupon: coupon,
                                    )),
                              );
                            },
                            child: Text('Redeem'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
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