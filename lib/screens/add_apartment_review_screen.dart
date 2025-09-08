import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:immo_app/screens/apartment_details_screen.dart'; // Für Zufallsnamen

class AddApartmentReviewScreen extends StatefulWidget {
  final DocumentSnapshot apartmentDoc;

  AddApartmentReviewScreen({required this.apartmentDoc});

  @override
  _AddApartmentReviewScreenState createState() => _AddApartmentReviewScreenState();
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

  // Methode zum Generieren eines zufälligen Benutzernamens
  String _generateRandomUsername() {
    final random = Random();
    final adjectives = ['Cool', 'Happy', 'Lucky', 'Smart', 'Brave'];
    final nouns = ['User', 'Reviewer', 'Explorer', 'Adventurer', 'Fan'];
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
        content: Text('Bitte korrigieren Sie folgende Felder:\n• ${missingFields.join('\n• ')}'),
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
      content: Text('Bestätigen Sie, dass Sie Mieter dieser Wohnung waren '
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
    // Hole die Firestore-Dokument-ID des Apartments
    final apartmentId = widget.apartmentDoc.id;

    if (apartmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: Apartment-ID fehlt!')),
      );
      return;
    }

    print('Updating apartment with ID: $apartmentId');

    // Speichere die Bewertung im Apartment-Dokument
    await _firestore.collection('apartments').doc(apartmentId).set({
      'reviews': FieldValue.arrayUnion([
        {
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
          'additionalComments': _commentController.text.trim(),
          'username': _username,
          'timestamp': Timestamp.now(),
        }
      ]),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bewertung erfolgreich abgegeben!')),
    );

    // Holen des aktualisierten Dokuments
    final updatedDoc = await _firestore.collection('apartments').doc(apartmentId).get();
    
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
      'additionalComments': 'Zusätzliche Kommentare',
      'username': 'Benutzername',
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
            ..._ratings.keys.map((key) {
              final categoryName = categoryMapping[key];
              return Column(
                children: [
                  Center(
                    child: Text(
                      categoryName ?? key,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 4), // Reduzierter Abstand zwischen Label und Sternen
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