import 'package:flutter/material.dart';


class Newdiscount extends StatefulWidget {
  const Newdiscount({super.key});

  @override
  State<Newdiscount> createState() => _NewdiscountState();
}

class _NewdiscountState extends State<Newdiscount> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Discount Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! New Discount Page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
