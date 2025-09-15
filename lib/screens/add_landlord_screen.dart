// lib/screens/add_landlord_screen.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:immo_app/screens/tenant_verification_screen.dart';
import 'package:immo_app/services/image_upload_service.dart';
import 'package:immo_app/services/rate_limit_service.dart';
import 'package:immo_app/widgets/star_rating_widget.dart';
import 'package:immo_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

class AddLandlordScreen extends StatefulWidget {
  const AddLandlordScreen({super.key});

  @override
  _AddLandlordScreenState createState() => _AddLandlordScreenState();
}

class _AddLandlordScreenState extends State<AddLandlordScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _additionalCommentsController =
      TextEditingController();
  List<File> _imageFiles = [];
  bool _isLoading = false;
  bool _isAnonymous = false; // Neue Variable für Anonymität

  // User-Daten
  String _userId = 'anonymous';
  String _username = 'Anonymous';
  String _profileImageUrl = '';

  // Ratings
  final Map<String, int> _ratings = {
    'communication': 1,
    'helpfulness': 1,
    'fairness': 1,
    'transparency': 1,
    'responseTime': 1,
    'respect': 1,
    'renovationManagement': 1,
    'leaseAgreement': 1,
    'operatingCosts': 1,
    'depositHandling': 1,
  };

  // Apartment selection
  List<String> _selectedApartmentIds = [];
  List<Map<String, dynamic>> _allApartments = [];
  List<Map<String, dynamic>> _filteredApartments = [];
  bool _isLoadingApartments = false;

  // Pagination
  final int _apartmentsPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;
  String _apartmentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Load apartments on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _loadApartments();
      });
    });
  }

  // Lade die Daten des eingeloggten Users
  Future<void> _loadCurrentUser() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _userId = currentUser.uid;
      });

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _username =
                userData?['username'] ??
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Mieter';
            _profileImageUrl = userData?['profileImageUrl'] ?? '';
          });
        } else {
          // Fallback zu Firebase Auth Daten
          setState(() {
            _username =
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Mieter';
          });
        }
      } catch (e) {
        print('Fehler beim Laden der User-Daten: $e');
        // Fallback
        setState(() {
          _username =
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Mieter';
        });
      }
    }
  }

  // Image picker
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile>? images = await picker.pickMultiImage();

      if (images != null) {
        final selectedImages = images.length > 5
            ? images.take(5).toList()
            : images;
        final imageFiles = selectedImages
            .map((xFile) => File(xFile.path))
            .toList();

        setState(() {
          _imageFiles = imageFiles;
        });

        if (images.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Es können maximal 5 Bilder ausgewählt werden. ${images.length - 5} Bilder wurden ignoriert.',
              ),
              backgroundColor: AppColors.warning, // ✅ THEME FARBE
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Auswählen der Bilder: $e'),
          backgroundColor: AppColors.error, // ✅ THEME FARBE
        ),
      );
    }
  }

  // Validation
  bool _validateRequiredFields() {
    return _nameController.text.trim().isNotEmpty &&
        _additionalCommentsController.text.trim().length >= 20 &&
        _additionalCommentsController.text.trim().length <= 800;
  }

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (_nameController.text.trim().isEmpty) missing.add('Vermietername');
    final String comment = _additionalCommentsController.text.trim();
    if (comment.isEmpty) {
      missing.add('Kommentar (mindestens 20 Zeichen)');
    } else if (comment.length < 20) {
      missing.add('Kommentar zu kurz (mindestens 20 Zeichen)');
    } else if (comment.length > 800) {
      missing.add('Kommentar zu lang (max. 800 Zeichen)');
    }

    return missing;
  }

  // Save landlord
  Future<void> _saveLandlord() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final canCreate = await RateLimitService.canUserCreateLandlord(
      currentUser.uid,
    );
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vermieterlimit erreicht: Maximal 5 Vermieter pro Woche',
          ),
          backgroundColor: AppColors.warning, // ✅ THEME FARBE
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final confirmed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TenantVerificationScreen(
          isApartment: false,
          targetName: 'Neuer Vermieter',
        ),
      ),
    );

    if (confirmed != true) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (!_validateRequiredFields()) {
        final missingFields = _getMissingFields();
        _showValidationError(
          'Bitte füllen Sie alle Pflichtfelder aus:\n• ${missingFields.join('\n• ')}',
        );
        setState(() => _isLoading = false);
        return;
      }

      await _processAndSaveLandlord(currentUser.uid);
    } catch (e) {
      _showErrorSnackBar('Fehler beim Speichern der Daten: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Process and save with progress indication
  Future<void> _processAndSaveLandlord(String userId) async {
    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      try {
        // Upload with progress indication
        imageUrls = await ImageUploadService.uploadImagesWithProgress(
          _imageFiles,
          (message) {
            // Update snackbar with progress message
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

    // Berechne Durchschnittsbewertung
    final totalRating = _ratings.values.reduce((a, b) => a + b);
    final averageRating = _ratings.isNotEmpty
        ? totalRating / _ratings.length
        : 0.0;

    final landlordData = {
      'userId': userId, // WICHTIG: userId hinzufügen
      'name': _nameController.text.trim(),
      'imageUrls': imageUrls,
      'username': _isAnonymous ? 'Anonymous' : _username, // Echter Username
      'profileImageUrl': _isAnonymous
          ? ''
          : _profileImageUrl, // Echtes Profilbild
      'isAnonymous': _isAnonymous, // Anonymitäts-Flag
      'createdAt': DateTime.now(), // WICHTIG: createdAt hinzufügen
      'updatedAt': DateTime.now(), // WICHTIG: updatedAt hinzufügen
      'averageRating': averageRating, // Durchschnittsbewertung
      'totalRatings': _ratings.length, // Anzahl Bewertungen
      if (_selectedApartmentIds.isNotEmpty)
        'apartmentIds': _selectedApartmentIds,

      // Erste Review (die Erstellung selbst)
      'reviews': [_buildReviewData()],
    };

    final docRef = await FirebaseFirestore.instance
        .collection('landlords')
        .add(landlordData);

    // Update apartments with landlord information
    if (_selectedApartmentIds.isNotEmpty) {
      for (final apartmentId in _selectedApartmentIds) {
        await FirebaseFirestore.instance
            .collection('apartments')
            .doc(apartmentId)
            .update({
              'landlordId': docRef.id,
              'landlordName': landlordData['name'],
            });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vermieter erfolgreich hinzugefügt.'),
          backgroundColor: AppColors.success, // ✅ THEME FARBE
        ),
      );

      Navigator.pop(context, {'success': true, 'id': docRef.id});
    }
  }

  Map<String, dynamic> _buildReviewData() {
    return {
      'userId': _userId,
      'username': _isAnonymous ? 'Anonymous' : _username,
      'profileImageUrl': _isAnonymous ? '' : _profileImageUrl,
      'isAnonymous': _isAnonymous,
      ..._ratings.map((key, value) => MapEntry(key, value.toDouble())),
      'timestamp': DateTime.now(),
      'additionalComments': _additionalCommentsController.text.trim(),
    };
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

  // Load apartments for selection
  Future<void> _loadApartments() async {
    if (_isLoadingApartments) return;

    setState(() {
      _isLoadingApartments = true;
    });

    try {
      print('Lade Wohnungen...');

      final snapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .limit(500)
          .get();

      print('Geladene Wohnungen: ${snapshot.docs.length}');

      final apartments = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        apartments.add({
          'id': doc.id,
          'address': data['addresslong'] ?? 'Adresse nicht verfügbar',
          'city': data['city'] ?? '',
          'zipCode': data['zipCode'] ?? '',
        });
      }

      print('Verarbeitete Wohnungen: ${apartments.length}');

      setState(() {
        _allApartments = apartments;
        _totalPages = (_allApartments.length / _apartmentsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _currentPage = 1;
        _isLoadingApartments = false;
      });

      _updateFilteredApartments();

      print('Filtered Apartments: ${_filteredApartments.length}');
    } catch (e) {
      print('Fehler beim Laden der Wohnungen: $e');
      setState(() {
        _isLoadingApartments = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Wohnungen: $e')),
      );
    }
  }

  // Filter and pagination logic
  void _updateFilteredApartments() {
    print(
      'Update filtered apartments. All: ${_allApartments.length}, Query: $_apartmentSearchQuery',
    );

    final filtered = _allApartments.where((apartment) {
      if (_apartmentSearchQuery.isEmpty) return true;
      final query = _apartmentSearchQuery.toLowerCase();
      return (apartment['address']?.toLowerCase().contains(query) ?? false) ||
          (apartment['city']?.toLowerCase().contains(query) ?? false) ||
          (apartment['zipCode']?.toString().contains(query) ?? false);
    }).toList();

    print('Gefilterte Wohnungen: ${filtered.length}');

    final startIndex = (_currentPage - 1) * _apartmentsPerPage;

    setState(() {
      _filteredApartments = filtered
          .skip(startIndex)
          .take(_apartmentsPerPage)
          .toList();
      _totalPages = (filtered.length / _apartmentsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      print(
        'Updated filtered apartments: ${_filteredApartments.length}, Pages: $_totalPages',
      );
    });
  }

  void _loadFilteredApartments(String query) {
    print('Filter query: $query');
    setState(() {
      _apartmentSearchQuery = query;
      _currentPage = 1;
    });
    _updateFilteredApartments();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateFilteredApartments();
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _updateFilteredApartments();
      });
    }
  }

  // UI Building methods
  Widget _buildNameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vermieter Information *',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Vermietername *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
                ),
                hintText: 'z.B. Max Mustermann',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wohnungen verknüpfen (optional)',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

            // Search field
            TextField(
              decoration: InputDecoration(
                labelText: 'Wohnungen suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
                ),
                hintText: 'Adresse, Stadt, PLZ eingeben...',
              ),
              onChanged: (value) {
                _loadFilteredApartments(value);
              },
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

            // Pagination controls
            if (_totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seite $_currentPage von $_totalPages',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                      color: AppColors.textSecondary, // ✅ THEME FARBE
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: _currentPage > 1 ? _previousPage : null,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: _currentPage < _totalPages
                            ? _nextPage
                            : null,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

            // Apartments list
            if (_isLoadingApartments)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                    Text(
                      'Lade Wohnungen... (${_allApartments.length} gefunden)',
                    ),
                  ],
                ),
              )
            else if (_allApartments.isEmpty)
              Column(
                children: [
                  Text(
                    'Keine Wohnungen in der Datenbank gefunden',
                    style: TextStyle(color: AppColors.textSecondary), // ✅ THEME FARBE
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  TextButton(
                    onPressed: _loadApartments,
                    child: Text('Erneut versuchen'),
                  ),
                ],
              )
            else if (_filteredApartments.isEmpty)
              Column(
                children: [
                  Text(
                    _apartmentSearchQuery.isNotEmpty
                        ? 'Keine Wohnungen für "${_apartmentSearchQuery}" gefunden'
                        : 'Keine Wohnungen verfügbar',
                    style: TextStyle(color: AppColors.textSecondary), // ✅ THEME FARBE
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Text(
                    'Insgesamt ${_allApartments.length} Wohnungen geladen',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                      color: AppColors.textSecondary, // ✅ THEME FARBE
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    '${_filteredApartments.length} von ${_allApartments.length} Wohnungen',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                      color: AppColors.textSecondary, // ✅ THEME FARBE
                    ),
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _filteredApartments.length,
                      itemBuilder: (context, index) {
                        final apartment = _filteredApartments[index];
                        final isSelected = _selectedApartmentIds.contains(
                          apartment['id'],
                        );

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1) // ✅ THEME FARBE
                              : null,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            title: Text(
                              apartment['address'].length > 40
                                  ? '${apartment['address'].substring(0, 40)}...'
                                  : apartment['address'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${apartment['zipCode']} ${apartment['city'] ?? ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary, // ✅ THEME FARBE
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isSelected 
                                  ? AppColors.primary // ✅ THEME FARBE
                                  : AppColors.textSecondary, // ✅ THEME FARBE
                              size: 20,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedApartmentIds.remove(apartment['id']);
                                } else {
                                  _selectedApartmentIds.add(apartment['id']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              'Wählen Sie Wohnungen aus, die diesem Vermieter gehören',
              style: TextStyle(
                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                color: AppColors.textSecondary, // ✅ THEME FARBE
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            ..._ratings.keys.map((key) {
              return _buildRatingWidget(key);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingWidget(String key) {
    final Map<String, String> _tooltipMessages = {
      'communication':
          'Reagiert der Vermieter schnell und höflich auf Anfragen?',
      'helpfulness':
          'Ist der Vermieter hilfreich bei Problemen (z.B. Reparaturen)?',
      'fairness':
          'Ist der Vermieter fair in der Miete und bei der Abrechnung von Nebenkosten?',
      'transparency':
          'Informiert der Vermieter klar über Mietbedingungen und Verträge?',
      'responseTime':
          'Wie schnell löst der Vermieter Probleme (z.B. defekte Geräte)?',
      'respect': 'Behandelt der Vermieter die Mieter mit Respekt?',
      'renovationManagement':
          'Wie wird mit Renovierungen oder Modernisierungen umgegangen?',
      'leaseAgreement': 'Ist der Mietvertrag fair und transparent?',
      'operatingCosts':
          'Legt der Vermieter die Abrechnungen der Betriebskosten regelmäßig vor?',
      'depositHandling':
          'Retourniert der Vermieter die hinterlegte Kaution ordnungsgemäß?',
    };

    final Map<String, String> _ratingLabels = {
      'communication': 'Kommunikation:',
      'helpfulness': 'Hilfsbereitschaft:',
      'fairness': 'Fairness:',
      'transparency': 'Transparenz:',
      'responseTime': 'Reaktionszeit:',
      'respect': 'Respekt:',
      'renovationManagement': 'Renovierungsmanagement:',
      'leaseAgreement': 'Mietvertrag:',
      'operatingCosts': 'Betriebskosten:',
      'depositHandling': 'Kaution:',
    };

    return Tooltip(
      message: _tooltipMessages[key] ?? '',
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(_tooltipMessages[key] ?? ''),
              backgroundColor: AppColors.primary, // ✅ THEME FARBE
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _ratingLabels[key] ?? key,
                  style: TextStyle(
                    fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: AppSpacing.xs), // ✅ THEME ABSTAND
                Icon(Icons.help_outline, size: 16, color: AppColors.textSecondary), // ✅ THEME FARBE
              ],
            ),
            SizedBox(height: AppSpacing.xs), // ✅ THEME ABSTAND
            InteractiveStarRating(
              initialRating: _ratings[key] ?? 1,
              onRatingChanged: (rating) {
                setState(() {
                  _ratings[key] = rating;
                });
              },
            ),
            SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilder des Vermieters',
                  style: TextStyle(
                    fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_imageFiles.length}/5 Bilder',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                    color: _imageFiles.length >= 5 
                        ? AppColors.error // ✅ THEME FARBE
                        : AppColors.textSecondary, // ✅ THEME FARBE
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            ElevatedButton(
              onPressed: _imageFiles.length >= 5 ? null : _pickImages,
              child: Text('Bilder auswählen (max. 5)'),
            ),
            if (_imageFiles.length >= 5)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.s), // ✅ THEME ABSTAND
                child: Text(
                  'Maximale Anzahl von 5 Bildern erreicht',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                    color: AppColors.warning, // ✅ THEME FARBE
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            if (_imageFiles.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _imageFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textDisabled, // ✅ THEME FARBE
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: AppTypography.caption, // ✅ THEME TYPOGRAFIE
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zusätzliche Kommentare *',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            TextField(
              controller: _additionalCommentsController,
              maxLines: null,
              minLines: 4,
              maxLength: 800,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
                ),
                labelText: 'Kommentar *',
                hintText: 'Beschreiben Sie Ihre Erfahrung mit dem Vermieter...',
                alignLabelWithHint: true,
                helperText: 'Mindestens 20, maximal 800 Zeichen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Anonymität-Option
  Widget _buildAnonymitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veröffentlichung',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

            // User-Info Card (wenn nicht anonym)
            if (!_isAnonymous)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s), // ✅ THEME ABSTAND
                  child: Row(
                    children: [
                      // Profilbild
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _profileImageUrl.isNotEmpty
                            ? NetworkImage(_profileImageUrl)
                            : null,
                        child: _profileImageUrl.isEmpty
                            ? Icon(Icons.person, size: 20)
                            : null,
                      ),
                      SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                      // Username und Erstellungsinfo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Erstellt von:',
                              style: TextStyle(
                                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                                color: AppColors.textSecondary, // ✅ THEME FARBE
                              ),
                            ),
                            Text(
                              _username,
                              style: TextStyle(
                                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs), // ✅ THEME ABSTAND
                            Text(
                              'Heute',
                              style: TextStyle(
                                fontSize: AppTypography.caption, // ✅ THEME TYPOGRAFIE
                                color: AppColors.textDisabled, // ✅ THEME FARBE
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            SwitchListTile(
              title: Text('Anonym veröffentlichen'),
              subtitle: Text(
                _isAnonymous
                    ? 'Ihr Name und Profilbild werden nicht angezeigt'
                    : 'Ihr Name und Profilbild werden öffentlich sichtbar',
              ),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value ?? false;
                });
              },
              secondary: Icon(
                _isAnonymous ? Icons.visibility_off : Icons.visibility,
                color: _isAnonymous
                    ? Colors.grey
                    : AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            if (_isAnonymous)
              Container(
                padding: EdgeInsets.all(AppSpacing.s), // ✅ THEME ABSTAND
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1), // ✅ THEME FARBE
                  borderRadius: BorderRadius.circular(AppRadius.medium), // ✅ THEME RADIUS
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3), // ✅ THEME FARBE
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info, 
                      color: AppColors.warning, // ✅ THEME FARBE
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                    Expanded(
                      child: Text(
                        'Ihre Bewertung wird anonym veröffentlicht. Sie hilft anderen Mietern, ohne Ihre Identität preiszugeben.',
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                          color: AppColors.warning, // ✅ THEME FARBE
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _additionalCommentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vermieter hinzufügen'), 
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameSection(),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            _buildApartmentsSection(),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            _buildRatingsSection(),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            _buildImageSection(),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            _buildCommentsSection(),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            _buildAnonymitySection(), // Neue Anonymität-Sektion mit Profilbild
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            // Hint for required fields
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s), // ✅ THEME ABSTAND
              child: Text(
                '* Pflichtfelder',
                style: TextStyle(
                  fontSize: AppTypography.caption, // ✅ THEME TYPOGRAFIE
                  color: AppColors.textSecondary, // ✅ THEME FARBE
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLandlord,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.m, // ✅ THEME ABSTAND
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
                  ),
                  backgroundColor: AppColors.accent, // ✅ THEME FARBE
                  foregroundColor: Colors.white,
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
                        'Vermieter speichern',
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