import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:immo_app/firebase_options.dart';
import 'package:immo_app/screens/about_screen.dart';
import 'package:immo_app/screens/apartment_list_screen.dart';
import 'package:immo_app/screens/landlord_list_screen.dart';
import 'package:immo_app/screens/settings_screen.dart';
import 'package:immo_app/screens/login_screen.dart'; // Neuer Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialisiert erfolgreich!');
  } catch (e) {
    print('Fehler bei Firebase-Initialisierung: $e');
  }

  runApp(ImmoRateApp());
}

class FirebaseInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
      } catch (e) {
        print('Error initializing Firebase: $e');
      }
    }
  }
}

class ImmoRateApp extends StatelessWidget {
  const ImmoRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mietwohnungs Bewertung',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(), // Neue Wrapper-Widget für Auth-Check
      debugShowCheckedModeBanner: false,
    );
  }
}

// Neues Widget für die Authentifizierungsprüfung
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Prüfe den Authentifizierungsstatus
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Ladeanzeige während des Auth-Checks
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Lade Authentifizierungsstatus...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // Benutzer ist eingeloggt
          return HomeScreen();
        } else {
          // Kein eingeloggter Benutzer - zeige Login-Screen
          return LoginScreen();
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Liste der Bildschirme
  final List<Widget> _screens = [
    ApartmentListScreen(), // Wohnungen
    LandlordListScreen(),  // Vermieter
    SettingsScreen(),      // Einstellungen
    AboutScreen(),         // Über uns
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Wohnungen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Vermieter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Über uns',
          ),
        ],
      ),
    );
  }
}