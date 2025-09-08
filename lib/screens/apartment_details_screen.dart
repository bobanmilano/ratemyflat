// lib/screens/apartment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Für Datumformatierung
import 'package:cloud_firestore/cloud_firestore.dart'; // Für Timestamp
import 'package:immo_app/screens/add_apartment_review_screen.dart'; // Import für AddApartmentReviewScreen
import 'package:immo_app/screens/landlord_details_screen.dart'; // Import für LandlordDetailScreen
import 'package:immo_app/screens/tenant_verification_screen.dart'; // Import für TenantVerificationScreen

class ApartmentDetailScreen extends StatelessWidget {
  final DocumentSnapshot apartmentDoc;

  ApartmentDetailScreen({required this.apartmentDoc});

  // Methode zur Berechnung der Durchschnittsbewertung für eine Kategorie
  double calculateAverageRating(List<dynamic> reviews, String category) {
    if (reviews == null || reviews.isEmpty) {
      return 0.0; // Keine Bewertungen vorhanden
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

  // Methode zur Berechnung der Gesamtbewertung (Durchschnitt aller Kategorien)
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
        for (int i = 0; i < fullStars; i++) Icon(Icons.star, color: Colors.orange, size: 24),
        if (fractionalPart == 0.5) Icon(Icons.star_half, color: Colors.orange, size: 24),
        for (int i = 0; i < emptyStars; i++) Icon(Icons.star_border, color: Colors.grey, size: 24),
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
              Navigator.pop(context); // Schließe den Dialog beim Tippen
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
    final apartmentData = apartmentDoc.data() as Map<String, dynamic>;
    final List<dynamic>? reviews = apartmentData['reviews'];
    final overallRating = calculateOverallRating(reviews ?? []);
    final valueForMoneyRating = calculateAverageRating(reviews ?? [], 'valueForMoney');
    final landlordRating = calculateAverageRating(reviews ?? [], 'landlord');

    // Alle Bewertungskategorien
    final categories = [
      'Preis-/Leistung',
      'Vermieter',
      'Barrierefreiheit',
      'Sauberkeit im Gebäude',
      'Zustand der Wohnung',
      'Ausstattung',
      'Freizeitmöglichkeiten',
      'Lage',
      'Nachbarn',
      'Parkmöglichkeiten',
      'Sicherheit',
      'Einkaufsmöglichkeiten',
      'Anbindung an öffentliche Verkehrsmittel',
    ];

    // Mapping von Kategorien zu Firestore-Feldern
    final categoryMapping = {
      'Preis-/Leistung': 'valueForMoney',
      'Vermieter': 'landlord',
      'Barrierefreiheit': 'accessibility',
      'Sauberkeit im Gebäude': 'cleanliness',
      'Zustand der Wohnung': 'condition',
      'Ausstattung': 'equipment',
      'Freizeitmöglichkeiten': 'leisure',
      'Lage': 'location',
      'Nachbarn': 'neighbors',
      'Parkmöglichkeiten': 'parking',
      'Sicherheit': 'safety',
      'Einkaufsmöglichkeiten': 'shopping',
      'Anbindung an öffentliche Verkehrsmittel': 'transport',
    };

    // Bilder verarbeiten - Default-Bild wenn keine vorhanden
    final List<dynamic>? imageUrls = apartmentData['imageUrls'];
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Apartment Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gallery of Images - mit Default-Bild
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
                                    // Auch bei Netzwerkfehlern Default-Bild anzeigen
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/apartment-placeholder.jpeg',
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
                    : // Keine Bilder vorhanden - nur Default-Bild anzeigen
                    Center(
                        child: GestureDetector(
                          onTap: () {
                            // Default-Bild auch im Dialog anzeigen
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
                                        'assets/apartment-placeholder.jpeg',
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
                              'assets/apartment-placeholder.jpeg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 16),

              // Address
              Text(
                apartmentData['addresslong'] ?? 'Keine Adresse verfügbar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Vermieter-Link (wenn vorhanden)
              if (apartmentData['landlordId'] != null) ...[
                Text(
                  'Vermieter:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('landlords')
                      .doc(apartmentData['landlordId'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return Text('Vermieter nicht gefunden');
                    }

                    final landlordDoc = snapshot.data!;
                    final landlordData = landlordDoc.data() as Map<String, dynamic>;
                    final landlordName = landlordData['name'] ?? 'Unbekannter Vermieter';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        title: Text(
                          landlordName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LandlordDetailScreen(landlordDoc: landlordDoc),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
              ],

              // Gesamtbewertung und Preis-Leistungs-Verhältnis
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
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preis-/Leistung:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  buildStarRating(valueForMoneyRating),
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
                  final valueForMoneyRating = review['valueForMoney']?.toDouble() ?? 0.0;
                  final landlordRating = review['landlord']?.toDouble() ?? 0.0;

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
                          SizedBox(height: 4),

                          // Preis-Leistungs-Verhältnis
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Preis-/Leistung:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              buildStarRating(valueForMoneyRating),
                            ],
                          ),
                          SizedBox(height: 4),

                          // Vermieter-Bewertung
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Vermieter:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              buildStarRating(landlordRating),
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
                  'No reviews available.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

              // Bewertung abgeben Button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final confirmed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TenantVerificationScreen(
                        isApartment: true,
                        targetName: apartmentData['addresslong'] ?? 'Diese Wohnung',
                      ),
                    ),
                  );
                  
                  if (confirmed == true) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddApartmentReviewScreen(apartmentDoc: apartmentDoc),
                      ),
                    );
                    
                    // Wenn eine Bewertung erfolgreich abgegeben wurde, aktualisiere die Ansicht
                    if (result == true) {
                      // Die StreamBuilder aktualisieren automatisch
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

  // Methode zur Formatierung des Datums
  String _formatDate(dynamic timestamp) {
    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        // Firestore Timestamp
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        // String-Datum
        dateTime = DateTime.parse(timestamp);
      } else {
        // Fallback, falls das Datum ungültig ist
        return 'Unbekanntes Datum';
      }

      // Formatieren des Datums
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      // Fehlerbehandlung bei ungültigen Daten
      print('Fehler beim Parsen des Datums: $e');
      return 'Unbekanntes Datum';
    }
  }
}