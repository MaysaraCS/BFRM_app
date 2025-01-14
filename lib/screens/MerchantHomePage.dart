import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/report.dart';
import 'package:bfrm_app_flutter/screens/camera.dart';
import 'package:bfrm_app_flutter/screens/newCoupon.dart';
import 'package:bfrm_app_flutter/screens/couponList.dart';

import 'package:bfrm_app_flutter/screens/newDiscount.dart';
import 'package:bfrm_app_flutter/screens/mercchantProfile.dart';

class Merchanthomepage extends StatefulWidget {
  const Merchanthomepage({super.key});

  @override
  State<Merchanthomepage> createState() => _MerchanthomepageState();
}

class _MerchanthomepageState extends State<Merchanthomepage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Merchanthomepage(),
    const Report(),
    const Camera(),
    CouponListPage(),
    const Mercchantprofile(),
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
          Center(
            child: Image.asset(
              'lib/assets/logo.png', // Replace with the correct path to your logo.png
              height: 80,
            ),
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  NewCoupon()),
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
                    MaterialPageRoute(builder: (context) => const Newdiscount()),
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
          const SizedBox(height: 120),
          const Center(
            child: Text(
              "Hello! Welcome to BEACCON FOR RESTAURANT MARKETING APP",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
