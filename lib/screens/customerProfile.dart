import 'package:flutter/material.dart';

class Customerprofile extends StatefulWidget {
  const Customerprofile({super.key});

  @override
  State<Customerprofile> createState() => _CustomerprofileState();
}

class _CustomerprofileState extends State<Customerprofile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Profile Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Customer Profile page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
