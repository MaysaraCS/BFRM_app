// import 'package:flutter/material.dart';
// import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
// import 'package:flutter_google_places/flutter_google_places.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:google_api_headers/google_api_headers.dart';
// import 'package:bfrm_app_flutter/screens/logo.dart';
// import 'package:bfrm_app_flutter/screens/login.dart';
//
// import '../model/Login.dart';
//
// const kGoogleApiKey = 'AIzaSyBeDzl0MOiEQpnwthVENf7xDdyF5rXyRio';
// final homeScaffoldKey = GlobalKey<ScaffoldState>();
//
// class Restaurantlocation extends StatefulWidget {
//   final Login usernameData; // Assume you passed primeGoal in the previous page
//   const Restaurantlocation({super.key, required this.usernameData});
//
//   @override
//   State<Restaurantlocation> createState() => _RestaurantlocationState();
// }
//
// class _RestaurantlocationState extends State<Restaurantlocation> {
//   static const CameraPosition initialCameraPosition = CameraPosition(target: LatLng(37.42796, -122.08574), zoom: 14.0);
//
//   Set<Marker> markersList = {};
//   late GoogleMapController googleMapController;
//
//   final Mode _mode = Mode.overlay;
//   final TextEditingController _locationController = TextEditingController();
//
//   // Function to handle place search
//   Future<void> _handlePressButton() async {
//     Prediction? p = await PlacesAutocomplete.show(
//       context: context,
//       apiKey: kGoogleApiKey,
//       onError: onError,
//       mode: _mode,
//       language: 'en',
//       strictbounds: false,
//       types: [""],
//       decoration: InputDecoration(
//         hintText: 'Search',
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: const BorderSide(color: Colors.white),
//         ),
//       ),
//       components: [
//         Component(Component.country, "my"),
//         Component(Component.country, "usa"),
//       ],
//     );
//
//     if (p != null) {
//       displayPrediction(p);
//     }
//   }
//
//   // Function to handle errors in place search
//   void onError(PlacesAutocompleteResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       elevation: 0,
//       behavior: SnackBarBehavior.floating,
//       backgroundColor: Colors.transparent,
//       content: AwesomeSnackbarContent(
//         title: 'Error',
//         message: response.errorMessage!,
//         contentType: ContentType.failure,
//       ),
//     ));
//   }
//
//   // Function to display predictions and save selected location
//   Future<void> displayPrediction(Prediction p) async {
//     _locationController.text = p.description!; // Autofill the selected location
//     widget.usernameData.restaurantLocation = p.description; // Save the location string
//     GoogleMapsPlaces places = GoogleMapsPlaces(
//       apiKey: kGoogleApiKey,
//       apiHeaders: await const GoogleApiHeaders().getHeaders(),
//     );
//
//     PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);
//
//     final lat = detail.result.geometry!.location.lat;
//     final lng = detail.result.geometry!.location.lng;
//
//     markersList.clear();
//     markersList.add(Marker(
//       markerId: const MarkerId("0"),
//       position: LatLng(lat, lng),
//       infoWindow: InfoWindow(title: detail.result.name),
//     ));
//
//     setState(() {});
//
//     googleMapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
//   }
//
//   // Function to handle "NEXT" button click
//   Future<void> _submitLocation() async {
//     final String restaurantLocation = _locationController.text.trim();
//     widget.usernameData.restaurantLocation = restaurantLocation;
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Logo(usernameData: widget.usernameData),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false, // Prevent widget resizing
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => LoginPage()),
//             );
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Image.asset(
//               'lib/assets/logo.png',
//               height: 80,
//             ),
//             const SizedBox(height: 20),
//             Image.asset(
//               'lib/assets/location.png',
//               height: 150, // Larger image
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "What is your Restaurant location?",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             GestureDetector(
//               onTap: _handlePressButton,
//               child: AbsorbPointer(
//                 child: TextField(
//                   controller: _locationController,
//                   decoration: const InputDecoration(
//                     labelText: "Type your Restaurant address",
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.location_on),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity, // Make the button wide
//               child: ElevatedButton(
//                 onPressed: _submitLocation,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: Colors.blue,
//                 ),
//                 child: const Text("NEXT", style: TextStyle(fontSize: 16, color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bfrm_app_flutter/screens/logo.dart';
import 'package:bfrm_app_flutter/screens/login.dart';

import '../model/Login.dart';

class Restaurantlocation extends StatefulWidget {
  final Login usernameData;
  const Restaurantlocation({super.key, required this.usernameData});

  @override
  State<Restaurantlocation> createState() => _RestaurantlocationState();
}

class _RestaurantlocationState extends State<Restaurantlocation> {
  final TextEditingController _streetController = TextEditingController();

  // Malaysian cities
  final List<String> _malaysianCities = [
    'Kuala Lumpur',
    'George Town',
    'Johor Bahru',
    'Shah Alam',
    'Petaling Jaya',
    'Ipoh',
    'Kuching',
    'Kota Kinabalu',
    'Seremban',
    'Malacca City',
    'Alor Setar',
    'Kuantan',
    'Kota Bharu',
    'Kuala Terengganu',
    'Miri',
    'Sandakan',
    'Tawau',
    'Sibu',
    'Bintulu',
    'Taiping',
    'Ampang',
    'Subang Jaya',
    'Klang',
    'Kajang',
    'Selayang',
    'Cheras',
    'Sungai Petani',
    'Batu Pahat',
    'Muar',
    'Segamat',
    'Kluang',
    'Pontian',
    'Kulai',
    'Skudai',
    'Pasir Gudang',
  ];

  // Malaysian states
  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Malacca',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  String? _selectedCity;
  String? _selectedState;

  // Function to validate the location input
  bool _validateLocation() {
    if (_streetController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter the restaurant street address.');
      return false;
    }

    if (_selectedCity == null) {
      _showErrorSnackbar('Please select a city.');
      return false;
    }

    if (_selectedState == null) {
      _showErrorSnackbar('Please select a state.');
      return false;
    }

    // Basic validation for minimum length
    if (_streetController.text.trim().length < 5) {
      _showErrorSnackbar('Please enter a more detailed street address.');
      return false;
    }

    return true;
  }

  // Function to show error messages
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Invalid Input',
        message: message,
        contentType: ContentType.failure,
      ),
    ));
  }

  // Function to show success message
  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Success',
        message: 'Restaurant location saved successfully!',
        contentType: ContentType.success,
      ),
    ));
  }

  // Function to build the complete address string
  String _buildCompleteAddress() {
    List<String> addressParts = [];

    if (_streetController.text.trim().isNotEmpty) {
      addressParts.add(_streetController.text.trim());
    }
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      addressParts.add(_selectedCity!);
    }
    if (_selectedState != null && _selectedState!.isNotEmpty) {
      addressParts.add(_selectedState!);
    }
    addressParts.add('Malaysia'); // Always add Malaysia at the end

    return addressParts.join(', ');
  }

  // Function to handle "NEXT" button click
  Future<void> _submitLocation() async {
    if (!_validateLocation()) {
      return;
    }

    final String completeAddress = _buildCompleteAddress();
    widget.usernameData.restaurantLocation = completeAddress;

    _showSuccessSnackbar();

    // Wait a bit for the snackbar to show
    await Future.delayed(const Duration(milliseconds: 1500));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Logo(usernameData: widget.usernameData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.png',
              height: 80,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'lib/assets/location.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              "What is your Restaurant location?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Street Address Input
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: "Restaurant Street Address *",
                hintText: "e.g., 123 Jalan Bukit Bintang",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // City Selection
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: "City *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              hint: const Text('Select a city'),
              items: _malaysianCities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
              },
            ),

            const SizedBox(height: 20),

            // State Selection
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: "State *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              hint: const Text('Select a state'),
              items: _malaysianStates.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedState = newValue;
                });
              },
            ),

            const SizedBox(height: 30),

            // Preview of complete address
            if (_streetController.text.isNotEmpty || _selectedCity != null || _selectedState != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address Preview:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildCompleteAddress(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "NEXT",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}