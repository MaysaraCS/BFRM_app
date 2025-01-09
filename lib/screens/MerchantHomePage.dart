import 'package:flutter/material.dart';


class Merchanthomepage extends StatefulWidget {
  const Merchanthomepage({super.key});

  @override
  State<Merchanthomepage> createState() => _MerchanthomepageState();
}

class _MerchanthomepageState extends State<Merchanthomepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Home Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Merchant Home page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}