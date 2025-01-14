import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:bfrm_app_flutter/screens/logo.dart';
import 'package:bfrm_app_flutter/screens/login.dart';

import '../model/Login.dart';

const kGoogleApiKey = 'AIzaSyBeDzl0MOiEQpnwthVENf7xDdyF5rXyRio';
final homeScaffoldKey = GlobalKey<ScaffoldState>();

class Restaurantlocation extends StatefulWidget {
  final Login usernameData; // Assume you passed primeGoal in the previous page
  const Restaurantlocation({super.key, required this.usernameData});

  @override
  State<Restaurantlocation> createState() => _RestaurantlocationState();
}

class _RestaurantlocationState extends State<Restaurantlocation> {
  static const CameraPosition initialCameraPosition = CameraPosition(target: LatLng(37.42796, -122.08574), zoom: 14.0);

  Set<Marker> markersList = {};
  late GoogleMapController googleMapController;

  final Mode _mode = Mode.overlay;
  final TextEditingController _locationController = TextEditingController();

  // Function to handle place search
  Future<void> _handlePressButton() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: _mode,
      language: 'en',
      strictbounds: false,
      types: [""],
      decoration: InputDecoration(
        hintText: 'Search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      components: [
        Component(Component.country, "my"),
        Component(Component.country, "usa"),
      ],
    );

    if (p != null) {
      displayPrediction(p);
    }
  }

  // Function to handle errors in place search
  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Error',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  // Function to display predictions and save selected location
  Future<void> displayPrediction(Prediction p) async {
    _locationController.text = p.description!; // Autofill the selected location
    widget.usernameData.restaurantLocation = p.description; // Save the location string
    GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: kGoogleApiKey,
      apiHeaders: await const GoogleApiHeaders().getHeaders(),
    );

    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    markersList.clear();
    markersList.add(Marker(
      markerId: const MarkerId("0"),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: detail.result.name),
    ));

    setState(() {});

    googleMapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }

  // Function to handle "NEXT" button click
  Future<void> _submitLocation() async {
    final String restaurantLocation = _locationController.text.trim();
    widget.usernameData.restaurantLocation = restaurantLocation;

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
      resizeToAvoidBottomInset: false, // Prevent widget resizing
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
      body: Padding(
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
              height: 150, // Larger image
            ),
            const SizedBox(height: 20),
            const Text(
              "What is your Restaurant location?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _handlePressButton,
              child: AbsorbPointer(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Type your Restaurant address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button wide
              child: ElevatedButton(
                onPressed: _submitLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("NEXT", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
