// lib/screens/add_apartment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/widgets/star_rating_widget.dart';
import 'package:immo_app/utils/rating_helper.dart';
import 'package:immo_app/utils/address_utils.dart';
import 'package:immo_app/services/image_upload_service.dart';
import 'package:immo_app/services/apartment_service.dart';
import 'package:immo_app/screens/apartment_details_screen.dart';
import 'package:immo_app/screens/add_landlord_screen.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  _AddApartmentScreenState createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  // Text controllers
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _topStiegeHausController =
      TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _additionalCommentsController =
      TextEditingController();

  // State variables
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

  List<File> _imageFiles = [];
  bool _isDuplicate = false;
  String? _existingApartmentId;
  bool _isLoading = false;

  // NEU: Vermieter-Auswahl-Variablen
  String? _selectedLandlordId;
  String? _selectedLandlordName;
  List<Map<String, dynamic>> _allLandlords = [];  // Alle geladenen Vermieter
  List<Map<String, dynamic>> _filteredLandlords = [];  // Gefilterte Vermieter für Anzeige
  bool _isLoadingLandlords = false;
  
  // NEU: Pagination-Variablen für Vermieter
  final int _landlordsPerPage = 20;  // Vermieter pro Seite
  int _currentPage = 1;  // Aktuelle Seite
  int _totalPages = 1;   // Gesamtanzahl Seiten
  String _landlordSearchQuery = '';  // Suchbegriff

  // Extracted methods
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null) {
      // Begrenze auf maximal 5 Bilder
      final selectedImages = images.length > 5 ? images.take(5).toList() : images;
      
      // Konvertiere zu File-Liste
      final imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();
      
      setState(() {
        _imageFiles = imageFiles;
      });
      
      // Zeige Information über Anzahl der ausgewählten Bilder
      if (images.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Es können maximal 5 Bilder ausgewählt werden. ${images.length - 5} Bilder wurden ignoriert.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveApartment() async {
    setState(() => _isLoading = true);

    try {
      // Prüfe auf Duplikate
      await _performDuplicateCheck();
      if (_isDuplicate) return _handleDuplicate();

      // Validiere verpflichtende Felder
      if (!_validateRequiredFields()) {
        final missingFields = _getMissingFields();
        _showValidationError(
          'Bitte füllen Sie alle Pflichtfelder aus:\n• ${missingFields.join('\n• ')}',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Verarbeite und speichere das Apartment
      await _processAndSaveApartment();
    } catch (e) {
      _showErrorSnackBar('Fehler beim Speichern der Daten: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _validateRequiredFields() {
    // Prüfe Addressfelder
    final bool isAddressValid =
        _streetController.text.trim().isNotEmpty &&
        _houseNumberController.text.trim().isNotEmpty &&
        _zipCodeController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;

    // Prüfe additionalComments
    final bool isCommentValid = _additionalCommentsController.text
        .trim()
        .isNotEmpty;

    return isAddressValid && isCommentValid;
  }

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (_streetController.text.trim().isEmpty) missing.add('Straße');
    if (_houseNumberController.text.trim().isEmpty) missing.add('Hausnummer');
    if (_zipCodeController.text.trim().isEmpty) missing.add('PLZ');
    if (_cityController.text.trim().isEmpty) missing.add('Stadt');
    if (_additionalCommentsController.text.trim().isEmpty)
      missing.add('Kommentar');

    return missing;
  }

  Future<void> _performDuplicateCheck() async {
    final isDuplicate = await ApartmentService.checkForDuplicate(
      street: _streetController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      topStiegeHaus: _topStiegeHausController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      city: _cityController.text.trim(),
      country: _selectedCountry,
    );

    final existingId = await ApartmentService.getExistingApartmentId(
      street: _streetController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      topStiegeHaus: _topStiegeHausController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      city: _cityController.text.trim(),
      country: _selectedCountry,
    );

    setState(() {
      _isDuplicate = isDuplicate;
      _existingApartmentId = existingId;
    });
  }

  Future<void> _processAndSaveApartment() async {
    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      imageUrls = await ImageUploadService.uploadImages(_imageFiles);
    }

    final apartmentData = _buildApartmentData(imageUrls);

    final docRef = await FirebaseFirestore.instance.collection('apartments').add(apartmentData);

    // Wenn ein Vermieter ausgewählt wurde, aktualisiere auch den Vermieter
    if (_selectedLandlordId != null) {
      await FirebaseFirestore.instance
          .collection('landlords')
          .doc(_selectedLandlordId)
          .update({
        'apartmentIds': FieldValue.arrayUnion([docRef.id]),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wohnung erfolgreich hinzugefügt.')),
    );

    // Gebe Erfolg und Document ID zurück
    Navigator.pop(context, {'success': true, 'id': docRef.id});
  }

  Map<String, dynamic> _buildApartmentData(List<String> imageUrls) {
    String address =
        '${_cityController.text}, ${_streetController.text} ${_houseNumberController.text}, '
        '${_topStiegeHausController.text.isNotEmpty ? "${_topStiegeHausController.text}, " : ""}';
    String addressLong =
        '${_streetController.text} ${_houseNumberController.text}, '
        '${_topStiegeHausController.text.isNotEmpty ? "${_topStiegeHausController.text}, " : ""}'
        '${_zipCodeController.text} ${_cityController.text}, ${_selectedCountry}';
    String uniqueAddress = AddressUtils.createUniqueAddress(
      _streetController.text,
      _houseNumberController.text,
      _topStiegeHausController.text,
      _zipCodeController.text,
      _cityController.text,
      _selectedCountry,
    );

    final apartmentData = {
      'address': address,
      'addresslong': addressLong,
      'uniqueAddress': uniqueAddress,
      'street': _streetController.text,
      'normalizedStreet': AddressUtils.normalizeStreetName(_streetController.text.trim()),
      'houseNumber': _houseNumberController.text,
      'topStiegeHaus': _topStiegeHausController.text,
      'zipCode': _zipCodeController.text,
      'city': _cityController.text,
      'country': _selectedCountry,
      'imageUrls': imageUrls,
      'reviews': [_buildReviewData()],
      // Vermieter-Verknüpfung
      if (_selectedLandlordId != null) 'landlordId': _selectedLandlordId,
      if (_selectedLandlordName != null) 'landlordName': _selectedLandlordName,
    };

    return apartmentData;
  }

  Map<String, dynamic> _buildReviewData() {
    return {
      ..._ratings.map((key, value) => MapEntry(key, value)),
      'timestamp': DateTime.now().toIso8601String(),
      'additionalComments': _additionalCommentsController.text.trim(),
      'username': 'Mieter', // TODO: Replace with actual user
    };
  }

  void _handleDuplicate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dieses Apartment existiert bereits.'),
        action: SnackBarAction(
          label: 'Zum Apartment',
          onPressed: _navigateToExistingApartment,
        ),
      ),
    );
  }

  void _navigateToExistingApartment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('apartments')
                  .doc(_existingApartmentId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Scaffold(body: Center(child: Text('Fehler beim Laden der Apartmentdaten')));
                }
                return ApartmentDetailScreen(apartmentDoc: snapshot.data!);
              },
            ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // NEU: Vermieter laden mit Pagination
  Future<void> _loadLandlords() async {
    if (_isLoadingLandlords) return;

    setState(() {
      _isLoadingLandlords = true;
    });

    try {
      // Lade maximal 500 Vermieter (Performance-Optimierung)
      final snapshot = await FirebaseFirestore.instance
          .collection('landlords')
          .orderBy('name')
          .limit(500)
          .get();

      final landlords = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        landlords.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unbekannter Vermieter',
        });
      }

      setState(() {
        _allLandlords = landlords;
        _totalPages = (_allLandlords.length / _landlordsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _currentPage = 1;
        _isLoadingLandlords = false;
      });
      
      _updateFilteredLandlords();
      
    } catch (e) {
      print('Fehler beim Laden der Vermieter: $e');
      setState(() {
        _isLoadingLandlords = false;
      });
    }
  }

  // NEU: Filter- und Pagination-Logik für Vermieter
  void _updateFilteredLandlords() {
    final filtered = _allLandlords.where((landlord) {
      if (_landlordSearchQuery.isEmpty) return true;
      final query = _landlordSearchQuery.toLowerCase();
      return (landlord['name']?.toLowerCase().contains(query) ?? false);
    }).toList();

    final startIndex = (_currentPage - 1) * _landlordsPerPage;
    
    setState(() {
      _filteredLandlords = filtered.skip(startIndex).take(_landlordsPerPage).toList();
      _totalPages = (filtered.length / _landlordsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    });
  }

  void _loadFilteredLandlords(String query) {
    setState(() {
      _landlordSearchQuery = query;
      _currentPage = 1;
    });
    _updateFilteredLandlords();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateFilteredLandlords();
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _updateFilteredLandlords();
      });
    }
  }

  // NEU: Methode zum Erstellen eines neuen Vermieters
  void _createNewLandlord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddLandlordScreen()),
    );
    
    if (result != null && result is Map && result['success'] == true) {
      // Neu laden der Vermieter-Liste
      _loadLandlords();
      
      // Optional: Den neu erstellten Vermieter auswählen
      // Das kann später hinzugefügt werden
    }
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresse *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildRequiredTextField(
                    controller: _streetController,
                    labelText: 'Straße *',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildRequiredTextField(
                    controller: _houseNumberController,
                    labelText: 'Nr. *',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _topStiegeHausController,
                    decoration: InputDecoration(labelText: 'Top/Stiege'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildRequiredTextField(
                    controller: _zipCodeController,
                    labelText: 'PLZ *',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildRequiredTextField(
                    controller: _cityController,
                    labelText: 'Stadt *',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    items: _countryOptions.map((String option) {
                      return DropdownMenuItem<String>(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value ?? 'Deutschland';
                      });
                    },
                    decoration: InputDecoration(labelText: 'Land'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsmethode für verpflichtende Textfelder
  Widget _buildRequiredTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bewertungen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._ratings.keys.map((key) {
              return _buildRatingWidget(key);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingWidget(String key) {
    return Tooltip(
      message: RatingHelper.getTooltip(key),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(RatingHelper.getTooltip(key))),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  RatingHelper.getLabel(key),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.help_outline, size: 16, color: Colors.grey),
              ],
            ),
            SizedBox(height: 4),
            InteractiveStarRating(
              initialRating: _ratings[key] ?? 1,
              onRatingChanged: (rating) {
                setState(() {
                  _ratings[key] = rating;
                });
              },
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilder der Wohnung',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_imageFiles.length}/5 Bilder',
                  style: TextStyle(
                    fontSize: 14,
                    color: _imageFiles.length >= 5 ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _imageFiles.length >= 5 ? null : _pickImages,
              child: Text('Bilder auswählen (max. 5)'),
            ),
            if (_imageFiles.length >= 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Maximale Anzahl von 5 Bildern erreicht',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            SizedBox(height: 8),
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
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Nummerierung
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
                            style: TextStyle(color: Colors.white, fontSize: 10),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zusätzliche Kommentare *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _additionalCommentsController,
              maxLines: null,
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
          ],
        ),
      ),
    );
  }

  // NEU: Optimiertes Vermieter-Auswahl-Widget
  Widget _buildLandlordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vermieter (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            // Info-Text über spätere Zuweisung
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                'ℹ️ Sie können den Vermieter auch später erstellen und dieser Wohnung dann zuweisen.',
                style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              ),
            ),
            SizedBox(height: 8),
            
            // Suchfeld für Vermieter
            TextField(
              decoration: InputDecoration(
                labelText: 'Vermieter suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Name eingeben...',
              ),
              onChanged: (value) {
                _loadFilteredLandlords(value);
              },
            ),
            SizedBox(height: 8),
            
            // Pagination-Controls
            if (_totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seite $_currentPage von $_totalPages',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                        onPressed: _currentPage < _totalPages ? _nextPage : null,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            SizedBox(height: 8),
            
            // Vermieter-Liste mit Pagination
            if (_isLoadingLandlords)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Lade Vermieter... (${_allLandlords.length} gefunden)'),
                  ],
                ),
              )
            else if (_allLandlords.isEmpty)
              Column(
                children: [
                  Text(
                    'Keine Vermieter in der Datenbank gefunden',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadLandlords,
                    child: Text('Erneut versuchen'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _createNewLandlord,
                    child: Text('+ Neuen Vermieter erstellen'),
                  ),
                ],
              )
            else if (_filteredLandlords.isEmpty)
              Column(
                children: [
                  Text(
                    _landlordSearchQuery.isNotEmpty
                        ? 'Keine Vermieter für "${_landlordSearchQuery}" gefunden'
                        : 'Keine Vermieter verfügbar',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Insgesamt ${_allLandlords.length} Vermieter geladen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _createNewLandlord,
                    child: Text('+ Neuen Vermieter erstellen'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    '${_filteredLandlords.length} von ${_allLandlords.length} Vermietern',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 150, // Feste Höhe für bessere Kontrolle
                    child: ListView.builder(
                      itemCount: _filteredLandlords.length,
                      itemBuilder: (context, index) {
                        final landlord = _filteredLandlords[index];
                        final isSelected = _selectedLandlordId == landlord['id'];
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Text(
                              landlord['name'].length > 30 
                                  ? '${landlord['name'].substring(0, 30)}...' 
                                  : landlord['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isSelected ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedLandlordId = null;
                                  _selectedLandlordName = null;
                                } else {
                                  _selectedLandlordId = landlord['id'];
                                  _selectedLandlordName = landlord['name'];
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _createNewLandlord,
                    child: Text('+ Neuen Vermieter erstellen'),
                  ),
                ],
              ),
            SizedBox(height: 8),
            Text(
              'Wählen Sie einen bestehenden Vermieter aus oder erstellen Sie einen neuen',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Lade Vermieter beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _loadLandlords();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wohnung hinzufügen'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressSection(),
            SizedBox(height: 8),
            _buildLandlordSection(),
            SizedBox(height: 8),
            _buildRatingsSection(),
            SizedBox(height: 8),
            _buildImageSection(),
            SizedBox(height: 8),
            _buildCommentsSection(),
            SizedBox(height: 8),

            // Hinweistext für Pflichtfelder
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '* Pflichtfelder',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            if (_isDuplicate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Dieses Apartment existiert bereits!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveApartment,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 8),
                        Text('Speichern...'),
                      ],
                    )
                  : Text('Wohnung speichern'),
            ),
          ],
        ),
      ),
    );
  }
}