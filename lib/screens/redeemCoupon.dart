import 'package:flutter/material.dart';

class Redeemcoupon extends StatefulWidget {
  const Redeemcoupon({super.key});

  @override
  State<Redeemcoupon> createState() => _RedeemcouponState();
}

class _RedeemcouponState extends State<Redeemcoupon> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("redeem coupon Page"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Hello! Customer redeem coupon page in progress",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
