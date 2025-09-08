// lib/services/data_processing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/utils/address_utils.dart';

class DataProcessingService {
  Map<String, dynamic> buildApartmentData({
    required Map<String, String> addressData,
    required List<String> imageUrls,
    required Map<String, int> ratings,
    String? landlordId,
    String? landlordName,
  }) {
    final street = addressData['street'] ?? '';
    final houseNumber = addressData['houseNumber'] ?? '';
    final topStiegeHaus = addressData['topStiegeHaus'] ?? '';
    final zipCode = addressData['zipCode'] ?? '';
    final city = addressData['city'] ?? '';
    final country = addressData['country'] ?? 'Deutschland';

    String address =
        '$city, $street $houseNumber, ${topStiegeHaus.isNotEmpty ? "$topStiegeHaus, " : ""}';
    String addressLong =
        '$street $houseNumber, ${topStiegeHaus.isNotEmpty ? "$topStiegeHaus, " : ""}'
        '$zipCode $city, $country';
    String uniqueAddress = AddressUtils.createUniqueAddress(
      street, houseNumber, topStiegeHaus, zipCode, city, country,
    );

    return {
      'address': address,
      'addresslong': addressLong,
      'uniqueAddress': uniqueAddress,
      'street': street,
      'normalizedStreet': AddressUtils.normalizeStreetName(street.trim()),
      'houseNumber': houseNumber,
      'topStiegeHaus': topStiegeHaus,
      'zipCode': zipCode,
      'city': city,
      'country': country,
      'imageUrls': imageUrls,
      'reviews': [_buildReviewData(ratings)],
      if (landlordId != null) 'landlordId': landlordId,
      if (landlordName != null) 'landlordName': landlordName,
    };
  }

  Map<String, dynamic> buildLandlordData({
    required String name,
    required List<String> imageUrls,
    required Map<String, int> ratings,
    required String comments,
    List<String>? apartmentIds,
  }) {
    return {
      'name': name,
      'imageUrls': imageUrls,
      'username': 'Mieter',
      'reviews': [_buildLandlordReviewData(ratings, comments)],
      'createdAt': FieldValue.serverTimestamp(),
      if (apartmentIds != null && apartmentIds.isNotEmpty) 'apartmentIds': apartmentIds,
    };
  }

  Map<String, dynamic> _buildReviewData(Map<String, int> ratings) {
    return {
      ...ratings.map((key, value) => MapEntry(key, value)),
      'timestamp': DateTime.now().toIso8601String(),
      'username': 'Mieter',
    };
  }

  Map<String, dynamic> _buildLandlordReviewData(Map<String, int> ratings, String comments) {
    return {
      ...ratings.map((key, value) => MapEntry(key, value)),
      'timestamp': DateTime.now().toIso8601String(),
      'additionalComments': comments.trim(),
      'username': 'Mieter',
    };
  }

  Future<void> updateLandlordWithApartment(String landlordId, String apartmentId, String landlordName) async {
    await FirebaseFirestore.instance
        .collection('landlords')
        .doc(landlordId)
        .update({
      'apartmentIds': FieldValue.arrayUnion([apartmentId]),
    });
  }

  Future<void> updateApartmentWithLandlord(String apartmentId, String landlordId, String landlordName) async {
    await FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartmentId)
        .update({
      'landlordId': landlordId,
      'landlordName': landlordName,
    });
  }
}