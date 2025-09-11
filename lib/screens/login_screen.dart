// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/register_screen.dart';
import 'package:immo_app/main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late String _email;
  late String _password;
  bool _loading = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anmelden'),
        centerTitle: true,
      ),
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
                  Icons.account_circle,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Hauptüberschrift
            Text(
              'Willkommen zurück!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            
            Text(
              'Melden Sie sich an, um fortzufahren',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24),
            
            // Login Form
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihr Passwort ein';
                      }
                      if (value.length < 6) {
                        return 'Das Passwort muss mindestens 6 Zeichen haben';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value!,
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
                      child: Text(
                        _error,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 16),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Anmelden',
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
            
            // Register Link
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    text: 'Noch keinen Account? ',
                    style: TextStyle(color: Colors.grey[600]),
                    children: [
                      TextSpan(
                        text: 'Registrieren',
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
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ihre Daten sind sicher bei uns. Wir respektieren Ihre Privatsphäre.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _loading = true;
        _error = '';
      });
      
      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        
        if (result.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          setState(() {
            _error = 'Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Daten.';
            _loading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _error = 'Kein Benutzer mit dieser E-Mail gefunden.';
          } else if (e.code == 'wrong-password') {
            _error = 'Falsches Passwort.';
          } else {
            _error = 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';
          }
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
          _loading = false;
        });
      }
    }
  }
}