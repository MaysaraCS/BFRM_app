import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constant.dart';

class Favlist extends StatefulWidget {
  const Favlist({Key? key}) : super(key: key);

  @override
  State<Favlist> createState() => _FavlistState();
}

class _FavlistState extends State<Favlist> {
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final response = await http.get(Uri.parse('$favoriteURL'));
    if (response.statusCode == 200) {
      setState(() {
        _favorites = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load favorites')),
      );
    }
  }

  Future<void> _deleteFavorite(int favoriteId) async {
    final response = await http.delete(Uri.parse('$favoriteURL/$favoriteId'));
    if (response.statusCode == 200) {
      setState(() {
        _favorites.removeWhere((item) => item['id'] == favoriteId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorite list')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove from favorite list')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Favorite List', style: TextStyle(color: Colors.black)),
      ),
      body: _favorites.isEmpty
          ? const Center(child: Text('No favorites added yet'))
          : ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return Card(
            child: ListTile(
              leading: Image.network(favorite['photo']),
              title: Text(favorite['description']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFavorite(favorite['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
