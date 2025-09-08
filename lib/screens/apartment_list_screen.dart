// lib/screens/apartment_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/add_apartment_screen.dart';
import 'package:immo_app/screens/apartment_details_screen.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';

class ApartmentListScreen extends StatefulWidget {
  @override
  _ApartmentListScreenState createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoadingCities = false;

  // Pagination-Variablen
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _apartments = [];
  ScrollController _scrollController = ScrollController();

  // Methode zur Berechnung der Durchschnittsbewertung aus den Reviews
  double calculateOverallRating(List<dynamic> reviews) {
    if (reviews == null || reviews.isEmpty) {
      return 0.0; // Keine Bewertungen vorhanden
    }

    double totalSum = 0;
    int totalCount = 0;

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        final ratings = {
          'accessibility': review['accessibility']?.toDouble() ?? 0.0,
          'cleanliness': review['cleanliness']?.toDouble() ?? 0.0,
          'condition': review['condition']?.toDouble() ?? 0.0,
          'equipment': review['equipment']?.toDouble() ?? 0.0,
          'landlord': review['landlord']?.toDouble() ?? 0.0,
          'leisure': review['leisure']?.toDouble() ?? 0.0,
          'location': review['location']?.toDouble() ?? 0.0,
          'neighbors': review['neighbors']?.toDouble() ?? 0.0,
          'parking': review['parking']?.toDouble() ?? 0.0,
          'safety': review['safety']?.toDouble() ?? 0.0,
          'shopping': review['shopping']?.toDouble() ?? 0.0,
          'transport': review['transport']?.toDouble() ?? 0.0,
          'valueForMoney': review['valueForMoney']?.toDouble() ?? 0.0,
        };

        totalSum += ratings.values.reduce((a, b) => a + b);
        totalCount += ratings.length;
      }
    }

    return totalCount > 0 ? totalSum / totalCount : 0.0;
  }

  // Methode zum Entfernen des letzten Beistrichs aus der Adresse
  String cleanAddress(String address) {
    if (address.endsWith(',')) {
      return address.substring(0, address.length - 1);
    }
    return address;
  }

  // Methode zur Anzeige der Sternebewertung
  Widget buildStarRating(double rating, String label) {
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < fullStars; i++)
              Icon(Icons.star, color: Colors.orange, size: 14),
            if (fractionalPart == 0.5)
              Icon(Icons.star_half, color: Colors.orange, size: 14),
            for (int i = 0; i < emptyStars; i++)
              Icon(Icons.star_border, color: Colors.grey, size: 14),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _loadCities();
        _loadApartments();
      });
    });
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
        _loadMoreApartments();
      }
    }
  }

  // Erste Ladung der Apartments
  Future<void> _loadApartments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore.collection('apartments').limit(_limit);

      // Stadtfilter anwenden
      if (_selectedCity != null) {
        query = query.where('city', isEqualTo: _selectedCity);
      }

      final snapshot = await query.get();

      setState(() {
        _apartments = snapshot.docs;
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Fehler beim Laden der Apartments: $e');
    }
  }

  // Weitere Apartments laden (Pagination)
  Future<void> _loadMoreApartments() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore
          .collection('apartments')
          .startAfterDocument(_lastDocument!)
          .limit(_limit);

      // Stadtfilter anwenden
      if (_selectedCity != null) {
        query = query.where('city', isEqualTo: _selectedCity);
      }

      final snapshot = await query.get();

      setState(() {
        _apartments.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Fehler beim Laden weiterer Apartments: $e');
    }
  }

  // Städte aus Firestore laden
  Future<void> _loadCities() async {
    if (_isLoadingCities) return;

    setState(() {
      _isLoadingCities = true;
    });

    try {
      print('Lade Städte...');

      final snapshot = await _firestore
          .collection('apartments')
          .limit(1000)
          .get();

      print('Geladene Dokumente: ${snapshot.docs.length}');

      final citiesSet = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['city'] != null) {
          citiesSet.add(data['city'].toString());
        }
      }

      print('Gefundene Städte: ${citiesSet.length}');

      setState(() {
        _cities = citiesSet.toList()..sort();
        _isLoadingCities = false;
      });

      print('Städte geladen: ${_cities.length}');
    } catch (e) {
      print('Fehler beim Laden der Städte: $e');
      setState(() {
        _isLoadingCities = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Städte: $e')),
        );
      }
    }
  }

  // Filter anwenden
  void _applyFilter(String? city) {
    setState(() {
      _selectedCity = city;
      _lastDocument = null;
      _hasMore = true;
      _apartments.clear();
    });
    _loadApartments();
  }

  // Filter-Dialog anzeigen
  void _showFilterDialog() {
    if (_cities.isEmpty && !_isLoadingCities) {
      _loadCities();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stadt-Auswahl
                  if (_isLoadingCities)
                    Column(
                      children: [
                        Text('Lade Städte...'),
                        SizedBox(height: 8),
                        CircularProgressIndicator(),
                      ],
                    )
                  else if (_cities.isEmpty)
                    Column(
                      children: [
                        Text('Keine Städte gefunden'),
                        TextButton(
                          onPressed: _loadCities,
                          child: Text('Erneut versuchen'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: Text('Stadt auswählen (${_cities.length})'),
                      items: _cities
                          .map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _applyFilter(null);
                    Navigator.pop(context);
                  },
                  child: Text('Zurücksetzen'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Anwenden'),
                ),
              ],
            );
          },
        );
      },
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
            _selectedCity != null
                ? 'Keine Apartments in $_selectedCity gefunden'
                : 'Keine Apartments gefunden',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentCard(DocumentSnapshot apartmentDoc) {
    final apartment = apartmentDoc.data() as Map<String, dynamic>;
    final imageUrl = apartment['imageUrls']?.isNotEmpty == true
        ? apartment['imageUrls'][0]
        : null;

    final cleanedAddress = cleanAddress(apartment['addresslong'] ?? '');

    final List<dynamic>? reviews = apartment['reviews'];
    final overallRating = calculateOverallRating(reviews ?? []);

    final valueForMoneyRating = reviews != null && reviews.isNotEmpty
        ? reviews[0]['valueForMoney']?.toDouble() ?? 0.0
        : 0.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApartmentDetailScreen(apartmentDoc: apartmentDoc),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/apartment-placeholder.jpeg',
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/apartment-placeholder.jpeg',
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      cleanedAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    if (overallRating > 0)
                      buildStarRating(overallRating, 'Gesamtbewertung')
                    else
                      Text(
                        'No entries',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    SizedBox(height: 8),
                    if (valueForMoneyRating > 0)
                      buildStarRating(valueForMoneyRating, 'Preis-/Leistung')
                    else
                      Text(
                        'No entries',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apartments'),
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
          if (_selectedCity != null)
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text('Stadt: $_selectedCity'),
                    onDeleted: () {
                      _applyFilter(null);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      _applyFilter(null);
                    },
                    child: Text('Filter löschen'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _applyFilter(_selectedCity);
              },
              child: _apartments.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      padding: EdgeInsets.all(10),
                      itemCount: _apartments.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _apartments.length) {
                          // Loading-Indicator am Ende
                          return _buildLoadingIndicator();
                        }

                        final apartmentDoc = _apartments[index];
                        return _buildApartmentCard(apartmentDoc);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Zeige Tenant Verification vor dem Formular
          final confirmed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantVerificationScreen(
                isApartment: true,
                targetName: 'Neue Wohnung',
              ),
            ),
          );

          // Nur wenn bestätigt, zeige das Formular
          if (confirmed == true) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddApartmentScreen()),
            );
            
            // Wenn eine neue Wohnung erfolgreich erstellt wurde, aktualisiere die Liste
            if (result != null && result is Map && result['success'] == true) {
              // Force refresh der Liste
              _applyFilter(_selectedCity);
            }
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Wohnung hinzufügen',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}