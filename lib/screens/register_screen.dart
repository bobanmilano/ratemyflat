// lib/screens/register_screen.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/main.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _email;
  String? _password;
  String? _username;
  String? _confirmPassword;
  bool _loading = false;
  String _error = '';

  void initState() {
    super.initState();
    _testFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrieren'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-Bild oder Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.person_add,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Hauptüberschrift
            Text(
              'Konto erstellen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),

            Text(
              'Erstellen Sie ein neues Konto',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24),

            // Register Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Username Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Benutzername',
                      hintText: 'Ihr gewünschter Benutzername',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie einen Benutzernamen ein';
                      }
                      if (value.length < 3) {
                        return 'Der Benutzername muss mindestens 3 Zeichen haben';
                      }
                      return null;
                    },
                    onSaved: (value) => _username = value,
                  ),
                  SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      hintText: 'ihre.email@beispiel.de',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihre E-Mail ein';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Bitte geben Sie eine gültige E-Mail ein';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value,
                  ),
                  SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      hintText: 'Mindestens 6 Zeichen',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie ein Passwort ein';
                      }
                      if (value.length < 6) {
                        return 'Das Passwort muss mindestens 6 Zeichen haben';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value,
                  ),
                  SizedBox(height: 16),

                  // Password Confirmation Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Passwort bestätigen',
                      hintText: 'Passwort erneut eingeben',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte bestätigen Sie Ihr Passwort';
                      }
                      if (_password != null && value != _password) {
                        return 'Die Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                    onSaved: (value) => _confirmPassword = value,
                  ),
                  SizedBox(height: 24),

                  // Error Message
                  if (_error.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(_error, style: TextStyle(color: Colors.red)),
                    ),
                  SizedBox(height: 16),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Konto erstellen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Login Link
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text.rich(
                  TextSpan(
                    text: 'Bereits ein Konto? ',
                    style: TextStyle(color: Colors.grey[600]),
                    children: [
                      TextSpan(
                        text: 'Anmelden',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Datenschutz',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ihre Daten werden sicher gespeichert und nicht an Dritte weitergegeben.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Füge diese Methode in deinen RegisterScreen hinzu
  Future<void> _testFirebase() async {
    try {
      print('Teste Firebase Core...');
      final app = Firebase.app();
      print('Firebase App: ${app.name}');

      print('Teste Firebase Auth...');
      final auth = FirebaseAuth.instance;
      print('Aktueller User: ${auth.currentUser?.email}');

      print('Teste Firestore...');
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      print('Firestore Verbindung OK');
    } catch (e) {
      print('Firebase Test Fehler: $e');
    }
  }

  Future<void> _handleRegister() async {
    print('Starte Registrierung...');

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Eingegebene Daten - Email: $_email, Username: $_username');

      if (_email == null || _username == null || _password == null) {
        setState(() {
          _error = 'Bitte füllen Sie alle Felder aus.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _loading = true;
        _error = '';
      });

      try {
        print('Schritt 1: Erstelle Firebase Auth User...');

        UserCredential? result;

        // Versuche es mit Timeout
        await Future.any([
          FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _email!.trim(),
                password: _password!,
              )
              .then((value) => result = value),
          Future.delayed(Duration(seconds: 10)),
        ]);

        if (result == null) {
          throw Exception('Timeout bei der Benutzererstellung');
        }

        User? user = result!.user;
        print('Schritt 1 erfolgreich: User ID ${user?.uid}');

        if (user != null) {
          print('Schritt 2: Erstelle Firestore Dokument...');
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'uid': user.uid,
                  'email': _email!.trim(),
                  'username': _username!.trim(),
                  'createdAt': DateTime.now(),
                  'profileImageUrl': '',
                });
            print('Schritt 2 erfolgreich');

            print('Registrierung abgeschlossen, navigiere zum HomeScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } catch (firestoreError) {
            print('Firestore Fehler: $firestoreError');
            // Lösche den Auth-User wieder, wenn Firestore fehlschlägt
            await user.delete();
            rethrow;
          }
        }
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Fehler: ${e.code} - ${e.message}');
        setState(() {
          if (e.code == 'email-already-in-use') {
            _error = 'Diese E-Mail wird bereits verwendet.';
          } else if (e.code == 'invalid-email') {
            _error = 'Ungültige E-Mail-Adresse.';
          } else if (e.code == 'weak-password') {
            _error = 'Das Passwort ist zu schwach.';
          } else if (e.code == 'operation-not-allowed') {
            _error = 'E-Mail/Passwort-Anmeldung ist nicht aktiviert.';
          } else {
            _error = 'Registrierung fehlgeschlagen: ${e.message}';
          }
          _loading = false;
        });
      } catch (e) {
        print('Allgemeiner Fehler: $e');
        setState(() {
          _error = 'Ein Fehler ist aufgetreten: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }
}
