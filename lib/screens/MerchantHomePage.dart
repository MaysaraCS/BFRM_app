import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/newCoupon.dart';
import 'package:bfrm_app_flutter/screens/newDiscount.dart';
import 'package:bfrm_app_flutter/screens/editDiscount.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mercchantProfile.dart';
import 'camera.dart';
import 'report.dart';
import 'couponList.dart';
import '../model/Login.dart';
import '../constant.dart';

class Merchanthomepage extends StatefulWidget {
  final Login? usernameData;

  const Merchanthomepage({super.key, this.usernameData});

  @override
  State<Merchanthomepage> createState() => _MerchanthomepageState();
}

class _MerchanthomepageState extends State<Merchanthomepage> {
  int _currentIndex = 0;
  List<dynamic> _discounts = [];
  bool _isLoading = false;

  // Colors for discount cards
  final List<List<Color>> _cardGradients = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E8E)], // Red gradient
    [Color(0xFF4ECDC4), Color(0xFF7BDDD8)], // Teal gradient
    [Color(0xFF45B7D1), Color(0xFF68C5E8)], // Blue gradient
    [Color(0xFFFA8072), Color(0xFFFFB07C)], // Orange gradient
    [Color(0xFF98D8C8), Color(0xFFB8E6D3)], // Green gradient
    [Color(0xFFDDA0DD), Color(0xFFE6B3E6)], // Purple gradient
  ];

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    // Enhanced validation with better error messages
    if (widget.usernameData?.userId == null || widget.usernameData!.userId!.isEmpty) {
      print('DEBUG: ERROR: User ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please login again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build the URL with merchant_id parameter
      final url = '$discountURL?merchant_id=${widget.usernameData!.authToken}';
      print('DEBUG: Making request to: $url');

      // Prepare headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if available
      if (widget.usernameData!.isAuthenticated()) {
        headers['Authorization'] = 'Bearer ${widget.usernameData!.authToken}';
        print('DEBUG: Added Authorization header');
      } else {
        print('DEBUG: No auth token available');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('DEBUG: Response received: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Check if response body is empty
          if (response.body.trim().isEmpty) {
            print('DEBUG: Response body is empty!');
            setState(() {
              _discounts = [];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server returned empty response')),
            );
            return;
          }

          final responseData = json.decode(response.body);
          print('DEBUG: JSON parsed successfully. Structure: ${responseData.toString()}');

          setState(() {
            // Your Laravel API returns: {"status": true, "message": "...", "data": [...]}
            if (responseData is Map) {
              if (responseData.containsKey('status') && responseData['status'] == true) {
                // Laravel success response
                if (responseData.containsKey('data') && responseData['data'] is List) {
                  _discounts = responseData['data'];
                  print('DEBUG: Laravel API: Set ${_discounts.length} discounts from data array');
                } else {
                  _discounts = [];
                  print('DEBUG: Laravel API: No data array found or data is not a list');
                }
              } else if (responseData.containsKey('status') && responseData['status'] == false) {
                // Laravel error response
                _discounts = [];
                final message = responseData['message'] ?? 'Unknown error';
                print('DEBUG: Laravel API Error: $message');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API Error: $message')),
                );
              } else {
                // Fallback for other response structures
                if (responseData.containsKey('data') && responseData['data'] is List) {
                  _discounts = responseData['data'];
                  print('DEBUG: Fallback: Set ${_discounts.length} discounts from data array');
                } else {
                  _discounts = [];
                  final keys = responseData.keys.toList();
                  print('DEBUG: Unknown response structure. Keys: $keys');
                }
              }
            } else if (responseData is List) {
              _discounts = responseData;
              print('DEBUG: Direct list response: ${_discounts.length} discounts');
            } else {
              _discounts = [];
              print('DEBUG: Response is neither map nor list: ${responseData.runtimeType}');
            }

            // Sort discounts if there are any
            if (_discounts.isNotEmpty) {
              _discounts.sort((a, b) {
                final aDate = a['created_at'] ?? '';
                final bDate = b['created_at'] ?? '';
                return bDate.compareTo(aDate);
              });
            }
          });

          print('DEBUG: Final discount count: ${_discounts.length}');

          // Show result message
          if (_discounts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No discounts found'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loaded ${_discounts.length} discounts'),
                backgroundColor: Colors.green,
              ),
            );
          }

        } catch (jsonError) {
          print('DEBUG: JSON parsing failed: $jsonError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid JSON response: $jsonError')),
          );
        }
      } else if (response.statusCode == 404) {
        print('DEBUG: 404 - No discounts found or endpoint not found');
        setState(() {
          _discounts = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No discounts found for this merchant'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        print('DEBUG: HTTP Error ${response.statusCode}: ${response.body}');

        String errorMessage = 'Failed to fetch discounts (${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Use default error message
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('DEBUG: Network/General error: $e');

      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection or server unreachable';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid server response format';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDiscount(dynamic discountId) async {
    try {
      // Ensure discountId is properly converted to string for URL
      final String id = discountId.toString();
      print('DEBUG: Attempting to delete discount with ID: $id');

      // Validate user data
      if (widget.usernameData?.userId == null || widget.usernameData!.userId!.isEmpty) {
        print('DEBUG: ERROR: User ID is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please login again.')),
        );
        return;
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if available
      if (widget.usernameData?.isAuthenticated() == true) {
        headers['Authorization'] = 'Bearer ${widget.usernameData!.authToken}';
        print('DEBUG: Added Authorization header for delete request');
      }

      // Build URL - try both query parameter and request body approaches
      final url = '$discountURL/$id';
      print('DEBUG: Delete request URL: $url');

      // Prepare request body with merchant_id (as backup method)
      final requestBody = json.encode({
        'merchant_id': widget.usernameData!.userId,
      });

      print('DEBUG: Request body: $requestBody');
      print('DEBUG: Headers: $headers');

      // First attempt: DELETE with query parameter (as per your current approach)
      var response = await http.delete(
        Uri.parse('$url?merchant_id=${Uri.encodeComponent(widget.usernameData!.userId!)}'),
        headers: headers,
      );

      print('DEBUG: First attempt - Delete response status: ${response.statusCode}');
      print('DEBUG: First attempt - Delete response body: ${response.body}');

      // If first attempt fails with 401/403, try with request body
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('DEBUG: First attempt failed with auth error, trying with request body');

        response = await http.delete(
          Uri.parse(url),
          headers: headers,
          body: requestBody,
        );

        print('DEBUG: Second attempt - Delete response status: ${response.statusCode}');
        print('DEBUG: Second attempt - Delete response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - remove from local list
        setState(() {
          _discounts.removeWhere((discount) {
            // Handle both string and int comparisons
            final discountIdStr = discount['id'].toString();
            final targetIdStr = discountId.toString();
            return discountIdStr == targetIdStr;
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        print('DEBUG: Discount deleted successfully, remaining count: ${_discounts.length}');
      } else {
        // Handle error response
        String errorMessage = 'Failed to delete discount (${response.statusCode})';

        // Handle malformed JSON responses (like the 500 error you're getting)
        try {
          if (response.body.isNotEmpty) {
            // Clean the response body - remove any trailing characters that might cause JSON parsing issues
            String cleanBody = response.body.trim();

            // Check if response body looks like it might be truncated or malformed
            if (!cleanBody.endsWith('}') && !cleanBody.endsWith(']')) {
              print('DEBUG: Response body appears to be truncated: ${cleanBody.length} characters');
              // Try to find the last complete JSON object
              int lastBraceIndex = cleanBody.lastIndexOf('}');
              if (lastBraceIndex > 0) {
                cleanBody = cleanBody.substring(0, lastBraceIndex + 1);
                print('DEBUG: Attempting to parse truncated JSON');
              }
            }

            final errorData = json.decode(cleanBody);
            if (errorData is Map) {
              if (errorData.containsKey('message') && errorData['message'] != null) {
                errorMessage = errorData['message'].toString();
              } else if (errorData.containsKey('error') && errorData['error'] != null) {
                errorMessage = errorData['error'].toString();
              } else if (errorData.containsKey('exception') && errorData['exception'] != null) {
                // Handle Laravel exception format
                errorMessage = 'Server Error: ${errorData['exception'].toString()}';
                if (errorData.containsKey('message')) {
                  errorMessage += ' - ${errorData['message'].toString()}';
                }
              }
            }
          }
        } catch (jsonError) {
          print('DEBUG: Error parsing delete response JSON: $jsonError');
          print('DEBUG: Raw response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

          // For 500 errors, provide more specific error message
          if (response.statusCode == 500) {
            errorMessage = 'Server error occurred. Please check server logs.';

            // Try to extract error message from HTML or malformed JSON
            if (response.body.contains('Target class [role] does not exist')) {
              errorMessage = 'Server configuration error: Role middleware not found';
            }
          }
        }

        print('DEBUG: Delete failed with message: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Delete request failed with exception: $e');

      String errorMessage = 'An error occurred while deleting discount';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(dynamic discountId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Discount'),
          content: const Text('Are you sure you want to delete this discount? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDiscount(discountId);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex && index == 0) return;

    Widget destination;
    switch (index) {
      case 0:
        return;
      case 1:
        destination = Report();
        break;
      case 2:
        destination = Camera();
        break;
      case 3:
        destination = CouponListPage(usernameData: widget.usernameData);
        break;
      case 4:
        destination = MerchantProfile();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ).then((_) {
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  String _getImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';

    if (photoPath.startsWith('http')) {
      return photoPath;
    }

    // Assuming your storage URL structure
    return 'http://192.168.0.197:8080/storage/$photoPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              widget.usernameData?.email ?? 'Merchant',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchDiscounts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDiscounts,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo Section
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, size: 30),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.usernameData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewCoupon(usernameData: widget.usernameData!),
                              ),
                            ).then((_) {
                              _fetchDiscounts();
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please login first')),
                            );
                          }
                        },
                        icon: Icon(Icons.local_offer),
                        label: Text("New Coupon"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.usernameData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewDiscount(usernameData: widget.usernameData!),
                              ),
                            ).then((_) {
                              _fetchDiscounts();
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please login first')),
                            );
                          }
                        },
                        icon: Icon(Icons.discount),
                        label: Text("New Discount"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // My Discounts Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Discounts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_discounts.isNotEmpty)
                      Text(
                        '${_discounts.length} items',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Discounts Display
              if (_isLoading)
                Container(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_discounts.isEmpty)
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.discount_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No discounts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first discount to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDiscounts,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _discounts.length,
                    itemBuilder: (context, index) {
                      final discount = _discounts[index];
                      final gradientColors = _cardGradients[index % _cardGradients.length];

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Food Type Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      discount['food_type'] ?? 'Food',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: gradientColors[0],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Discount Image
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _getImageUrl(discount['photo']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.fastfood,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Description
                                  Text(
                                    discount['description'] ?? 'Delicious Food Discount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 8),

                                  // Beacon Info
                                  if (discount['beacon_id'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.bluetooth,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Beacon Active',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Action Buttons
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditDiscount(discount: discount),
                                        ),
                                      );
                                      if (result == true) {
                                        _fetchDiscounts();
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _showDeleteConfirmationDialog(discount['id']),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Report",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: "Coupon",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}