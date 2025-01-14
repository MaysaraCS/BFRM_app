import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/RestaurantLocation.dart';

import '../model/Login.dart';


class Primarygoal extends StatefulWidget {
  final Login usernameData; // Assume you passed restaurantname in the previous page
  const Primarygoal({super.key, required this.usernameData});

  @override
  State<Primarygoal> createState() => _PrimarygoalState();
}

class _PrimarygoalState extends State<Primarygoal> {

  bool _isIncrease = false;
  bool _isPromote = false;
  bool _isCustomerFeedback = false;

  final TextEditingController _othersController = TextEditingController();


  // Submit preferences to API
  Future<void> _submitPrimaryGoal() async {
    final selectedPrimGoal = <String>[];

    if (_isIncrease) selectedPrimGoal.add('Increase foot traffic');
    if (_isPromote) selectedPrimGoal.add('Promote discounts');
    if (_isCustomerFeedback) selectedPrimGoal.add('customer feedback');
    if (_othersController.text
        .trim()
        .isNotEmpty) {
      selectedPrimGoal.add(_othersController.text.trim());
    }

    if (selectedPrimGoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one Primary Goal')),
      );
      return;
    }
    widget.usernameData.PrimGoal = selectedPrimGoal;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Restaurantlocation(usernameData:widget.usernameData),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.white, // White app bar for consistency
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo at the top
              Image.asset('lib/assets/logo.png', height: 80),
              const SizedBox(height: 20),

              // Preference image
              Image.asset('lib/assets/prime.png', height: 120), // Adjusted size
              const SizedBox(height: 20),

              const Text(
                "What is your primary goal for using this app?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Cuisine preference checkboxes
              CheckboxListTile(
                title: const Text("Increase foot traffic"),
                value: _isIncrease,
                onChanged: (bool? value) {
                  setState(() {
                    _isIncrease = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Promote discounts"),
                value: _isPromote,
                onChanged: (bool? value) {
                  setState(() {
                    _isPromote = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("customer feedback"),
                value: _isCustomerFeedback,
                onChanged: (bool? value) {
                  setState(() {
                    _isCustomerFeedback = value!;
                  });
                },
              ),

              // TextField for "Others"
              const SizedBox(height: 10),
              TextField(
                controller: _othersController,
                decoration: InputDecoration(
                  labelText: "Others (please specify)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Submit button
              ElevatedButton(
                onPressed: _submitPrimaryGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}