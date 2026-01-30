import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  const SearchResultsPage({required this.searchQuery, super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<QueryDocumentSnapshot>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = _fetchSearchResults(widget.searchQuery);
  }

  Future<List<QueryDocumentSnapshot>> _fetchSearchResults(String query) async {
    // 🔹 Simple name search
    final snapshot = await _firestore
        .collection('places')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results: "${widget.searchQuery}"'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final place = results[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: place['imageUrl'] != null
                    ? Image.network(place['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.location_on),
                title: Text(place['name'] ?? ''),
                subtitle: Text(place['description'] ?? ''),
                onTap: () {
                  // 🔹 Navigate to detailed place page or add to trip
                },
              );
            },
          );
        },
      ),
    );
  }
}
