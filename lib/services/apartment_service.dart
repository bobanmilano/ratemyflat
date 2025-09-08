// lib/services/apartment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/utils/address_utils.dart';

class ApartmentService {
  static Future<bool> checkForDuplicate({
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

    return querySnapshot.docs.isNotEmpty;
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