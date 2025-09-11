// lib/services/apartment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/utils/address_utils.dart';

class ApartmentService {
  // In der ApartmentService.dart - füge Debugging hinzu:

  static Future<bool> checkForDuplicate({
    required String street,
    required String houseNumber,
    required String topStiegeHaus,
    required String zipCode,
    required String city,
    required String country,
  }) async {

    final normalizedStreet = AddressUtils.normalizeStreetName(street);


    try {
      Query query = FirebaseFirestore.instance
          .collection('apartments')
          .where('normalizedStreet', isEqualTo: normalizedStreet)
          .where('houseNumber', isEqualTo: houseNumber)
          .where('zipCode', isEqualTo: zipCode)
          .where('city', isEqualTo: city)
          .where('country', isEqualTo: country);

      if (topStiegeHaus.isNotEmpty) {
        query = query.where('topStiegeHaus', isEqualTo: topStiegeHaus);
      }

      final querySnapshot = await query.get();
      final isDuplicate = querySnapshot.docs.isNotEmpty;


      return isDuplicate;
    } catch (e) {
      print('Fehler in checkForDuplicate: $e');
      return false;
    }
  }

  static Future<String?> getExistingApartmentId({
    required String street,
    required String houseNumber,
    required String topStiegeHaus,
    required String zipCode,
    required String city,
    required String country,
  }) async {
    final normalizedStreet = AddressUtils.normalizeStreetName(street);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('apartments')
        .where('normalizedStreet', isEqualTo: normalizedStreet)
        .where('houseNumber', isEqualTo: houseNumber)
        .where('zipCode', isEqualTo: zipCode)
        .where('city', isEqualTo: city)
        .where('country', isEqualTo: country)
        .where('topStiegeHaus', isEqualTo: topStiegeHaus)
        .get();

    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
  }
}
