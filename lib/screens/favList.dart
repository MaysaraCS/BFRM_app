import 'package:flutter/material.dart';

class Favlist extends StatefulWidget {
  const Favlist({super.key});

  @override
  State<Favlist> createState() => _FavlistState();
}

class _FavlistState extends State<Favlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite list Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Favorite list page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}