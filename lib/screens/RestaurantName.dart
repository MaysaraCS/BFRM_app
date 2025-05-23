import 'package:flutter/material.dart';

import '../model/Login.dart';
import 'package:bfrm_app_flutter/screens/PrimaryGoal.dart';

import 'login.dart';


class Restaurantname extends StatefulWidget {
  final Login usernameData;
  const Restaurantname({Key? key, required this.usernameData}) : super(key: key);

  @override
  State<Restaurantname> createState() => _RestaurantnameState();
}

class _RestaurantnameState extends State<Restaurantname> {

  final TextEditingController _RestaurantnameController = TextEditingController();

  Future<void> _submitRestaurantname() async {
    final String restaurantname = _RestaurantnameController.text.trim();
    widget.usernameData.restaurantName = restaurantname;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Primarygoal(usernameData:widget.usernameData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent widget resizing

      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.png',
              height: 80,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'lib/assets/restaurant.png',
              height: 150, // Larger image
            ),
            const SizedBox(height: 20),
            const Text(
              "what is your Restaurant name ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _RestaurantnameController,
              decoration: const InputDecoration(
                labelText: "Type your Restaurant name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button wide
              child: ElevatedButton(
                onPressed: _submitRestaurantname,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("NEXT", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
