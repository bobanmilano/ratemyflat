// lib/screens/landlord_details_screen.dart
import 'package:flutter/material.dart';
import 'package:immo_app/screens/add_apartment_review_screen.dart';
import 'package:immo_app/screens/apartment_details_screen.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/add_landlord_review_screen.dart';

class LandlordDetailScreen extends StatelessWidget {
  final DocumentSnapshot landlordDoc;

  LandlordDetailScreen({required this.landlordDoc});

  // Methode zur Berechnung der Durchschnittsbewertung für eine Kategorie
  double calculateAverageRating(List<dynamic> reviews, String category) {
    if (reviews == null || reviews.isEmpty) {
      return 0.0;
    }

    double totalSum = 0;
    int count = 0;

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        final rating = review[category]?.toDouble() ?? 0.0;
        totalSum += rating;
        count++;
      }
    }

    return count > 0 ? totalSum / count : 0.0;
  }

  // Methode zur Berechnung der Gesamtbewertung
  double calculateOverallRating(List<dynamic> reviews) {
    if (reviews == null || reviews.isEmpty) {
      return 0.0;
    }

    double totalSum = 0;
    int totalCount = 0;

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        final ratings = {
          'communication': review['communication']?.toDouble() ?? 0.0,
          'helpfulness': review['helpfulness']?.toDouble() ?? 0.0,
          'fairness': review['fairness']?.toDouble() ?? 0.0,
          'transparency': review['transparency']?.toDouble() ?? 0.0,
          'responseTime': review['responseTime']?.toDouble() ?? 0.0,
          'respect': review['respect']?.toDouble() ?? 0.0,
          'renovationManagement': review['renovationManagement']?.toDouble() ?? 0.0,
          'leaseAgreement': review['leaseAgreement']?.toDouble() ?? 0.0,
          'operatingCosts': review['operatingCosts']?.toDouble() ?? 0.0,
          'depositHandling': review['depositHandling']?.toDouble() ?? 0.0,
        };

        totalSum += ratings.values.reduce((a, b) => a + b);
        totalCount += ratings.length;
      }
    }

    return totalCount > 0 ? totalSum / totalCount : 0.0;
  }

  // Methode zur Anzeige der Sternebewertung
  Widget buildStarRating(double rating) {
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
          Icon(Icons.star, color: Colors.orange, size: 24),
        if (fractionalPart == 0.5)
          Icon(Icons.star_half, color: Colors.orange, size: 24),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: Colors.grey, size: 24),
      ],
    );
  }

  // Methode zur Anzeige eines Bildes in voller Größe
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.all(20.0),
              minScale: 0.1,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Bild nicht verfügbar'));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extrahiere die Daten aus dem DocumentSnapshot
    final landlordData = landlordDoc.data() as Map<String, dynamic>;
    final List<dynamic>? reviews = landlordData['reviews'];
    final overallRating = calculateOverallRating(reviews ?? []);

    // Alle Bewertungskategorien für Vermieter
    final categories = [
      'Kommunikation',
      'Hilfsbereitschaft',
      'Fairness',
      'Transparenz',
      'Reaktionszeit',
      'Respekt',
      'Renovierungsmanagement',
      'Mietvertrag',
      'Betriebskosten',
      'Kaution',
    ];

    // Mapping von Kategorien zu Firestore-Feldern
    final categoryMapping = {
      'Kommunikation': 'communication',
      'Hilfsbereitschaft': 'helpfulness',
      'Fairness': 'fairness',
      'Transparenz': 'transparency',
      'Reaktionszeit': 'responseTime',
      'Respekt': 'respect',
      'Renovierungsmanagement': 'renovationManagement',
      'Mietvertrag': 'leaseAgreement',
      'Betriebskosten': 'operatingCosts',
      'Kaution': 'depositHandling',
    };

    // Bilder verarbeiten - LANDLORD DEFAULT-Bild
    final List<dynamic>? imageUrls = landlordData['imageUrls'];
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vermieter Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gallery of Images - MIT LANDLORD-DEFAULT-BILD
              SizedBox(
                height: 200,
                child: hasImages
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls?.length ?? 0,
                        itemBuilder: (context, index) {
                          final imageUrl = imageUrls?[index] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                _showImageDialog(context, imageUrl);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // LANDLORD-DEFAULT-BILD bei Fehler
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/landlord_placeholder.png', // ✅ Korrigiert
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : // Keine Bilder vorhanden - nur LANDLORD-DEFAULT-Bild anzeigen
                    Center(
                        child: GestureDetector(
                          onTap: () {
                            // LANDLORD-DEFAULT-Bild auch im Dialog anzeigen
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: InteractiveViewer(
                                      boundaryMargin: EdgeInsets.all(20.0),
                                      minScale: 0.1,
                                      maxScale: 4.0,
                                      child: Image.asset(
                                        'assets/landlord_placeholder.png', // ✅ Korrigiert
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/landlord_placeholder.png', // ✅ Korrigiert
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 16),

              // Vermieter Name
              Text(
                landlordData['name'] ?? 'Unbekannter Vermieter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Gesamtbewertung
              Text(
                'Gesamtbewertung:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gesamtbewertung:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  buildStarRating(overallRating),
                ],
              ),
              SizedBox(height: 16),

              // Durchschnittsbewertungen
              Text(
                'Einzelbewertungen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...categories.map((category) {
                final fieldName = categoryMapping[category];
                final averageRating = calculateAverageRating(reviews ?? [], fieldName!);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category, style: TextStyle(fontSize: 14, color: Colors.grey)),
                    buildStarRating(averageRating),
                  ],
                );
              }).toList(),
              SizedBox(height: 16),

              // Wohnungen des Vermieters
              _buildApartmentsSection(landlordDoc.id),
              SizedBox(height: 16),

              // Einzelbewertungen
              Text(
                'MIETERKOMMENTARE:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (reviews != null && reviews.isNotEmpty)
                ...reviews.map((review) {
                  final username = review['username'] ?? 'Anonymous';
                  final timestamp = review['timestamp'];
                  final formattedDate = _formatDate(timestamp);
                  final comment = review['additionalComments'] ?? 'Kein Kommentar';
                  final overallRating = calculateOverallRating([review]);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Benutzername und Datum
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                username,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Gesamtbewertung
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gesamtbewertung:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              buildStarRating(overallRating),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Kommentar
                          Text(
                            'Kommentar:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 4),
                          Text(
                            comment,
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList()
              else
                Text(
                  'Noch keine Bewertungen vorhanden.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

              // Bewertung abgeben Button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final landlordData = landlordDoc.data() as Map<String, dynamic>;
                  final landlordName = landlordData['name'] ?? 'Diesen Vermieter';
                  
                  final confirmed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TenantVerificationScreen(
                        isApartment: false, // ✅ Korrekt für Vermieter
                        targetName: landlordName,
                      ),
                    ),
                  );
                  
                  if (confirmed == true) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddLandlordReviewScreen(landlordDoc: landlordDoc),
                      ),
                    );
                    
                    if (result == true) {
                      // Aktualisierung erfolgt automatisch durch StreamBuilder
                    }
                  }
                },
                child: Text('Neue Bewertung verfassen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Methode für Wohnungsliste
  Widget _buildApartmentsSection(String landlordId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wohnungen dieses Vermieters:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('apartments')
              .where('landlordId', isEqualTo: landlordId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Fehler beim Laden der Wohnungen');
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                'Keine Wohnungen gefunden',
                style: TextStyle(color: Colors.grey),
              );
            }

            final apartmentDocs = snapshot.data!.docs;

            return Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: apartmentDocs.length,
                itemBuilder: (context, index) {
                  final apartmentDoc = apartmentDocs[index];
                  final apartment = apartmentDoc.data() as Map<String, dynamic>;
                  
                  // Adresse bereinigen
                  final address = apartment['addresslong'] ?? 'Adresse nicht verfügbar';
                  final imageUrl = apartment['imageUrls']?.isNotEmpty == true
                      ? apartment['imageUrls'][0]
                      : null;

                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(right: 10),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApartmentDetailScreen(apartmentDoc: apartmentDoc),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // APARTMENT-DEFAULT-BILD für Wohnungen
                                        return Image.asset(
                                          'assets/apartment-placeholder.jpeg', // ✅ Korrekt für Wohnungen
                                          height: 80,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/apartment-placeholder.jpeg', // ✅ Korrekt für Wohnungen
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(
                                address.length > 30 
                                    ? '${address.substring(0, 30)}...' 
                                    : address,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Methode zur Formatierung des Datums
  String _formatDate(dynamic timestamp) {
    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unbekanntes Datum';
      }

      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      print('Fehler beim Parsen des Datums: $e');
      return 'Unbekanntes Datum';
    }
  }
}