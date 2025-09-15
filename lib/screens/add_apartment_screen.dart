// lib/screens/add_apartment_screen.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/apartment_details_screen.dart';
import 'package:immo_app/services/rate_limit_service.dart';
import 'package:immo_app/widgets/address_section.dart';
import 'package:immo_app/widgets/rating_section.dart';
import 'package:immo_app/widgets/image_section.dart';
import 'package:immo_app/widgets/comments_section.dart';
import 'package:immo_app/widgets/entity_selector.dart';
import 'package:immo_app/services/form_validation_service.dart';
import 'package:immo_app/services/data_processing_service.dart';
import 'package:immo_app/services/image_upload_service.dart';
import 'package:immo_app/services/apartment_service.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';
import 'package:immo_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  _AddApartmentScreenState createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  // Controllers
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _topStiegeHausController =
      TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _additionalCommentsController =
      TextEditingController();

  // State
  String _selectedCountry = 'Deutschland';
  final List<String> _countryOptions = [
    'Deutschland',
    'Österreich',
    'Schweiz',
    'Frankreich',
    'Niederlande',
    'Belgien',
    'Luxemburg',
    'Polen',
    'Tschechien',
    'Dänemark',
    'Liechtenstein',
  ];

  // Ratings
  final Map<String, int> _ratings = {
    'condition': 1,
    'cleanliness': 1,
    'landlord': 1,
    'equipment': 1,
    'location': 1,
    'transport': 1,
    'parking': 1,
    'neighbors': 1,
    'accessibility': 1,
    'leisure': 1,
    'shopping': 1,
    'safety': 1,
    'valueForMoney': 1,
  };

  // Images
  List<File> _imageFiles = [];
  bool _isLoading = false;
  bool _isDuplicate = false;
  String? _existingApartmentId;

  // Vermieter-Auswahl
  String? _selectedLandlordId;
  String? _selectedLandlordName;

  // Services
  final FormValidationService _validationService = FormValidationService();
  final DataProcessingService _dataService = DataProcessingService();

  // Ersetze die _saveApartment Methode mit dieser debug-verbesserten Version:

  // Füge diese Methode zur _AddApartmentScreenState Klasse hinzu:
  Future<void> _testRateLimit() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('=== RATE-LIMIT TEST ===');
    print('Aktueller User: ${currentUser.uid}');

    try {
      // Teste den kompletten Check
      final limits = await RateLimitService.checkUserLimits(currentUser.uid);
      print('Alle Limits: $limits');

      // Teste spezifisch für Apartments
      final canCreateApartment = await RateLimitService.canUserCreateApartment(
        currentUser.uid,
      );
      print('Kann Apartment erstellen: $canCreateApartment');

      // Zeige aktuelle Apartments des Users
      final apartmentSnapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print('Gefundene Apartments des Users: ${apartmentSnapshot.docs.length}');
      for (var doc in apartmentSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        print('  Apartment ${doc.id}: createdAt = $createdAt');
      }
    } catch (e) {
      print('Fehler beim Testen des Rate-Limits: $e');
    }
  }

  Future<void> _saveApartment() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Validierung
      if (!_validationService.validateApartmentFields(
        street: _streetController.text,
        houseNumber: _houseNumberController.text,
        zipCode: _zipCodeController.text,
        city: _cityController.text,
        comments: _additionalCommentsController.text,
      )) {
        final missingFields = _validationService.getMissingApartmentFields(
          street: _streetController.text,
          houseNumber: _houseNumberController.text,
          zipCode: _zipCodeController.text,
          city: _cityController.text,
          comments: _additionalCommentsController.text,
        );
        _showValidationError(
          'Bitte füllen Sie alle Pflichtfelder aus:\n• ${missingFields.join('\n• ')}',
        );
        setState(() => _isLoading = false);
        return;
      }

      await _performDuplicateCheck();
      await Future.delayed(Duration(milliseconds: 100));

      if (_isDuplicate && _existingApartmentId != null) {
        _handleDuplicate();
        setState(() => _isLoading = false);
        return; // <- DAS FEHLT IN DEINEM CODE!
      }

      // Tenant Verification BEIM SPEICHERN
      final String addressForVerification =
          '${_streetController.text} ${_houseNumberController.text}, '
          '${_zipCodeController.text} ${_cityController.text}';

      final confirmed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantVerificationScreen(
            isApartment: true,
            targetName: addressForVerification,
          ),
        ),
      );

      // Nur wenn bestätigt, prüfe Limits und speichere
      if (confirmed == true) {
        // ERST JETZT das Rate-Limiting prüfen
        final canCreate = await RateLimitService.canUserCreateApartment(
          currentUser.uid,
        );

        if (!canCreate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Wohnungslimit erreicht: Maximal 3 Wohnungen pro Woche',
                ),
                backgroundColor: AppColors.warning, // ✅ THEME FARBE
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        await _processAndSaveApartment(currentUser.uid);
      } else {
        // Abgebrochen
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Speichern abgebrochen')));
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('FEHLER in _saveApartment: $e');
      _showErrorSnackBar('Fehler beim Speichern: $e');
      setState(() => _isLoading = false);
    }
  }

  // Duplikat-Prüfung
  Future<void> _performDuplicateCheck() async {
    try {
      // Prüfe ob alle benötigten Felder ausgefüllt sind
      if (_streetController.text.trim().isEmpty ||
          _houseNumberController.text.trim().isEmpty ||
          _zipCodeController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty) {
        print('NICHT ALLE FELDER AUSGEFÜLLT - ÜBERSPRINGE PRÜFUNG');
        setState(() {
          _isDuplicate = false;
          _existingApartmentId = null;
        });
        return;
      }

      final isDuplicate = await ApartmentService.checkForExactDuplicate(
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        topStiegeHaus: _topStiegeHausController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        city: _cityController.text.trim(),
        country: _selectedCountry,
      );

      print('Ergebnis checkForDuplicate: $isDuplicate');

      String? existingId;
      if (isDuplicate) {
        existingId = await ApartmentService.getExistingApartmentId();
        print('Gefundene existingId: $existingId');
      }

      setState(() {
        _isDuplicate = isDuplicate;
        _existingApartmentId = existingId;
      });

      print('State nach setState:');
      print('  _isDuplicate: $_isDuplicate');
      print('  _existingApartmentId: $_existingApartmentId');
    } catch (e) {
      print('Fehler bei der Duplikat-Prüfung: $e');
      // Bei Fehler nicht blockieren, setze auf false
      setState(() {
        _isDuplicate = false;
        _existingApartmentId = null;
      });
    }
  }

  // Hilfsmethode zur Normalisierung
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-äöüß]'), '') // Entferne Sonderzeichen
        .replaceAll(RegExp(r'\s+'), ' ') // Mehrfache Leerzeichen zu einem
        // Normalisiere verschiedene Schreibweisen von "straße"
        .replaceAll(RegExp(r'strasse|straße|str\.?($|\s)'), 'str. ')
        .replaceAll(RegExp(r'\s+'), ' ') // Nochmal Leerzeichen normalisieren
        .trim();
  }

  // Duplikat-Handling
  void _handleDuplicate() {
    // Zeige die Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❌ Diese Wohnung existiert bereits!\n\n'
          'Jede Wohnung darf nur EINMAL angelegt werden.\n'
          'Fügen Sie Ihre Bewertung auf der Detailseite hinzu.',
          style: TextStyle(
            fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
            fontWeight: FontWeight.bold,
          ),
        ),
        action: SnackBarAction(
          label: 'ZUR WOHNUNG',
          onPressed: _navigateToExistingApartment,
          textColor: Colors.white,
        ),
        backgroundColor: AppColors.error, // ✅ THEME FARBE
        duration: Duration(seconds: 30), // Wird später überschrieben
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Automatische Navigation nach 3 Sekunden
    Future.delayed(Duration(seconds: 3), () {
      if (_existingApartmentId != null && context.mounted) {
        _navigateToExistingApartment();
      }
    });
  }

  void _navigateToExistingApartment() {
    print('Navigiere zur existierenden Wohnung: $_existingApartmentId');

    if (_existingApartmentId != null) {
      // SCHLIESSE ZUERST DIE SNACKBAR
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Lade das Dokument
      FirebaseFirestore.instance
          .collection('apartments')
          .doc(_existingApartmentId)
          .get()
          .then((docSnapshot) async {
            // Schließe den aktuellen Screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Warte auf das Schließen
            await Future.delayed(Duration(milliseconds: 300));

            // Prüfe ob wir noch navigieren können
            if (docSnapshot.exists) {
              try {
                // Verwende den Root-Navigator um sicherzugehen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ApartmentDetailScreen(apartmentDoc: docSnapshot),
                  ),
                );
              } catch (e) {
                print('Navigation error: $e');
              }
            } else {
              // Zeige Fehlermeldung
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wohnung nicht gefunden'),
                    backgroundColor: AppColors.warning, // ✅ THEME FARBE
                  ),
                );
              }
            }
          })
          .catchError((error) {
            // SCHLIESSE DIE SNACKBAR BEI FEHLER
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fehler beim Laden der Wohnung: $error'),
                  backgroundColor: AppColors.error, // ✅ THEME FARBE
                ),
              );
            }
          });
    } else {
      // SCHLIESSE DIE SNACKBAR
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<Map<String, dynamic>> _getCurrentUserReviewData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    String username = 'Anonymous';
    String profileImageUrl = '';
    String userId = 'anonymous';

    if (currentUser != null) {
      userId = currentUser.uid;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          username =
              userData?['username'] ??
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Mieter';
          profileImageUrl = userData?['profileImageUrl'] ?? '';
        } else {
          // Fallback zu Firebase Auth Daten
          username =
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Mieter';
        }
      } catch (e) {
        print('Fehler beim Laden der User-Daten: $e');
        // Fallback
        username =
            currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'Mieter';
      }
    }

    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
    };
  }

  Future<void> _processAndSaveApartment(String userId) async {
    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      try {
        // Upload mit Fortschrittsanzeige
        imageUrls = await ImageUploadService.uploadImagesWithProgress(
          _imageFiles,
          (message) {
            // Update die Snackbar mit Fortschrittsmeldung
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message), 
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary, // ✅ THEME FARBE
              ),
            );
          },
        );
      } catch (e) {
        throw Exception('Fehler beim Bild-Upload: $e');
      }
    }

    final userReviewData = await _getCurrentUserReviewData();

    // Erstelle die Review-Datenstruktur (für die Anzeige in der App)
    final reviewData = {
      'userId': userReviewData['userId'],
      'username': userReviewData['username'],
      'profileImageUrl': userReviewData['profileImageUrl'],
      'timestamp': DateTime.now(),
      'additionalComments': _additionalCommentsController.text.trim(),
      'isAnonymous': false, // Standardmäßig nicht anonym
      // Alle Bewertungskategorien
      'condition': (_ratings['condition'] ?? 1).toDouble(),
      'cleanliness': (_ratings['cleanliness'] ?? 1).toDouble(),
      'landlord': (_ratings['landlord'] ?? 1).toDouble(),
      'equipment': (_ratings['equipment'] ?? 1).toDouble(),
      'location': (_ratings['location'] ?? 1).toDouble(),
      'transport': (_ratings['transport'] ?? 1).toDouble(),
      'parking': (_ratings['parking'] ?? 1).toDouble(),
      'neighbors': (_ratings['neighbors'] ?? 1).toDouble(),
      'accessibility': (_ratings['accessibility'] ?? 1).toDouble(),
      'leisure': (_ratings['leisure'] ?? 1).toDouble(),
      'shopping': (_ratings['shopping'] ?? 1).toDouble(),
      'safety': (_ratings['safety'] ?? 1).toDouble(),
      'valueForMoney': (_ratings['valueForMoney'] ?? 1).toDouble(),
    };

    // Erstelle die vollständige Adresse
    final String fullAddress =
        '${_streetController.text.trim()} ${_houseNumberController.text.trim()}';
    final String addressLong =
        '${_streetController.text.trim()} ${_houseNumberController.text.trim()}, '
        '${_topStiegeHausController.text.trim()}, '
        '${_zipCodeController.text.trim()} ${_cityController.text.trim()}, '
        '$_selectedCountry';

    // Normalisierte Felder erstellen
    final normalizedStreet = _normalizeText(_streetController.text.trim());
    final normalizedCity = _normalizeText(_cityController.text.trim());
    final normalizedTopStiege = _normalizeText(
      _topStiegeHausController.text.trim(),
    );
    final normalizedHouseNumber = _normalizeText(
      _houseNumberController.text.trim(),
    );
    final normalizedCountry = _normalizeText(_selectedCountry);

    // Erstelle das Apartment-Dokument mit userId und createdAt
    final apartmentData = {
      'userId': userId, // WICHTIG: userId hinzufügen
      'street': _streetController.text.trim(),
      'houseNumber': _houseNumberController.text.trim(),
      'topStiegeHaus': _topStiegeHausController.text.trim(),
      'zipCode': _zipCodeController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _selectedCountry,
      'address': fullAddress,
      'addresslong': addressLong,
      'additionalComments': _additionalCommentsController.text.trim(),
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'reviews': [reviewData],
      'imageUrls': imageUrls,
      'landlordId': _selectedLandlordId,
      'landlordName': _selectedLandlordName ?? '',
      'normalizedStreet': normalizedStreet,
      'normalizedHouseNumber': normalizedHouseNumber,
      'normalizedCity': normalizedCity,
      'normalizedTopStiege': normalizedTopStiege,
      'normalizedZipCode': _zipCodeController.text,
      'normalizedCountry': normalizedCountry.trim(),
      ..._ratings.map((key, value) => MapEntry(key, value.toDouble())),
    };

    // Speichere in Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('apartments')
        .add(apartmentData);

    // Vermieter aktualisieren
    if (_selectedLandlordId != null) {
      await _dataService.updateLandlordWithApartment(
        _selectedLandlordId!,
        docRef.id,
        _selectedLandlordName ?? '',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wohnung erfolgreich hinzugefügt.'),
          backgroundColor: AppColors.success, // ✅ THEME FARBE
        ),
      );

      Navigator.pop(context, {'success': true, 'id': docRef.id});
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: AppColors.error, // ✅ THEME FARBE
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: AppColors.error, // ✅ THEME FARBE
      ),
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _topStiegeHausController.dispose();
    _zipCodeController.dispose();
    _cityController.dispose();
    _additionalCommentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wohnung hinzufügen'), 
        centerTitle: true,
        // Entfernt explizite Farbzuweisungen - verwendet Theme
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AddressSection(
              streetController: _streetController,
              houseNumberController: _houseNumberController,
              topStiegeHausController: _topStiegeHausController,
              zipCodeController: _zipCodeController,
              cityController: _cityController,
              selectedCountry: _selectedCountry,
              countryOptions: _countryOptions,
              onCountryChanged: (value) =>
                  setState(() => _selectedCountry = value),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            EntitySelector(
              entityType: 'landlords',
              selectedEntityId: _selectedLandlordId,
              selectedEntityName: _selectedLandlordName,
              onEntitySelected: (id, name) => setState(() {
                _selectedLandlordId = id;
                _selectedLandlordName = name;
              }),
              placeholderText: 'Vermieter auswählen',
              createButtonText: 'Neuen Vermieter erstellen',
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            RatingsSection(ratings: _ratings, isLandlord: false),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            ImageSection(
              imageFiles: _imageFiles,
              onImagesChanged: (files) => setState(() => _imageFiles = files),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            CommentsSection(controller: _additionalCommentsController),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveApartment,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.m, // ✅ THEME ABSTAND
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
                  ),
                  // Entfernt explizite Farbzuweisungen - verwendet Theme
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                          Text(
                            'Speichern...',
                            style: TextStyle(
                              fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Wohnung speichern',
                        style: TextStyle(
                          fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
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