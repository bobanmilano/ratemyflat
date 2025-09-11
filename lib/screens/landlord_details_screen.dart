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
          'communication': review['communication']?.toDouble() ?? 0.0,
          'helpfulness': review['helpfulness']?.toDouble() ?? 0.0,
          'fairness': review['fairness']?.toDouble() ?? 0.0,
          'transparency': review['transparency']?.toDouble() ?? 0.0,
          'responseTime': review['responseTime']?.toDouble() ?? 0.0,
          'respect': review['respect']?.toDouble() ?? 0.0,
          'renovationManagement':
              review['renovationManagement']?.toDouble() ?? 0.0,
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
    final landlordData = landlordDoc.data() as Map<String, dynamic>;
    final List<dynamic>? reviews = landlordData['reviews'];
    final overallRating = calculateOverallRating(reviews ?? []);
    final valueForMoneyRating = calculateAverageRating(
      reviews ?? [],
      'valueForMoney',
    );
    final landlordRating = calculateAverageRating(reviews ?? [], 'landlord');

    // Alle Bewertungskategorien
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

    // Bilder verarbeiten
    final List<dynamic>? imageUrls = landlordData['imageUrls'];
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    final firstImageUrl = hasImages ? imageUrls![0] : null;

    return Scaffold(
      appBar: AppBar(title: Text('Vermieter Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery of Images - MIT CONSISTENT DESIGN
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
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/landlord_placeholder.png',
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
                  : Center(
                      child: GestureDetector(
                        onTap: () {
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
                                      'assets/landlord_placeholder.png',
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
                            'assets/landlord_placeholder.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 16),

            // VERMIETER-ADRESSE ALS CARD MIT LOCATION ICON
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
            
                          SizedBox(height: 8),
                          Text(
                            landlordData['name'] ?? 'Unbekannter Vermieter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Gesamtbewertung und Preis-Leistungs-Verhältnis
            Text(
              'Gesamtbewertung:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Durchschnitt:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                buildStarRating(overallRating),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preis-/Leistung:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                buildStarRating(valueForMoneyRating),
              ],
            ),
            SizedBox(height: 16),

            // Durchschnittsbewertungen
            Text(
              'Einzelbewertungen:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...categories.map((category) {
              final fieldName = categoryMapping[category];
              final averageRating = calculateAverageRating(
                reviews ?? [],
                fieldName!,
              );
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      buildStarRating(averageRating),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ), // Verdoppelter Abstand (vorher 12, jetzt 24)
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
                // Extrahiere Review-Daten
                final username = review['username'] ?? 'Anonymous';
                final profileImageUrl = review['profileImageUrl'] ?? '';
                final isAnonymous = review['isAnonymous'] ?? false;
                final timestamp = review['timestamp'];
                final formattedDate = _formatDate(timestamp);
                final comment = review['additionalComments'] ?? 'Kein Kommentar';
                final overallRating = calculateOverallRating([review]);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Benutzerheader mit Profilbild
                        Row(
                          children: [
                            // Profilbild
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: profileImageUrl.isNotEmpty && !isAnonymous
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty || isAnonymous
                                  ? Icon(Icons.person, size: 20)
                                  : null,
                            ),
                            SizedBox(width: 12),
                            // Username und Datum
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAnonymous ? 'Anonymous' : username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Anonym-Indikator
                            if (isAnonymous)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Anonym',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Gesamtbewertung
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gesamtbewertung:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            buildStarRating(overallRating),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Kommentar
                        if (comment.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comment,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Keine Bewertungen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Dieser Vermieter wurde noch nicht bewertet.\nSeien Sie der Erste, der eine Bewertung abgibt!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

            // Bewertung abgeben Button - MIT TENANT VERIFICATION
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final landlordData = landlordDoc.data() as Map<String, dynamic>;
                  final landlordName = landlordData['name'] ?? 'Diesen Vermieter';

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddLandlordReviewScreen(landlordDoc: landlordDoc),
                    ),
                  );

                  // Wenn eine Bewertung erfolgreich abgegeben wurde, aktualisiere die Ansicht
                  if (result != null &&
                      result is Map &&
                      result['success'] == true) {
                    // Die StreamBuilder aktualisieren automatisch
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Neue Bewertung verfassen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Methode zur Anzeige der Wohnungen des Vermieters
  Widget _buildApartmentsSection(String landlordId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wohnungen dieses Vermieters:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('apartments')
              .where('landlordId', isEqualTo: landlordId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Text('Fehler beim Laden der Wohnungen');
            }

            if (snapshot.data!.docs.isEmpty) {
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
                  final address =
                      apartment['addresslong'] ?? 'Adresse nicht verfügbar';
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
                              builder: (context) => ApartmentDetailScreen(
                                apartmentDoc: apartmentDoc,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/apartment-placeholder.jpeg',
                                          height: 80,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/apartment-placeholder.jpeg',
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
        // Firestore Timestamp
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        // String-Datum
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        // DateTime-Objekt
        dateTime = timestamp;
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