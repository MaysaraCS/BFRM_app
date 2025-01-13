import 'package:flutter/material.dart';


class Restaurantname extends StatefulWidget {
  const Restaurantname({super.key});

  @override
  State<Restaurantname> createState() => _RestaurantnameState();
}

class _RestaurantnameState extends State<Restaurantname> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Restaurant home page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}