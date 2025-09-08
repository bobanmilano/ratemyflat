// lib/screens/add_landlord_review_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:immo_app/screens/landlord_details_screen.dart'; // Für Zufallsnamen

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
  String _username = '';

  @override
  void initState() {
    super.initState();
    // Generiere einen zufälligen Benutzernamen beim Start
    _username = _generateRandomUsername();
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

  // Methode zum Generieren eines zufälligen Benutzernamens
  String _generateRandomUsername() {
    final random = Random();
    final adjectives = [
      'Cool',
      'Happy',
      'Lucky',
      'Smart',
      'Brave',
      'Fair',
      'Honest',
    ];
    final nouns = [
      'Tenant',
      'Reviewer',
      'User',
      'Mieter',
      'Bewerter',
      'Nutzer',
    ];
    return '${adjectives[random.nextInt(adjectives.length)]}${nouns[random.nextInt(nouns.length)]}';
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

  // 2. Tenant Verification während des Speicherns
  final confirmed = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Bestätigung'),
      content: Text('Bestätigen Sie, dass Sie Kunde dieses Vermieters waren '
                   'und Ihre Angaben wahrheitsgemäß sind?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Bestätigen'),
        ),
      ],
    ),
  );

  if (confirmed != true) return; // User hat abgebrochen

    try {
      // Hole die Firestore-Dokument-ID des Vermieters
      final landlordId = widget.landlordDoc.id;

      if (landlordId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: Vermieter-ID fehlt!')));
        return;
      }

      print('Updating landlord with ID: $landlordId');

      // Speichere die Bewertung im Vermieter-Dokument
      await _firestore.collection('landlords').doc(landlordId).set({
        'reviews': FieldValue.arrayUnion([
          {
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
            'additionalComments': _commentController.text.trim(),
            'username': _username,
            'timestamp': Timestamp.now(),
          },
        ]),
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
      'additionalComments': 'Zusätzliche Kommentare',
      'username': 'Benutzername',
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
            Text(
              '* Pflichtfeld',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Bewertung absenden'),
            ),
          ],
        ),
      ),
    );
  }
}
