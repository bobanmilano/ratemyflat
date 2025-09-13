// lib/screens/add_landlord_review_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:immo_app/screens/landlord_details_screen.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';
import 'package:immo_app/services/rate_limit_service.dart'; // Für Zufallsnamen

class AddLandlordReviewScreen extends StatefulWidget {
  final DocumentSnapshot landlordDoc;

  AddLandlordReviewScreen({required this.landlordDoc});

  @override
  _AddLandlordReviewScreenState createState() =>
      _AddLandlordReviewScreenState();
}

class _AddLandlordReviewScreenState extends State<AddLandlordReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, double> _ratings = {
    'communication': 1.0, // Kommunikation
    'helpfulness': 1.0, // Hilfsbereitschaft
    'fairness': 1.0, // Fairness
    'transparency': 1.0, // Transparenz
    'responseTime': 1.0, // Reaktionszeit
    'respect': 1.0, // Respekt
    'renovationManagement': 1.0, // Renovierungsmanagement
    'leaseAgreement': 1.0, // Mietvertrag
    'operatingCosts': 1.0, // Betriebskosten
    'depositHandling': 1.0, // Kaution
  };
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false; // Neue Variable für Anonymität

  // User-Daten
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
      mainAxisAlignment: MainAxisAlignment.center,
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

  // ✅ NEU: Prüfe ob User bereits bewertet hat
  final landlordId = widget.landlordDoc.id;
  final userId = currentUser.uid;
  
  try {
    final landlordDoc = await _firestore.collection('landlords').doc(landlordId).get();
    if (landlordDoc.exists) {
      final landlordData = landlordDoc.data();
      final List<dynamic>? existingReviews = landlordData?['reviews'];
      
      if (existingReviews != null) {
        final hasAlreadyReviewed = existingReviews.any((review) {
          final reviewMap = review as Map<String, dynamic>;
          return reviewMap['userId'] == userId;
        });
        
        if (hasAlreadyReviewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sie haben diesen Vermieter bereits bewertet!'),
              backgroundColor: Colors.orange,
            ),
          );
          // Zurück zur Liste navigieren
          await Future.delayed(Duration(seconds: 2));
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
      }
    }
  } catch (e) {
    print('Fehler bei der Prüfung auf vorhandene Bewertung: $e');
    // Bei Fehler fortfahren, um User nicht zu blockieren
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
        isApartment: false, // ✅ Korrekt für Vermieter
        targetName:
            "${(widget.landlordDoc.data() as Map<String, dynamic>)['name'] ?? ''}",
      ),
    ),
  );

  if (confirmed != true) return; // User hat abgebrochen

  try {
    if (landlordId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler: Vermieter-ID fehlt!')));
      return;
    }

    print('Updating landlord with ID: $landlordId');

    // Erstelle die Review-Daten mit echten User-Informationen
    final reviewData = {
      'userId': userId, // ✅ Verwende die userId Variable
      'username': _isAnonymous ? 'Anonymous' : _username,
      'profileImageUrl': _isAnonymous ? '' : _profileImageUrl,
      'isAnonymous': _isAnonymous,
      'timestamp': DateTime.now(),
      'additionalComments': _commentController.text.trim(),
      // Alle Bewertungskategorien
      'communication': _ratings['communication'],
      'helpfulness': _ratings['helpfulness'],
      'fairness': _ratings['fairness'],
      'transparency': _ratings['transparency'],
      'responseTime': _ratings['responseTime'],
      'respect': _ratings['respect'],
      'renovationManagement': _ratings['renovationManagement'],
      'leaseAgreement': _ratings['leaseAgreement'],
      'operatingCosts': _ratings['operatingCosts'],
      'depositHandling': _ratings['depositHandling'],
    };

    // Speichere die Bewertung im Vermieter-Dokument
    await _firestore.collection('landlords').doc(landlordId).set({
      'reviews': FieldValue.arrayUnion([reviewData]),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bewertung erfolgreich abgegeben!')),
    );

    // Holen des aktualisierten Dokuments
    final updatedDoc = await _firestore
        .collection('landlords')
        .doc(landlordId)
        .get();

    // Zurück zur Liste navigieren
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Und dann direkt zur aktualisierten Detailseite
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandlordDetailScreen(landlordDoc: updatedDoc),
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
      'communication': 'Kommunikation',
      'helpfulness': 'Hilfsbereitschaft',
      'fairness': 'Fairness',
      'transparency': 'Transparenz',
      'responseTime': 'Reaktionszeit',
      'respect': 'Respekt',
      'renovationManagement': 'Renovierungsmanagement',
      'leaseAgreement': 'Mietvertrag',
      'operatingCosts': 'Betriebskosten',
      'depositHandling': 'Kaution',
    };

    // Extrahiere den Vermieter-Namen aus den Daten
    final landlordData = widget.landlordDoc.data() as Map<String, dynamic>;
    final landlordName = landlordData['name'] ?? 'Unbekannter Vermieter';

    return Scaffold(
      appBar: AppBar(title: Text('Bewertung abgeben')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deine Bewertung für $landlordName:',
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
              maxLines: null,
              minLines: 4,
              maxLength: 800,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Kommentar *',
                hintText: 'Beschreiben Sie Ihre Erfahrung mit dem Vermieter...',
                alignLabelWithHint: true,
                helperText: 'Mindestens 20, maximal 800 Zeichen',
              ),
            ),
            SizedBox(height: 16),

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
                          _isAnonymous = value ?? false;
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
