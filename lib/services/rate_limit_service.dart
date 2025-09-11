// lib/services/rate_limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateLimitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Erweiterte Rate-Limiting-Funktion MIT Composite-Index
  static Future<Map<String, bool>> checkUserLimits(
    String userId, {
    String? actionType,
  }) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(Duration(days: 1));
      final oneWeekAgo = now.subtract(Duration(days: 7));

      final limits = {
        'canCreateApartment': true,
        'canCreateLandlord': true,
        'canSubmitReview': true,
        'canChangeProfileImage': true,
      };

      // Wohnungserstellung limitieren (max 3 pro Woche) - MIT Index
      if (actionType == 'create_apartment' || actionType == null) {
        try {
          final apartmentSnapshot = await _firestore
              .collection('apartments')
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThan: oneWeekAgo)
              .get();

          print(
            'User $userId hat ${apartmentSnapshot.docs.length} Apartments diese Woche',
          );
          if (apartmentSnapshot.docs.length >= 3) {
            limits['canCreateApartment'] = false;
          }
        } catch (e) {
          print('Fehler beim Prüfen der Wohnungslimits: $e');
        }
      }

      // Vermietererstellung limitieren (max 5 pro Woche) - MIT Index
      if (actionType == 'create_landlord' || actionType == null) {
        try {
          final landlordSnapshot = await _firestore
              .collection('landlords')
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThan: oneWeekAgo)
              .get();

          print(
            'User $userId hat ${landlordSnapshot.docs.length} Vermieter diese Woche',
          );
          if (landlordSnapshot.docs.length >= 5) {
            limits['canCreateLandlord'] = false;
          }
        } catch (e) {
          print('Fehler beim Prüfen der Vermieterlimits: $e');
        }
      }

      // Bewertungslimit (max 8 pro Tag) - AUS APARTMENTS UND LANDLORDS
      if (actionType == 'submit_review' || actionType == null) {
        try {
          int totalReviewsToday = 0;

          // Zähle Reviews aus Apartments
          final apartmentSnapshot = await _firestore
              .collection('apartments')
              .where('userId', isEqualTo: userId)
              .get();

          totalReviewsToday += _countReviewsInDocuments(
            apartmentSnapshot.docs,
            oneDayAgo,
          );

          // Zähle Reviews aus Vermietern (falls Limit noch nicht erreicht)
          if (totalReviewsToday < 8) {
            final landlordSnapshot = await _firestore
                .collection('landlords')
                .where('userId', isEqualTo: userId)
                .get();

            totalReviewsToday += _countReviewsInDocuments(
              landlordSnapshot.docs,
              oneDayAgo,
            );
          }

          print('User $userId hat $totalReviewsToday Bewertungen heute');
          if (totalReviewsToday >= 8) {
            limits['canSubmitReview'] = false;
          }
        } catch (e) {
          print('Fehler beim Prüfen der Bewertungslimits: $e');
        }
      }

      // Profilbild-Änderung limitieren (max 1 pro Woche)
      if (actionType == 'change_profile_image' || actionType == null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            if (userData != null &&
                userData.containsKey('lastProfileImageChange') &&
                userData['lastProfileImageChange'] != null) {
              final lastChange = _getDateTimeFromFirestore(
                userData['lastProfileImageChange'],
              );
              if (lastChange != null && lastChange.isAfter(oneWeekAgo)) {
                limits['canChangeProfileImage'] = false;
              }
            }
          }
        } catch (e) {
          print('Fehler beim Prüfen der Profilbild-Limits: $e');
        }
      }
      //TODO remove
       return {
        'canCreateApartment': true,
        'canCreateLandlord': true,
        'canSubmitReview': true,
        'canChangeProfileImage': true,
      };
      //return limits;
    } catch (e) {
      print('Allgemeiner Fehler in checkUserLimits: $e');
      // Im Zweifel erlauben
      return {
        'canCreateApartment': true,
        'canCreateLandlord': true,
        'canSubmitReview': true,
        'canChangeProfileImage': true,
      };
    }
  }

  // Hilfsfunktion zum Zählen von Reviews in Dokumenten
  static int _countReviewsInDocuments(
    List<QueryDocumentSnapshot> documents,
    DateTime oneDayAgo,
  ) {
    int count = 0;

    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>;
      final reviews = data['reviews'] as List<dynamic>? ?? [];

      for (var review in reviews) {
        if (review is Map<String, dynamic>) {
          final timestamp = _getDateTimeFromFirestore(review['timestamp']);
          if (timestamp != null && timestamp.isAfter(oneDayAgo)) {
            count++;
          }
        }
      }

      // Frühes Abbrechen wenn Limit überschritten (Performance-Optimierung)
      if (count >= 8) {
        break;
      }
    }

    return count;
  }

  // Hilfsfunktion zum Extrahieren von DateTime aus verschiedenen Firestore-Typen
  static DateTime? _getDateTimeFromFirestore(dynamic dateField) {
    if (dateField == null) return null;

    try {
      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is DateTime) {
        return dateField;
      } else if (dateField is String) {
        return DateTime.parse(dateField);
      } else if (dateField is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateField);
      } else if (dateField is double) {
        if (dateField > 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(dateField.toInt());
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            (dateField * 1000).toInt(),
          );
        }
      }
    } catch (e) {
      print('Fehler beim Konvertieren des Datums: $e');
    }

    return null;
  }

  // Hilfsfunktionen für spezifische Prüfungen
  static Future<bool> canUserCreateApartment(String userId) async {
    final limits = await checkUserLimits(
      userId,
      actionType: 'create_apartment',
    );
    print(
      'canUserCreateApartment für $userId: ${limits['canCreateApartment']}',
    );
    return limits['canCreateApartment']!;
  }

  static Future<bool> canUserCreateLandlord(String userId) async {
    final limits = await checkUserLimits(userId, actionType: 'create_landlord');
    print('canUserCreateLandlord für $userId: ${limits['canCreateLandlord']}');
    return limits['canCreateLandlord']!;
  }

  static Future<bool> canUserSubmitReview(String userId) async {
    final limits = await checkUserLimits(userId, actionType: 'submit_review');
    print('canUserSubmitReview für $userId: ${limits['canSubmitReview']}');
    return limits['canSubmitReview']!;
  }

  static Future<bool> canUserChangeProfileImage(String userId) async {
    final limits = await checkUserLimits(
      userId,
      actionType: 'change_profile_image',
    );
    return limits['canChangeProfileImage']!;
  }

  // Funktion zum Aktualisieren des Profilbild-Änderungsdatums
  static Future<void> updateProfileImageChangeDate(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastProfileImageChange': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Fehler beim Aktualisieren des Profilbild-Datums: $e');
    }
  }
}
