// lib/services/form_validation_service.dart
class FormValidationService {
  bool validateApartmentFields({
    required String street,
    required String houseNumber,
    required String zipCode,
    required String city,
    required String comments,
  }) {
    return street.trim().isNotEmpty &&
           houseNumber.trim().isNotEmpty &&
           zipCode.trim().isNotEmpty &&
           city.trim().isNotEmpty &&
           comments.trim().length >= 20 &&
           comments.trim().length <= 800;
  }

  bool validateLandlordFields({
    required String name,
    required String comments,
  }) {
    return name.trim().isNotEmpty &&
           comments.trim().length >= 20 &&
           comments.trim().length <= 800;
  }

  List<String> getMissingApartmentFields({
    required String street,
    required String houseNumber,
    required String zipCode,
    required String city,
    required String comments,
  }) {
    List<String> missing = [];

    if (street.trim().isEmpty) missing.add('Straße');
    if (houseNumber.trim().isEmpty) missing.add('Hausnummer');
    if (zipCode.trim().isEmpty) missing.add('PLZ');
    if (city.trim().isEmpty) missing.add('Stadt');
    if (comments.trim().isEmpty) {
      missing.add('Kommentar (mindestens 20 Zeichen)');
    } else if (comments.trim().length < 20) {
      missing.add('Kommentar zu kurz (mindestens 20 Zeichen)');
    } else if (comments.trim().length > 800) {
      missing.add('Kommentar zu lang (max. 800 Zeichen)');
    }

    return missing;
  }

  List<String> getMissingLandlordFields({
    required String name,
    required String comments,
  }) {
    List<String> missing = [];

    if (name.trim().isEmpty) missing.add('Vermietername');
    if (comments.trim().isEmpty) {
      missing.add('Kommentar (mindestens 20 Zeichen)');
    } else if (comments.trim().length < 20) {
      missing.add('Kommentar zu kurz (mindestens 20 Zeichen)');
    } else if (comments.trim().length > 800) {
      missing.add('Kommentar zu lang (max. 800 Zeichen)');
    }

    return missing;
  }
}