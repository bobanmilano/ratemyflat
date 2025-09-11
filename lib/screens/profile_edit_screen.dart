// lib/screens/profile_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:immo_app/services/image_upload_service.dart';
import 'package:immo_app/services/rate_limit_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  
  File? _profileImageFile;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  User? _currentUser; // Firebase Auth User

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      // Falls kein User eingeloggt ist
      Navigator.pop(context);
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Lade User-Daten aus Firestore
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            _usernameController.text = userData['username'] ?? _currentUser!.displayName ?? 'Mieter';
            _currentProfileImageUrl = userData['profileImageUrl'];
          });
        }
      } else {
        // Erstelle neuen User-Eintrag mit Firebase Auth Daten
        final username = _currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? 'Mieter';
        
        await _firestore.collection('users').doc(_currentUser!.uid).set({
          'uid': _currentUser!.uid,
          'email': _currentUser!.email,
          'username': username,
          'createdAt': DateTime.now(),
          'lastLogin': DateTime.now(),
          'profileImageUrl': '',
        });
        
        setState(() {
          _usernameController.text = username;
        });
      }
    } catch (e) {
      print('Fehler beim Laden des Profils: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden des Profils')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _profileImageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Auswählen des Bildes')),
      );
    }
  }

Future<String?> _uploadProfileImage(File imageFile) async {
  if (_currentUser == null) return null;

  // Prüfe Profilbild-Limit
  final canChange = await RateLimitService.canUserChangeProfileImage(_currentUser!.uid);
  if (!canChange) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profilbild-Limit erreicht: Nur einmal pro Woche möglich'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return _currentProfileImageUrl; // Altes Bild behalten
  }

  try {
    // Optimiere Bild für Smartphone-Nutzung
    final optimizedImage = await ImageUploadService.optimizeForMobile(imageFile);
    
    // Upload zum Firebase Storage
    String fileName = 'user_${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference storageRef = 
        FirebaseStorage.instance.ref().child('profile_images/${_currentUser!.uid}/$fileName');
    
    UploadTask uploadTask = storageRef.putFile(optimizedImage);
    TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
    String downloadUrl = await snapshot.ref.getDownloadURL();
    
    // Lösche temporäre Datei falls erstellt
    if (optimizedImage.path != imageFile.path) {
      await optimizedImage.delete();
    }
    
    // Datum der letzten Änderung aktualisieren
    await RateLimitService.updateProfileImageChangeDate(_currentUser!.uid);
    
    return downloadUrl;
  } catch (e) {
    print('Fehler beim Upload des Profilbildes: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Upload des Profilbildes'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    
    setState(() => _isSaving = true);

    try {
      // Validiere Username
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        throw Exception('Benutzername darf nicht leer sein');
      }

      // Upload Profilbild falls geändert
      String? profileImageUrl = _currentProfileImageUrl;
      if (_profileImageFile != null) {
        profileImageUrl = await _uploadProfileImage(_profileImageFile!);
        if (profileImageUrl == null) {
          throw Exception('Fehler beim Upload des Profilbildes');
        }
      }

      // Speichere Profildaten in Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'updatedAt': DateTime.now(),
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil erfolgreich gespeichert!')),
      );

      Navigator.pop(context, true); // Erfolg zurückgeben
      
    } catch (e) {
      print('Fehler beim Speichern des Profils: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern des Profils')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil bearbeiten'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving || _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profilbild-Abschnitt
                  _buildProfileImageSection(),
                  SizedBox(height: 24),
                  
                  // Username-Abschnitt
                  _buildUsernameSection(),
                  SizedBox(height: 24),
                  
                  // Email-Anzeige (nicht editierbar)
                  _buildEmailSection(),
                  SizedBox(height: 24),
                  
                  // Speichern-Button
                 // Speichern-Button (konsistent mit App-Design)
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).primaryColor.withOpacity(0.3),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: _isSaving || _isLoading ? null : _saveProfile,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0, // Entferne Standard-Elevation
    ),
    child: _isSaving
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              SizedBox(width: 12),
              Text(
                'Speichern...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          )
        : Text(
            'Profil speichern',
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildProfileImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profilbild',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Profilbild-Anzeige
            Center(
              child: Stack(
                children: [
                  // Aktuelles Profilbild oder Platzhalter
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: ClipOval(
                      child: _profileImageFile != null
                          ? Image.file(
                              _profileImageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildProfileImagePlaceholder();
                              },
                            )
                          : _currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                              ? Image.network(
                                  _currentProfileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildProfileImagePlaceholder();
                                  },
                                )
                              : _buildProfileImagePlaceholder(),
                    ),
                  ),
                  
                  // Bearbeiten-Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickProfileImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Bild-Ändern-Button
            Center(
              child: TextButton(
                onPressed: _pickProfileImage,
                child: Text('Profilbild ändern'),
              ),
            ),
            
            // Hinweis
            Center(
              child: Text(
                'Unterstützte Formate: JPG, PNG (max. 5MB empfohlen)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: 50,
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benutzername',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Benutzername *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.person),
                hintText: 'Geben Sie Ihren Benutzernamen ein',
              ),
              maxLength: 30,
              enabled: !_isSaving,
            ),
            
            SizedBox(height: 8),
            
            Text(
              'Ihr Benutzername wird in Bewertungen angezeigt',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Mail Adresse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.grey[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentUser?.email ?? 'Keine E-Mail',
                      style: TextStyle(fontSize: 16),
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
    _usernameController.dispose();
    super.dispose();
  }
}