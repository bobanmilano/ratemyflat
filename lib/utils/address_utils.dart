// lib/utils/address_utils.dart
class AddressUtils {
  static String createUniqueAddress(
    String street,
    String houseNumber,
    String additionalInfo,
    String zipCode,
    String city,
    String country,
  ) {
    return '$street $houseNumber $additionalInfo, $zipCode $city, $country'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  static String normalizeStreetName(String street) {
    String normalized = street.trim().toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'strasse|straße|str\.'), 'str');
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), '');
    return normalized;
  }
}