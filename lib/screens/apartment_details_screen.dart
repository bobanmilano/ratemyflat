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
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        if (label.isNotEmpty)
          SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < fullStars; i++)
              Icon(Icons.star, color: Colors.orange, size: 22),
            if (fractionalPart == 0.5)
              Icon(Icons.star_half, color: Colors.orange, size: 22),
            for (int i = 0; i < emptyStars; i++)
              Icon(Icons.star_border, color: Colors.grey, size: 22),
          ],
        ),
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
    final valueForMoneyRating = reviews != null && reviews.isNotEmpty
        ? reviews[0]['valueForMoney']?.toDouble() ?? 0.0
        : 0.0;

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
      appBar: AppBar(title: Text('Apartment Details'), centerTitle: true),
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

              // ADRESSE ALS CARD MIT LOCATION ICON
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              apartmentData['addresslong'] ??
                                  'Keine Adresse verfügbar',
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
              SizedBox(height: 8),

              // Vermieter-Link (wenn vorhanden)
              if (apartmentData['landlordId'] != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('landlords')
                      .doc(apartmentData['landlordId'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return Text('Vermieter nicht gefunden');
                    }

                    final landlordDoc = snapshot.data!;
                    final landlordData =
                        landlordDoc.data() as Map<String, dynamic>;
                    final landlordName =
                        landlordData['name'] ?? 'Unbekannter Vermieter';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Vermietet von:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          landlordName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LandlordDetailScreen(
                                landlordDoc: landlordDoc,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              SizedBox(height: 16),

              // Hauptüberschrift wie in AboutScreen
              Text(
                'Bewertungsdetails',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16),

              // Gesamtbewertung und Preis-Leistungs-Verhältnis
              _buildInfoCard(
                context,
                icon: Icons.star,
                title: 'Gesamtbewertung',
                content: 'Durchschnittliche Bewertung aller Kategorien',
                rating: overallRating,
              ),
              SizedBox(height: 16),

              _buildInfoCard(
                context,
                icon: Icons.euro,
                title: 'Preis-/Leistung',
                content: 'Verhältnis von Preis zu Leistung',
                rating: valueForMoneyRating,
              ),
              SizedBox(height: 24),

              // Durchschnittsbewertungen
              Text(
                'Einzelbewertungen:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16),
              ...categories.map((category) {
                final fieldName = categoryMapping[category];
                final averageRating = calculateAverageRating(
                  reviews ?? [],
                  fieldName!,
                );
                return _buildRatingCard(
                  context,
                  title: category,
                  rating: averageRating,
                );
              }).toList(),
              SizedBox(height: 24),

              // Einzelbewertungen
              Text(
                'MIETERKOMMENTARE:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16),
              if (reviews != null && reviews.isNotEmpty)
                ...reviews.map((review) {
                  // Extrahiere Review-Daten
                  final username = review['username'] ?? 'Anonymous';
                  final profileImageUrl = review['profileImageUrl'] ?? '';
                  final isAnonymous = review['isAnonymous'] ?? false;
                  final timestamp = review['timestamp'];
                  final formattedDate = _formatDate(timestamp);
                  final comment = review['additionalComments'] ?? 'Kein Kommentar';
                  
                  // Berechne Bewertungen für diese Review
                  final overallRating = calculateOverallRating([review]);
                  final valueForMoneyRating = review['valueForMoney']?.toDouble() ?? 0.0;
                  final landlordRating = review['landlord']?.toDouble() ?? 0.0;

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

                          // Bewertungen
                          _buildReviewRating(
                            context,
                            'Gesamtbewertung',
                            overallRating,
                          ),
                          SizedBox(height: 8),
                          _buildReviewRating(
                            context,
                            'Preis-/Leistung',
                            valueForMoneyRating,
                          ),
                          SizedBox(height: 8),
                          _buildReviewRating(
                            context,
                            'Vermieter',
                            landlordRating,
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
                _buildEmptyStateCard(
                  context,
                  icon: Icons.comment_outlined,
                  title: 'Keine Bewertungen',
                  message:
                      'Dieses Apartment wurde noch nicht bewertet.\nSeien Sie der Erste, der eine Bewertung abgibt!',
                ),

              // Bewertung abgeben Button - MIT Tenant Verification
              SizedBox(height: 24),
              _buildActionCard(
                context,
                icon: Icons.add_comment,
                title: 'Neue Bewertung erstellen',
                message: 'Teilen Sie Ihre Erfahrung mit anderen Mietern',
                buttonText: 'Bewertung erstellen',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddApartmentReviewScreen(apartmentDoc: apartmentDoc),
                    ),
                  );

                  // Wenn eine Bewertung erfolgreich abgegeben wurde, aktualisiere die Liste
                  if (result != null &&
                      result is Map &&
                      result['success'] == true) {
                    // Die StreamBuilder aktualisieren automatisch
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Neue Helper-Methoden für konsistentes Design
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required double rating,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Center(child: buildStarRating(rating, '')),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(
    BuildContext context, {
    required String title,
    required double rating,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(child: buildStarRating(rating, '')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRating(BuildContext context, String title, double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        buildStarRating(rating, ''),
      ],
    );
  }

  Widget _buildEmptyStateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity, // Volle Breite
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(buttonText, style: TextStyle(fontSize: 16)),
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