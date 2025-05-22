import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
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
  final BleController _bleController = Get.put(BleController());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAndStartScan();
  }

  Future<void> _initializeAndStartScan() async {
    await _bleController.initNotifications();
    await _bleController.startScan();
    _fetchCoupons();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart scanning when app comes to foreground
      _bleController.startScan();
      _fetchCoupons();
    }
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(couponURL));
      if (response.statusCode == 200) {
        setState(() {
          _coupons = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Failed to load coupons');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching coupons: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredCoupons {
    // First filter by nearby beacons
    final nearbyBeaconCoupons = _coupons.where((coupon) {
      return _bleController.scannedBeaconIds.contains(coupon['beacon_id']);
    }).toList();

    // Then apply percentage filter if selected
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