import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constant.dart';
import '../model/Login.dart';
import 'MerchantHomePage.dart';
import 'newCoupon.dart';
import 'mercchantProfile.dart';
import 'camera.dart';
import 'report.dart';

class CouponListPage extends StatefulWidget {
  final Login? usernameData;

  const CouponListPage({Key? key, this.usernameData}) : super(key: key);

  @override
  _CouponListPageState createState() => _CouponListPageState();
}

class _CouponListPageState extends State<CouponListPage> {
  List<dynamic> _coupons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
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
      final url = '$couponURL?merchant_id=${widget.usernameData!.userId}';
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
              _coupons = [];
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
                  _coupons = responseData['data'];
                  print('DEBUG: Laravel API: Set ${_coupons.length} coupons from data array');
                } else {
                  _coupons = [];
                  print('DEBUG: Laravel API: No data array found or data is not a list');
                }
              } else if (responseData.containsKey('status') && responseData['status'] == false) {
                // Laravel error response
                _coupons = [];
                final message = responseData['message'] ?? 'Unknown error';
                print('DEBUG: Laravel API Error: $message');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API Error: $message')),
                );
              } else {
                // Fallback for other response structures
                if (responseData.containsKey('data') && responseData['data'] is List) {
                  _coupons = responseData['data'];
                  print('DEBUG: Fallback: Set ${_coupons.length} coupons from data array');
                } else {
                  _coupons = [];
                  final keys = responseData.keys.toList();
                  print('DEBUG: Unknown response structure. Keys: $keys');
                }
              }
            } else if (responseData is List) {
              _coupons = responseData;
              print('DEBUG: Direct list response: ${_coupons.length} coupons');
            } else {
              _coupons = [];
              print('DEBUG: Response is neither map nor list: ${responseData.runtimeType}');
            }

            // Sort coupons if there are any
            if (_coupons.isNotEmpty) {
              _coupons.sort((a, b) {
                final aDate = a['created_at'] ?? '';
                final bDate = b['created_at'] ?? '';
                return bDate.compareTo(aDate);
              });
            }
          });

          print('DEBUG: Final coupon count: ${_coupons.length}');

          // Show result message
          if (_coupons.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No coupons found'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loaded ${_coupons.length} coupons'),
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
        print('DEBUG: 404 - No coupons found or endpoint not found');
        setState(() {
          _coupons = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No coupons found for this merchant'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        print('DEBUG: HTTP Error ${response.statusCode}: ${response.body}');

        String errorMessage = 'Failed to fetch coupons (${response.statusCode})';
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

  Future<void> _deleteCoupon(dynamic couponId) async {
    try {
      // Ensure couponId is properly converted to string for URL
      final String id = couponId.toString();
      print('DEBUG: Attempting to delete coupon with ID: $id');

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
      final url = '$couponURL/$id';
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
          _coupons.removeWhere((coupon) {
            // Handle both string and int comparisons
            final couponIdStr = coupon['id'].toString();
            final targetIdStr = couponId.toString();
            return couponIdStr == targetIdStr;
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        print('DEBUG: Coupon deleted successfully, remaining count: ${_coupons.length}');
      } else {
        // Handle error response
        String errorMessage = 'Failed to delete coupon (${response.statusCode})';

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

      String errorMessage = 'An error occurred while deleting coupon';
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

  void _showDeleteConfirmationDialog(dynamic couponId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Coupon'),
          content: const Text('Are you sure you want to delete this coupon? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCoupon(couponId);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  int _currentIndex = 3;

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = Merchanthomepage(usernameData: widget.usernameData);
        break;
      case 1:
        destination = Report();
        break;
      case 2:
        destination = Camera();
        break;
      case 3:
        return;
      case 4:
        destination = MerchantProfile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Coupons',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCoupons,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Add New Coupon Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.usernameData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewCoupon(usernameData: widget.usernameData!),
                    ),
                  ).then((_) {
                    _fetchCoupons();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login first')),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Coupon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _coupons.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No coupons found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first coupon to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCoupons,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchCoupons,
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: _coupons.length,
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coupon Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                coupon['photo']?.toString().startsWith('http') == true
                                    ? coupon['photo']
                                    : 'http://192.168.0.197:8080/storage/${coupon['photo']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Coupon Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${coupon['percentage']}% OFF',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  coupon['description'] ?? 'No description',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expires: ${_formatDate(coupon['expiry_date'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (coupon['beacon_id'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bluetooth,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Beacon: ${coupon['beacon_id'].toString().substring(0, 8)}...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(coupon['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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