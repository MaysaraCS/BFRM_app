import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/favList.dart';
import 'package:bfrm_app_flutter/screens/customerCoupon.dart';
import 'package:bfrm_app_flutter/screens/customerProfile.dart';


class Customerhomepage extends StatefulWidget {
  const Customerhomepage({super.key});

  @override
  State<Customerhomepage> createState() => _CustomerhomepageState();
}

class _CustomerhomepageState extends State<Customerhomepage> {

  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Customerhomepage(),
    const Favlist(),
    CustomerCouponPage(),
    const Customerprofile(),
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
