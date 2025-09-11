import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/apartment_details_screen.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';
import 'package:immo_app/services/rate_limit_service.dart'; // Für Zufallsnamen

class AddApartmentReviewScreen extends StatefulWidget {
  final DocumentSnapshot apartmentDoc;

  AddApartmentReviewScreen({required this.apartmentDoc});

  @override
  _AddApartmentReviewScreenState createState() =>
      _AddApartmentReviewScreenState();
}

class _AddApartmentReviewScreenState extends State<AddApartmentReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, double> _ratings = {
    'accessibility': 1.0,
    'cleanliness': 1.0,
    'condition': 1.0,
    'equipment': 1.0,
    'landlord': 1.0,
    'leisure': 1.0,
    'location': 1.0,
    'neighbors': 1.0,
    'parking': 1.0,
    'safety': 1.0,
    'shopping': 1.0,
    'transport': 1.0,
    'valueForMoney': 1.0,
  };
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  String _userId = 'anonymous';
  String _username = 'Anonymous';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Lade die Daten des eingeloggten Users
  Future<void> _loadCurrentUser() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _userId = currentUser.uid;
      });

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _username =
                userData?['username'] ??
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Mieter';
            _profileImageUrl = userData?['profileImageUrl'] ?? '';
          });
        } else {
          // Fallback zu Firebase Auth Daten
          setState(() {
            _username =
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Mieter';
          });
        }
      } catch (e) {
        print('Fehler beim Laden der User-Daten: $e');
        // Fallback
        setState(() {
          _username =
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Mieter';
        });
      }
    }
  }

  // Methode zum Aktualisieren der Bewertung für eine Kategorie
  void _updateRating(String category, double value) {
    setState(() {
      _ratings[category] = value;
    });
  }

  // Methode zur Anzeige der Sternebewertung
  Widget buildStarRating(String category) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Sterne zentrieren
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return IconButton(
          icon: Icon(
            _ratings[category]! >= starValue
                ? Icons.star
                : _ratings[category]! >= starValue - 0.5
                ? Icons.star_half
                : Icons.star_border,
            color: Colors.orange,
            size: 32,
          ),
          onPressed: () {
            _updateRating(category, starValue);
          },
        );
      }),
    );
  }

  // Validierung der Eingabefelder
  bool _validateFields() {
    final String comment = _commentController.text.trim();
    final bool isCommentValid = comment.length >= 20 && comment.length <= 800;
    return isCommentValid;
  }

  List<String> _getMissingFields() {
    List<String> missing = [];
    final String comment = _commentController.text.trim();

    if (comment.isEmpty) {
      missing.add('Kommentar (mindestens 20 Zeichen)');
    } else if (comment.length < 20) {
      missing.add('Kommentar zu kurz (mindestens 20 Zeichen)');
    } else if (comment.length > 800) {
      missing.add('Kommentar zu lang (max. 800 Zeichen)');
    }

    return missing;
  }

  void _submitReview() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final canReview = await RateLimitService.canUserSubmitReview(
      currentUser.uid,
    );
    if (!canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bewertungslimit erreicht: Maximal 8 Bewertungen pro Tag',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validiere die Eingaben
    if (!_validateFields()) {
      final missingFields = _getMissingFields();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bitte korrigieren Sie folgende Felder:\n• ${missingFields.join('\n• ')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TenantVerificationScreen(
          isApartment: true,
          targetName:
              "${(widget.apartmentDoc.data() as Map<String, dynamic>)['address'] ?? ''}",
        ),
      ),
    );

    if (confirmed != true) return; // User hat abgebrochen

    try {
      // Hole die Firestore-Dokument-ID des Apartments
      final apartmentId = widget.apartmentDoc.id;

      if (apartmentId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: Apartment-ID fehlt!')));
        return;
      }

      print('Updating apartment with ID: $apartmentId');

      // Erstelle die Review-Daten mit echten User-Informationen
      final reviewData = {
        'userId': _userId,
        'username': _isAnonymous ? 'Anonymous' : _username,
        'profileImageUrl': _isAnonymous ? '' : _profileImageUrl,
        'isAnonymous': _isAnonymous,
        'timestamp': DateTime.now(),
        'additionalComments': _commentController.text.trim(),
        // Alle Bewertungskategorien
        'accessibility': _ratings['accessibility'],
        'cleanliness': _ratings['cleanliness'],
        'condition': _ratings['condition'],
        'equipment': _ratings['equipment'],
        'landlord': _ratings['landlord'],
        'leisure': _ratings['leisure'],
        'location': _ratings['location'],
        'neighbors': _ratings['neighbors'],
        'parking': _ratings['parking'],
        'safety': _ratings['safety'],
        'shopping': _ratings['shopping'],
        'transport': _ratings['transport'],
        'valueForMoney': _ratings['valueForMoney'],
      };

      // Speichere die Bewertung im Apartment-Dokument
      await _firestore.collection('apartments').doc(apartmentId).set({
        'reviews': FieldValue.arrayUnion([reviewData]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bewertung erfolgreich abgegeben!')),
      );

      // Holen des aktualisierten Dokuments
      final updatedDoc = await _firestore
          .collection('apartments')
          .doc(apartmentId)
          .get();

      // Zurück zur Liste navigieren
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Und dann direkt zur aktualisierten Detailseite
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApartmentDetailScreen(apartmentDoc: updatedDoc),
        ),
      );
    } catch (e) {
      print('Fehler beim Speichern der Bewertung: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern der Bewertung: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mapping von Kategorien zu lesbaren Namen
    final categoryMapping = {
      'accessibility': 'Barrierefreiheit',
      'cleanliness': 'Sauberkeit im Gebäude',
      'condition': 'Zustand der Wohnung',
      'equipment': 'Ausstattung',
      'landlord': 'Vermieter',
      'leisure': 'Freizeitmöglichkeiten',
      'location': 'Lage',
      'neighbors': 'Nachbarn',
      'parking': 'Parkmöglichkeiten',
      'safety': 'Sicherheit',
      'shopping': 'Einkaufsmöglichkeiten',
      'transport': 'Anbindung an öffentliche Verkehrsmittel',
      'valueForMoney': 'Preis-/Leistung',
    };

    // Extrahiere die Adresse aus den Apartment-Daten
    final apartmentData = widget.apartmentDoc.data() as Map<String, dynamic>;
    final address = apartmentData['addresslong'] ?? 'Unbekannte Adresse';

    return Scaffold(
      appBar: AppBar(title: Text('Bewertung abgeben')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deine Bewertung für:\n$address:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // User-Info Card (wenn nicht anonym)
            if (!_isAnonymous)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Profilbild
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _profileImageUrl.isNotEmpty
                            ? NetworkImage(_profileImageUrl)
                            : null,
                        child: _profileImageUrl.isEmpty
                            ? Icon(Icons.person, size: 20)
                            : null,
                      ),
                      SizedBox(width: 12),
                      // Username
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bewertung von:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _username,
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

            ..._ratings.keys.map((key) {
              final categoryName = categoryMapping[key];
              return Column(
                children: [
                  Center(
                    child: Text(
                      categoryName ?? key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  buildStarRating(key),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),

            // Verbessertes Kommentarfeld
            Text(
              'Zusätzliche Kommentare *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: null, // Dynamische Höhe
              minLines: 4,
              maxLength: 800,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Kommentar *',
                hintText: 'Beschreiben Sie Ihre Erfahrung mit der Wohnung...',
                alignLabelWithHint: true,
                helperText: 'Mindestens 20, maximal 800 Zeichen',
              ),
            ),
            SizedBox(height: 8),

            // Anonymität-Option
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Anonym bewerten'),
                      subtitle: Text(
                        _isAnonymous
                            ? 'Ihr Name und Profilbild werden nicht angezeigt'
                            : 'Ihr Name und Profilbild werden öffentlich sichtbar',
                      ),
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                      secondary: Icon(
                        _isAnonymous ? Icons.visibility_off : Icons.visibility,
                        color: _isAnonymous
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    if (_isAnonymous)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ihre Bewertung wird anonym veröffentlicht. Sie hilft anderen Mietern, ohne Ihre Identität preiszugeben.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
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
            Text(
              '* Pflichtfeld',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                child: Text(
                  'Bewertung absenden',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
