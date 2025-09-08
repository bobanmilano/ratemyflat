// lib/screens/add_apartment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/widgets/address_section.dart';
import 'package:immo_app/widgets/rating_section.dart';
import 'package:immo_app/widgets/image_section.dart';
import 'package:immo_app/widgets/comments_section.dart';
import 'package:immo_app/widgets/entity_selector.dart';
import 'package:immo_app/services/form_validation_service.dart';
import 'package:immo_app/services/data_processing_service.dart';
import 'package:immo_app/services/image_upload_service.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  _AddApartmentScreenState createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  // Controllers
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _topStiegeHausController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _additionalCommentsController = TextEditingController();

  // State
  String _selectedCountry = 'Deutschland';
  final List<String> _countryOptions = [
    'Deutschland', 'Österreich', 'Schweiz', 'Frankreich', 'Niederlande',
    'Belgien', 'Luxemburg', 'Polen', 'Tschechien', 'Dänemark', 'Liechtenstein',
  ];

  // Ratings
  final Map<String, int> _ratings = {
    'condition': 1, 'cleanliness': 1, 'landlord': 1, 'equipment': 1,
    'location': 1, 'transport': 1, 'parking': 1, 'neighbors': 1,
    'accessibility': 1, 'leisure': 1, 'shopping': 1, 'safety': 1, 'valueForMoney': 1,
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

  Future<void> _saveApartment() async {
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
        _showValidationError('Bitte füllen Sie alle Pflichtfelder aus:\n• ${missingFields.join('\n• ')}');
        setState(() => _isLoading = false);
        return;
      }

      // Speichern
      await _processAndSaveApartment();
      
    } catch (e) {
      _showErrorSnackBar('Fehler beim Speichern: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndSaveApartment() async {
    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      imageUrls = await ImageUploadService.uploadImages(_imageFiles);
    }

    final addressData = {
      'street': _streetController.text,
      'houseNumber': _houseNumberController.text,
      'topStiegeHaus': _topStiegeHausController.text,
      'zipCode': _zipCodeController.text,
      'city': _cityController.text,
      'country': _selectedCountry,
    };

    final apartmentData = _dataService.buildApartmentData(
      addressData: addressData,
      imageUrls: imageUrls,
      ratings: _ratings,
      landlordId: _selectedLandlordId,
      landlordName: _selectedLandlordName,
    );

    final docRef = await FirebaseFirestore.instance.collection('apartments').add(apartmentData);

    // Vermieter aktualisieren
    if (_selectedLandlordId != null) {
      await _dataService.updateLandlordWithApartment(
        _selectedLandlordId!, 
        docRef.id, 
        _selectedLandlordName ?? ''
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wohnung erfolgreich hinzugefügt.')),
    );

    Navigator.pop(context, {'success': true, 'id': docRef.id});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wohnung hinzufügen'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              onCountryChanged: (value) => setState(() => _selectedCountry = value),
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            RatingsSection(ratings: _ratings, isLandlord: false),
            SizedBox(height: 16),
            ImageSection(
              imageFiles: _imageFiles,
              onImagesChanged: (files) => setState(() => _imageFiles = files),
            ),
            SizedBox(height: 16),
            CommentsSection(controller: _additionalCommentsController),
            SizedBox(height: 16),
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