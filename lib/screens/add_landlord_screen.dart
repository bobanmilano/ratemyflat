// lib/screens/add_landlord_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:immo_app/services/image_upload_service.dart';
import 'package:immo_app/widgets/star_rating_widget.dart';

// lib/screens/add_landlord_screen.dart
// ... (Imports bleiben gleich)

class AddLandlordScreen extends StatefulWidget {
  const AddLandlordScreen({super.key});

  @override
  _AddLandlordScreenState createState() => _AddLandlordScreenState();
}

class _AddLandlordScreenState extends State<AddLandlordScreen> {
  // ... (Variablen bleiben gleich)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _additionalCommentsController = TextEditingController();
  List<File> _imageFiles = [];
  bool _isLoading = false;

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

  // Wohnungsauswahl-Variablen
  List<String> _selectedApartmentIds = [];
  List<Map<String, dynamic>> _allApartments = [];
  List<Map<String, dynamic>> _filteredApartments = [];
  bool _isLoadingApartments = false;
  
  // Pagination-Variablen
  final int _apartmentsPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;
  String _apartmentSearchQuery = '';

  // ... (Image picker bleibt gleich)
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final List<XFile>? images = await picker.pickMultiImage();
      
      if (images != null) {
        final selectedImages = images.length > 5 ? images.take(5).toList() : images;
        final imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();
        
        setState(() {
          _imageFiles = imageFiles;
        });
        
        if (images.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Es können maximal 5 Bilder ausgewählt werden. ${images.length - 5} Bilder wurden ignoriert.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Auswählen der Bilder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ... (Validierungsmethoden bleiben gleich)
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

  // ... (Save-Methoden bleiben größtenteils gleich)
  Future<void> _saveLandlord() async {
    setState(() => _isLoading = true);

    try {
      if (!_validateRequiredFields()) {
        final missingFields = _getMissingFields();
        _showValidationError(
          'Bitte füllen Sie alle Pflichtfelder aus:\n• ${missingFields.join('\n• ')}',
        );
        setState(() => _isLoading = false);
        return;
      }

      await _processAndSaveLandlord();
      
    } catch (e) {
      _showErrorSnackBar('Fehler beim Speichern der Daten: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndSaveLandlord() async {
    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      imageUrls = await ImageUploadService.uploadImages(_imageFiles);
    }

    final landlordData = _buildLandlordData(imageUrls);
    
    final docRef = await FirebaseFirestore.instance.collection('landlords').add(landlordData);
    
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vermieter erfolgreich hinzugefügt.')),
    );
    
    Navigator.pop(context, {'success': true, 'id': docRef.id});
  }

  Map<String, dynamic> _buildLandlordData(List<String> imageUrls) {
    return {
      'name': _nameController.text.trim(),
      'imageUrls': imageUrls,
      'username': 'Mieter',
      'reviews': [_buildReviewData()],
      'createdAt': FieldValue.serverTimestamp(),
      if (_selectedApartmentIds.isNotEmpty) 'apartmentIds': _selectedApartmentIds,
    };
  }

  Map<String, dynamic> _buildReviewData() {
    return {
      ..._ratings.map((key, value) => MapEntry(key, value)),
      'timestamp': DateTime.now().toIso8601String(),
      'additionalComments': _additionalCommentsController.text.trim(),
      'username': 'Mieter',
    };
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // NEU: Vereinfachte Wohnungsladung OHNE komplexe orderBy
  Future<void> _loadApartments() async {
    if (_isLoadingApartments) return;

    setState(() {
      _isLoadingApartments = true;
    });

    try {
      print('Lade Wohnungen...');
      
      // VEREINFACHT: Nur limitierte Abfrage OHNE orderBy
      final snapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .limit(500) // Reduziert auf 500 für bessere Performance
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

  // Filter- und Pagination-Logik (bleibt gleich)
  void _updateFilteredApartments() {
    print('Update filtered apartments. All: ${_allApartments.length}, Query: $_apartmentSearchQuery');
    
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
      _filteredApartments = filtered.skip(startIndex).take(_apartmentsPerPage).toList();
      _totalPages = (filtered.length / _apartmentsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      print('Updated filtered apartments: ${_filteredApartments.length}, Pages: $_totalPages');
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

  // UI Building methods (vereinfacht)
  Widget _buildNameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vermieter Information *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Vermietername *',
                border: OutlineInputBorder(),
                hintText: 'z.B. Max Mustermann',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimiertes Wohnungsauswahl-Widget
  Widget _buildApartmentsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wohnungen verknüpfen (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            // Suchfeld für Wohnungen
            TextField(
              decoration: InputDecoration(
                labelText: 'Wohnungen suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Adresse, Stadt, PLZ eingeben...',
              ),
              onChanged: (value) {
                _loadFilteredApartments(value);
              },
            ),
            SizedBox(height: 12),
            
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
            
            // Wohnungsliste mit Pagination
            if (_isLoadingApartments)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Lade Wohnungen... (${_allApartments.length} gefunden)'),
                  ],
                ),
              )
            else if (_allApartments.isEmpty)
              Column(
                children: [
                  Text(
                    'Keine Wohnungen in der Datenbank gefunden',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
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
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Insgesamt ${_allApartments.length} Wohnungen geladen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    '${_filteredApartments.length} von ${_allApartments.length} Wohnungen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _filteredApartments.length,
                      itemBuilder: (context, index) {
                        final apartment = _filteredApartments[index];
                        final isSelected = _selectedApartmentIds.contains(apartment['id']);
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Text(
                              apartment['address'].length > 40 
                                  ? '${apartment['address'].substring(0, 40)}...' 
                                  : apartment['address'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${apartment['zipCode']} ${apartment['city'] ?? ''}',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isSelected ? Colors.blue : Colors.grey,
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
            SizedBox(height: 8),
            Text(
              'Wählen Sie Wohnungen aus, die diesem Vermieter gehören',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Restliche UI-Methoden bleiben gleich)
  Widget _buildRatingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bewertungen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
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
      'communication': 'Reagiert der Vermieter schnell und höflich auf Anfragen?',
      'helpfulness': 'Ist der Vermieter hilfreich bei Problemen (z.B. Reparaturen)?',
      'fairness': 'Ist der Vermieter fair in der Miete und bei der Abrechnung von Nebenkosten?',
      'transparency': 'Informiert der Vermieter klar über Mietbedingungen und Verträge?',
      'responseTime': 'Wie schnell löst der Vermieter Probleme (z.B. defekte Geräte)?',
      'respect': 'Behandelt der Vermieter die Mieter mit Respekt?',
      'renovationManagement': 'Wie wird mit Renovierungen oder Modernisierungen umgegangen?',
      'leaseAgreement': 'Ist der Mietvertrag fair und transparent?',
      'operatingCosts': 'Legt der Vermieter die Abrechnungen der Betriebskosten regelmäßig vor?',
      'depositHandling': 'Retourniert der Vermieter die hinterlegte Kaution ordnungsgemäß?',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_tooltipMessages[key] ?? '')),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilder des Vermieters',
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
            SizedBox(height: 12),
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
            SizedBox(height: 12),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zusätzliche Kommentare *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
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

  @override
  void initState() {
    super.initState();
    // Lade Wohnungen beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _loadApartments();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vermieter hinzufügen'), 
        centerTitle: true
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameSection(),
            SizedBox(height: 16),
            _buildApartmentsSection(),
            SizedBox(height: 16),
            _buildRatingsSection(),
            SizedBox(height: 16),
            _buildImageSection(),
            SizedBox(height: 16),
            _buildCommentsSection(),
            SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '* Pflichtfelder',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _saveLandlord,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 8),
                        Text('Speichern...'),
                      ],
                    )
                  : Text('Vermieter speichern'),
            ),
          ],
        ),
      ),
    );
  }
}