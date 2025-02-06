import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bfrm_app_flutter/screens/redeemCoupon.dart';

import '../constant.dart';

class CustomerCouponPage extends StatefulWidget {
  @override
  _CustomerCouponPageState createState() => _CustomerCouponPageState();
}

class _CustomerCouponPageState extends State<CustomerCouponPage> {
  List<dynamic> _coupons = [];
  String? _selectedPercentageFilter;

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
        });
      } else {
        print('Failed to load coupons');
      }
    } catch (e) {
      print('Error fetching coupons: $e');
    }
  }

  List<dynamic> get _filteredCoupons {
    if (_selectedPercentageFilter == null) {
      return _coupons;
    } else {
      return _coupons.where((coupon) {
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'lib/assets/logo.png', // Replace with your logo path
              height: 80,
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredCoupons.isEmpty
                ? Center(
              child: Text(
                _selectedPercentageFilter == null
                    ? 'No coupons available at the moment.'
                    : 'This is the available coupons for now.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
                : ListView.builder(
              itemCount: _filteredCoupons.length,
              itemBuilder: (context, index) {
                final coupon = _filteredCoupons[index];
                List <String> scannedBeacon = [
                  "C3:00:00:1C:76:52",
                  "C3:00:00:1C:76:51",
                  "C3:00:00:1C:76:53"];
                bool isExist = scannedBeacon.contains(coupon["beacon_id"]);
                return isExist == true ? Card(
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
                                'http://192.168.8.112:8080/storage/${coupon['photo']}',
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
                                coupon['beacon_id'],
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isExist.toString(),
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Expires: ${coupon['expiry_date']}',
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
                ):Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
