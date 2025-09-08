// lib/screens/landlord_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/add_landlord_screen.dart';
import 'package:immo_app/screens/landlord_details_screen.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';

class LandlordListScreen extends StatefulWidget {
  @override
  _LandlordListScreenState createState() => _LandlordListScreenState();
}

class _LandlordListScreenState extends State<LandlordListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final int _limit = 20; // Anzahl der Elemente pro Seite
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _landlords = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadLandlords();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll-Listener für Endless Scroll
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoading && _hasMore) {
        _loadMoreLandlords();
      }
    }
  }

  // Erste Ladung der Vermieter
  Future<void> _loadLandlords() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Bei Suchfilter: Lade alle und filtere clientseitig
      if (_searchQuery.isNotEmpty) {
        final snapshot = await _firestore.collection('landlords').get();
        final filteredDocs = _filterLandlords(snapshot.docs);
        
        setState(() {
          _landlords = filteredDocs;
          _hasMore = false; // Keine weitere Pagination bei Suchfilter
          _isLoading = false;
        });
        return;
      }
      
      // Ohne Suchfilter: Normale Pagination
      Query query = _firestore.collection('landlords').limit(_limit);
      final snapshot = await query.get();
      
      setState(() {
        _landlords = snapshot.docs;
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Fehler beim Laden der Vermieter: $e');
    }
  }

  // Weitere Vermieter laden (Pagination)
  Future<void> _loadMoreLandlords() async {
    if (_isLoading || !_hasMore) return;
    
    // Bei Suchfilter keine weitere Pagination
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _hasMore = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore.collection('landlords')
          .startAfterDocument(_lastDocument!)
          .limit(_limit);
      
      final snapshot = await query.get();
      
      setState(() {
        _landlords.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Fehler beim Laden weiterer Vermieter: $e');
    }
  }

  // Clientseitige Filterung
  List<DocumentSnapshot> _filterLandlords(List<DocumentSnapshot> landlords) {
    if (_searchQuery.isEmpty) {
      return landlords;
    }

    final normalizedQuery = _searchQuery.toLowerCase().trim();
    
    return landlords.where((landlordDoc) {
      final landlord = landlordDoc.data() as Map<String, dynamic>;
      final name = landlord['name'] as String?;
      
      if (name == null) return false;
      
      final normalizedName = name.toLowerCase();
      
      // Teile den Suchbegriff in Wörter auf
      final queryWords = normalizedQuery.split(' ').where((word) => word.isNotEmpty);
      
      // Prüfe ob alle Suchwörter im Namen vorkommen
      return queryWords.every((queryWord) => normalizedName.contains(queryWord));
    }).toList();
  }

  // Filter anwenden
  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query.trim();
      _lastDocument = null;
      _hasMore = true;
      _landlords.clear();
    });
    _loadLandlords();
  }

  // Filter-Dialog anzeigen
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final searchController = TextEditingController(text: _searchQuery);
        
        return AlertDialog(
          title: Text('Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Name suchen',
                  hintText: 'Vorname, Nachname oder voller Name...',
                  prefixIcon: Icon(Icons.search),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  _applyFilter(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.clear();
                _applyFilter('');
                Navigator.pop(context);
              },
              child: Text('Zurücksetzen'),
            ),
            TextButton(
              onPressed: () {
                _applyFilter(searchController.text);
                Navigator.pop(context);
              },
              child: Text('Anwenden'),
            ),
          ],
        );
      },
    );
  }

  // Methode zur Berechnung der Durchschnittsbewertung
  double _calculateOverallRating(Map<String, dynamic> landlord) {
    final reviews = landlord['reviews'] as List<dynamic>?;

    if (reviews == null || reviews.isEmpty) {
      return 0.0;
    }

    double totalSum = 0;
    int totalCount = 0;

    // Bewertungskategorien für Vermieter
    final ratingCategories = [
      'communication',
      'helpfulness',
      'fairness',
      'transparency',
      'responseTime',
      'respect',
      'renovationManagement',
      'leaseAgreement',
      'operatingCosts',
      'depositHandling',
    ];

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        for (var category in ratingCategories) {
          final rating = review[category]?.toDouble() ?? 0.0;
          totalSum += rating;
          totalCount++;
        }
      }
    }

    return totalCount > 0 ? totalSum / totalCount : 0.0;
  }

  // Methode zur Anzeige der Sternebewertung
  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    double fractionalPart = rating - fullStars;

    if (fractionalPart < 0.5) {
      fractionalPart = 0;
    } else if (fractionalPart >= 0.5 && fractionalPart < 1) {
      fractionalPart = 0.5;
    } else {
      fractionalPart = 1;
    }

    int emptyStars = 5 - fullStars - (fractionalPart > 0 ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.orange, size: 14),
        if (fractionalPart == 0.5)
          Icon(Icons.star_half, color: Colors.orange, size: 14),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: Colors.grey, size: 14),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _searchQuery.isNotEmpty
                ? 'Keine Vermieter für "$_searchQuery" gefunden'
                : 'Keine Vermieter gefunden',
          ),
          SizedBox(height: 16),
          Text(
            'Fügen Sie den ersten Vermieter hinzu,\n'
            'um Bewertungen zu teilen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordCard(DocumentSnapshot landlordDoc) {
    final landlord = landlordDoc.data() as Map<String, dynamic>;
    final overallRating = _calculateOverallRating(landlord);
    final List<dynamic>? imageUrls = landlord['imageUrls'];
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    final firstImageUrl = hasImages ? imageUrls![0] : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LandlordDetailScreen(landlordDoc: landlordDoc),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: firstImageUrl != null
                  ? Image.network(
                      firstImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person, // Geändert von Icons.business zu Icons.person
                            color: Colors.grey[600],
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person, // Geändert von Icons.business zu Icons.person
                        color: Colors.grey[600],
                        size: 40,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    landlord['name'] ?? 'Unbekannter Vermieter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  _buildStarRating(overallRating),
                  SizedBox(height: 4),
                  Text(
                    '${landlord['reviews']?.length ?? 0} Bewertungen',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vermieter'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Aktive Filter anzeigen
          if (_searchQuery.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text('Name: $_searchQuery'),
                    onDeleted: () {
                      _applyFilter('');
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      _applyFilter('');
                    },
                    child: Text('Filter löschen'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _applyFilter(_searchQuery);
              },
              child: _landlords.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      padding: EdgeInsets.all(16),
                      itemCount: _landlords.length + (_hasMore && _searchQuery.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _landlords.length) {
                          // Loading-Indicator am Ende
                          return _buildLoadingIndicator();
                        }
                        
                        final landlordDoc = _landlords[index];
                        return _buildLandlordCard(landlordDoc);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final confirmed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantVerificationScreen(
                isApartment: false,
                targetName: 'Neuer Vermieter',
              ),
            ),
          );

          if (confirmed == true) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddLandlordScreen()),
            );
            
            // Wenn ein neuer Vermieter erfolgreich erstellt wurde, aktualisiere die Liste
            if (result != null && result is Map && result['success'] == true) {
              // Force refresh der Liste
              _applyFilter(_searchQuery);
            }
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Vermieter hinzufügen',
      ),
    );
  }
}