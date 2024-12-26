import 'package:flutter/material.dart';

class Customerhomepage extends StatefulWidget {
  const Customerhomepage({super.key});

  @override
  State<Customerhomepage> createState() => _CustomerhomepageState();
}

class _CustomerhomepageState extends State<Customerhomepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Home Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Home page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
