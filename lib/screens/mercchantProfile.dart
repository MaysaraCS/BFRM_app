import 'package:flutter/material.dart';

class Mercchantprofile extends StatefulWidget {
  const Mercchantprofile({super.key});

  @override
  State<Mercchantprofile> createState() => _MercchantprofileState();
}

class _MercchantprofileState extends State<Mercchantprofile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Merchant profile Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Merchant profile Page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}