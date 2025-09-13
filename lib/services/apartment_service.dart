// lib/services/apartment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String firebaseId = '';

  /// Prüft, ob eine exakte Duplikat-Wohnung basierend auf normalisierten Adressfeldern existiert.
  static Future<bool> checkForExactDuplicate({
    required String street,
    required String houseNumber,
    required String zipCode,
    required String city,
    required String country,
    String? topStiegeHaus,
  }) async {
    try {
      print('=== ABSOLUTE DUPLIKAT-PRÜFUNG ===');
      print('Suche nach exakter Übereinstimmung:');
      print('  Straße: $street');
      print('  Hausnummer: $houseNumber');
      print('  PLZ: $zipCode');
      print('  Stadt: $city');
      print('  Land: $country');
      print('  Top/Stiege: $topStiegeHaus');

      // Hilfsmethode zur Normalisierung
      String normalize(String text) {
        return text
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s\-äöüß]'), '') // Entferne Sonderzeichen
            .replaceAll(RegExp(r'\s+'), ' ') // Mehrfache Leerzeichen zu einem
            // Normalisiere verschiedene Schreibweisen von "straße"
            .replaceAll(RegExp(r'strasse|straße|str\.?($|\s)'), 'str. ')
            .replaceAll(
              RegExp(r'\s+'),
              ' ',
            ) // Nochmal Leerzeichen normalisieren
            .trim();
      }

      final normalizedStreet = normalize(street);
      final normalizedHouseNumber = normalize(houseNumber);
      final normalizedZipCode = zipCode.trim(); // Keep ZIP code as-is
      final normalizedCity = normalize(city);
      final normalizedCountry = normalize(country);
      final normalizedTopStiegeHaus = normalize(topStiegeHaus ?? '');

      // Query using normalized fields directly
      final querySnapshot = await _firestore
          .collection('apartments')
          .where('normalizedStreet', isEqualTo: normalizedStreet)
          .where('normalizedCity', isEqualTo: normalizedCity)
          .where('normalizedZipCode', isEqualTo: normalizedZipCode)
          .where('normalizedTopStiege', isEqualTo: normalizedTopStiegeHaus)
          .where('normalizedHouseNumber', isEqualTo: normalizedHouseNumber)
          .where('normalizedCountry', isEqualTo: normalizedCountry)
          .get();

      print('Gefundene Kandidaten: ${querySnapshot.docs.length}');

      // Prüfe ob mindestens ein Dokument gefunden wurde
      if (querySnapshot.docs.isNotEmpty) {
        print('EXAKTES DUPLIKAT GEFUNDEN basierend auf normalisierten Werten');
        // Gib die IDs der gefundenen Duplikate aus
        for (var doc in querySnapshot.docs) {
          print('Duplikat-Dokument ID: ${doc.id}');
        }
        firebaseId = querySnapshot.docs.first.id;
        return true; // Duplikat gefunden!
      }

      print('Kein exaktes Duplikat gefunden');
      return false; // Kein exaktes Duplikat
    } catch (e) {
      print('Fehler bei exakter Duplikat-Prüfung: $e');
      return false; // Bei Fehler nicht blockieren
    }
  }

  static String getExistingApartmentId() {
    return firebaseId;
  }
}
