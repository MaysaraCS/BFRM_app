import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'validateCoupon.dart'; // Import ValidateCoupon widget here

class Camera extends StatefulWidget {
  const Camera({Key? key}) : super(key: key);

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Scanner"),
        backgroundColor: Colors.blue,
      ),
      body: _isScanning
          ? MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;
          if (code != null && _isScanning) {
            setState(() {
              _isScanning = false; // Stop scanning after a valid QR code
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ValidateCoupon(scannedData: code),
              ),
            );
          }
        },
      )
          : const Center(
        child: Text(
          "No QR code detected.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
