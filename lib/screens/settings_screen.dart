// lib/screens/settings_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:immo_app/screens/legal_screen.dart';
import 'package:immo_app/screens/login_screen.dart';
import 'package:immo_app/screens/profile_edit_screen.dart';
import 'package:immo_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT
import 'package:package_info_plus/package_info_plus.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil-Bereich
              _buildSectionHeader('Profil'),
              _buildSettingsCard(
                context,
                icon: Icons.account_circle,
                title: 'Profil bearbeiten',
                subtitle: 'Name, Avatar und persönliche Informationen',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
              // App-Einstellungen
              _buildSectionHeader('App-Einstellungen'),
              _buildSettingsCard(
                context,
                icon: Icons.brightness_6,
                title: 'Darstellung',
                subtitle: 'Dark/Light Mode',
                onTap: () {
                  // TODO: Theme-Switcher implementieren
                  _showFeatureComingSoon(context);
                },
              ),
              SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
              _buildSettingsCard(
                context,
                icon: Icons.language,
                title: 'Sprache',
                subtitle: 'App-Sprache ändern',
                onTap: () {
                  // TODO: Sprachauswahl implementieren
                  _showFeatureComingSoon(context);
                },
              ),
              SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
              // Rechtliches
              _buildSectionHeader('Rechtliches'),
              _buildSettingsCard(
                context,
                icon: Icons.description,
                title: 'Datenschutzerklärung',
                subtitle: 'Informationen zum Datenschutz',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalScreen(documentType: 'privacy'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
              _buildSettingsCard(
                context,
                icon: Icons.gavel,
                title: 'Allgemeine Geschäftsbedingungen',
                subtitle: 'AGB der App',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LegalScreen(documentType: 'terms'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
              _buildSettingsCard(
                context,
                icon: Icons.info,
                title: 'Impressum',
                subtitle: 'Informationen zum Anbieter',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalScreen(documentType: 'imprint'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
              // Account-Aktionen
              _buildSectionHeader('Account'),
              _buildSettingsCard(
                context,
                icon: Icons.delete,
                title: 'Account löschen',
                subtitle:
                    'Account löschen, Bewertungen bleiben anonym erhalten',
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
                isDanger: true,
              ),
              SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
              _buildSettingsCard(
                context,
                icon: Icons.exit_to_app,
                title: 'Abmelden',
                subtitle: 'Von Ihrem Account abmelden',
                onTap: () {
                  _showLogoutDialog(context);
                },
                isDanger: true,
              ),
              SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
              // App-Informationen
              _buildAppInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Header für Einstellungsabschnitte
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.s), // ✅ THEME ABSTAND
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
          fontWeight: FontWeight.bold,
          color: AppColors.primary, // ✅ THEME FARBE
        ),
      ),
    );
  }

  // Einstellungs-Karte
  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDanger
              ? AppColors.error
              : AppColors.primary, // ✅ THEME FARBE
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDanger
                ? AppColors.error
                : AppColors.textPrimary, // ✅ THEME FARBE
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
            color: isDanger
                ? AppColors.error.withOpacity(0.7) // ✅ THEME FARBE
                : AppColors.textSecondary, // ✅ THEME FARBE
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDanger
              ? AppColors.error
              : AppColors.textSecondary, // ✅ THEME FARBE
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.m),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(), // ✅ Einmalig ausführen
        builder: (context, snapshot) {
          String version = '1.0.0'; // Fallback
          String buildNumber = '1'; // Fallback

          if (snapshot.hasData) {
            version = snapshot.data!.version;
            buildNumber = snapshot.data!.buildNumber;
          } else if (snapshot.hasError) {
            print('Fehler beim Laden der App-Info: ${snapshot.error}');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App-Informationen',
                style: TextStyle(
                  fontSize: AppTypography.headline3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.s),
              Text(
                'Version: $version', // ✅ Dynamisch
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Build: $buildNumber', // ✅ Dynamisch
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppSpacing.s),
              Text(
                '© ${DateTime.now().year} RateMyFlat. Alle Rechte vorbehalten.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Feature coming soon Dialog
  void _showFeatureComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Demnächst verfügbar'),
          content: Text(
            'Diese Funktion wird in einer zukünftigen Version der App verfügbar sein.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Verstanden'),
            ),
          ],
        );
      },
    );
  }

  // Methode zum Ausloggen
  // Methode zum Ausloggen - KORRIGIERT
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Abmelden'),
          content: Text(
            'Möchten Sie sich wirklich von Ihrem Account abmelden?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context); // Schließe den Dialog

                  // WICHTIG: Navigiere explizit zum Login-Screen
                  // Lösche alle bisherigen Routes und gehe zum Login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ), // ODER deine Login-Screen-Klasse
                    (route) => false,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erfolgreich abgemeldet'),
                        backgroundColor: AppColors.success, // ✅ THEME FARBE
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Schließe den Dialog
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler beim Abmelden'),
                        backgroundColor: AppColors.error, // ✅ THEME FARBE
                      ),
                    );
                  }
                  print('Fehler beim Ausloggen: $e');
                }
              },
              child: Text('Abmelden'),
            ),
          ],
        );
      },
    );
  }

  // Account-Löschungsdialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DeleteAccountDialog(
          onDeleteConfirmed: () async {
            Navigator.pop(context); // Schließe den Bestätigungsdialog
            await _deleteUserAccount(context);
          },
        );
      },
    );
  }

  // Account-Löschungslogik
  Future<void> _deleteUserAccount(BuildContext context) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Referenz zum Dialog-Kontext speichern
    BuildContext? dialogContext;

    try {
      // Zeige ersten Fortschrittsdialog und speichere den Kontext
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext buildContext) {
          dialogContext = buildContext; // Speichere den Dialog-Kontext
          return AlertDialog(
            title: Text('Lösche Account...'),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: AppSpacing.s),
                Text('Bitte warten...'),
              ],
            ),
          );
        },
      );

      await Future.delayed(Duration(milliseconds: 100));

      // 1. Anonymisiere alle Bewertungen des Users
      await _anonymizeUserReviews(currentUser.uid);

      // 2. Lösche das User-Profil in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .delete();

      // 3. Versuche den Firebase Auth Account zu löschen - ERSTER VERSUCH
      bool deletionSuccessful = false;
      bool requiresReauth = false;

      try {
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null) {
          await freshUser.delete();
          deletionSuccessful = true;
        }
      } on FirebaseAuthException catch (authError) {
        if (authError.code == 'requires-recent-login') {
          requiresReauth = true;
        } else {
          rethrow;
        }
      }

      // Schließe den ersten Dialog mit dem gespeicherten Kontext
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Wenn Re-Auth benötigt wird
      if (requiresReauth) {
        final bool reauthSuccess = await _showReauthenticateDialog(context);

        if (reauthSuccess) {
          BuildContext? secondDialogContext;

          // Zeige zweiten Fortschrittsdialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext buildContext) {
              secondDialogContext =
                  buildContext; // Speichere den Dialog-Kontext
              return AlertDialog(
                title: Text('Lösche Account...'),
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: AppSpacing.s),
                    Text('Bitte warten...'),
                  ],
                ),
              );
            },
          );

          await Future.delayed(Duration(milliseconds: 100));

          // ZWEITTER VERSUCH: Account löschen
          final secondUser = FirebaseAuth.instance.currentUser;
          if (secondUser != null) {
            await secondUser.delete();
          }

          // Schließe zweiten Dialog mit dem gespeicherten Kontext
          if (secondDialogContext != null && secondDialogContext!.mounted) {
            Navigator.of(secondDialogContext!, rootNavigator: true).pop();
          } else if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          deletionSuccessful = true;
        } else {
          // User hat abgebrochen
          return;
        }
      }

      // Zeige Erfolgsmeldung und führe Logout durch
      if (deletionSuccessful) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account erfolgreich gelöscht. Bewertungen bleiben anonym erhalten.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }

        // Warte kurz damit der SnackBar angezeigt wird
        await Future.delayed(Duration(seconds: 2));

        // App schließen statt zur Login-Seite navigieren
        try {
          // Plattformübergreifende Methode
          SystemNavigator.pop();
        } catch (e) {
          print('Fehler beim Schließen der App: $e');
          // Fallback für Android
          try {
            if (Platform.isAndroid) {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          } catch (fallbackError) {
            print('Fallback Fehler: $fallbackError');
            // Letzter Ausweg
            if (Platform.isAndroid) {
              exit(0);
            }
          }
        }

        // Führe den gleichen Logout-Prozess wie in _showLogoutDialog durch
        if (context.mounted) {
          Navigator.pop(context); // Schließe den Settings-Screen wenn nötig

          // WICHTIG: Navigiere explizit zum Login-Screen
          // Lösche alle bisherigen Routes und gehe zum Login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Schließe alle offenen Dialoge
      try {
        // Schließe den aktuellen Dialog
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } else if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}

      if (context.mounted) {
        String errorMessage = 'Fehler beim Löschen des Accounts';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'requires-recent-login':
              errorMessage =
                  'Sie müssen sich erneut anmelden, um den Account zu löschen';
              break;
            case 'user-not-found':
              errorMessage = 'Benutzer nicht gefunden';
              break;
            default:
              errorMessage = e.message ?? 'Unbekannter Fehler beim Löschen';
          }
        } else {
          errorMessage = e.toString().contains(': ')
              ? e.toString().split(': ').last
              : e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Anonymisiere User-Bewertungen
  Future<void> _anonymizeUserReviews(String userId) async {
    try {
      print('Starte Anonymisierung für userId: $userId');

      // 1. Anonymisiere Bewertungen in Apartments - Durchsuche alle Dokumente
      final apartmentSnapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .get();

      print('Durchsuche ${apartmentSnapshot.docs.length} Apartments');

      for (var doc in apartmentSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final reviews = data['reviews'] as List<dynamic>? ?? [];
          if (reviews.isEmpty) continue;

          bool needsUpdate = false;
          final updatedReviews = <Map<String, dynamic>>[];

          for (var review in reviews) {
            if (review is Map<String, dynamic>) {
              if (review['userId'] == userId) {
                // Anonymisiere diese Bewertung
                final anonymizedReview = Map<String, dynamic>.from(review);
                anonymizedReview['userId'] = 'anonymous';
                anonymizedReview['username'] = 'Anonymous';
                anonymizedReview['profileImageUrl'] = '';
                anonymizedReview['isAnonymous'] = true;
                updatedReviews.add(anonymizedReview);
                needsUpdate = true;
                print('Anonymisiere Bewertung in Apartment ${doc.id}');
              } else {
                updatedReviews.add(review);
              }
            } else {
              updatedReviews.add(review);
            }
          }

          if (needsUpdate) {
            await FirebaseFirestore.instance
                .collection('apartments')
                .doc(doc.id)
                .update({'reviews': updatedReviews});
            print('Aktualisierte Bewertungen in Apartment ${doc.id}');
          }
        } catch (e) {
          print('Fehler beim Verarbeiten von Apartment ${doc.id}: $e');
        }
      }

      // 2. Anonymisiere Bewertungen in Landlords - Durchsuche alle Dokumente
      final landlordSnapshot = await FirebaseFirestore.instance
          .collection('landlords')
          .get();

      print('Durchsuche ${landlordSnapshot.docs.length} Landlords');

      for (var doc in landlordSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final reviews = data['reviews'] as List<dynamic>? ?? [];
          if (reviews.isEmpty) continue;

          bool needsUpdate = false;
          final updatedReviews = <Map<String, dynamic>>[];

          for (var review in reviews) {
            if (review is Map<String, dynamic>) {
              if (review['userId'] == userId) {
                // Anonymisiere diese Bewertung
                final anonymizedReview = Map<String, dynamic>.from(review);
                anonymizedReview['userId'] = 'anonymous';
                anonymizedReview['username'] = 'Anonymous';
                anonymizedReview['profileImageUrl'] = '';
                anonymizedReview['isAnonymous'] = true;
                updatedReviews.add(anonymizedReview);
                needsUpdate = true;
                print('Anonymisiere Bewertung in Landlord ${doc.id}');
              } else {
                updatedReviews.add(review);
              }
            } else {
              updatedReviews.add(review);
            }
          }

          if (needsUpdate) {
            await FirebaseFirestore.instance
                .collection('landlords')
                .doc(doc.id)
                .update({'reviews': updatedReviews});
            print('Aktualisierte Bewertungen in Landlord ${doc.id}');
          }
        } catch (e) {
          print('Fehler beim Verarbeiten von Landlord ${doc.id}: $e');
        }
      }

      print('Anonymisierung abgeschlossen');
    } catch (e) {
      print('Schwerwiegender Fehler beim Anonymisieren der Bewertungen: $e');
      // Nicht kritisch - der Account kann trotzdem gelöscht werden
    }
  }

  // Re-Authentifizierungsdialog
  Future<bool> _showReauthenticateDialog(BuildContext context) async {
    final TextEditingController _passwordController = TextEditingController();
    final Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Erneute Anmeldung erforderlich'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aus Sicherheitsgründen müssen Sie sich erneut anmelden, um Ihren Account zu löschen.',
              ),
              SizedBox(height: AppSpacing.m),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                completer.complete(false);
              },
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                if (_passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Bitte geben Sie Ihr Passwort ein'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Zeige Fortschrittsdialog
                Navigator.pop(dialogContext); // Schließe Reauth-Dialog

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext progressDialogContext) {
                    return AlertDialog(
                      title: Text('Anmeldung...'),
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: AppSpacing.s),
                          Text('Bitte warten...'),
                        ],
                      ),
                    );
                  },
                );

                try {
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: _passwordController.text,
                    );

                    await user.reauthenticateWithCredential(credential);

                    // Schließe Fortschrittsdialog
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erfolgreich angemeldet.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }

                    completer.complete(true);
                  } else {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    completer.complete(false);
                  }
                } catch (e) {
                  // Schließe Fortschrittsdialog
                  try {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (_) {}

                  if (context.mounted) {
                    String errorMessage = 'Fehler bei der Anmeldung';
                    if (e is FirebaseAuthException) {
                      if (e.code == 'wrong-password') {
                        errorMessage = 'Falsches Passwort';
                      } else if (e.code == 'user-not-found') {
                        errorMessage = 'User nicht gefunden';
                      } else {
                        errorMessage = e.message ?? 'Anmeldefehler';
                      }
                    } else {
                      errorMessage = e.toString().contains(': ')
                          ? e.toString().split(': ').last
                          : 'Anmeldefehler';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }

                  completer.complete(false);
                }
              },
              child: Text('Anmelden'),
            ),
          ],
        );
      },
    );

    // Dispose des Controllers nach Abschluss
    completer.future.whenComplete(() {
      _passwordController.dispose();
    });

    return completer.future;
  }
}

// Anonymisiere User-Bewertungen
Future<void> _anonymizeUserReviews(String userId) async {
  try {
    print('Starte Anonymisierung für userId: $userId');

    // 1. Anonymisiere Bewertungen in Apartments - Durchsuche alle Dokumente
    final apartmentSnapshot = await FirebaseFirestore.instance
        .collection('apartments')
        .get();

    print('Durchsuche ${apartmentSnapshot.docs.length} Apartments');

    for (var doc in apartmentSnapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final reviews = data['reviews'] as List<dynamic>? ?? [];
        if (reviews.isEmpty) continue;

        bool needsUpdate = false;
        final updatedReviews = <Map<String, dynamic>>[];

        for (var review in reviews) {
          if (review is Map<String, dynamic>) {
            if (review['userId'] == userId) {
              // Anonymisiere diese Bewertung
              final anonymizedReview = Map<String, dynamic>.from(review);
              anonymizedReview['userId'] = 'anonymous';
              anonymizedReview['username'] = 'Anonymous';
              anonymizedReview['profileImageUrl'] = '';
              anonymizedReview['isAnonymous'] = true;
              updatedReviews.add(anonymizedReview);
              needsUpdate = true;
              print('Anonymisiere Bewertung in Apartment ${doc.id}');
            } else {
              updatedReviews.add(review);
            }
          } else {
            updatedReviews.add(review);
          }
        }

        if (needsUpdate) {
          await FirebaseFirestore.instance
              .collection('apartments')
              .doc(doc.id)
              .update({'reviews': updatedReviews});
          print('Aktualisierte Bewertungen in Apartment ${doc.id}');
        }
      } catch (e) {
        print('Fehler beim Verarbeiten von Apartment ${doc.id}: $e');
      }
    }

    // 2. Anonymisiere Bewertungen in Landlords - Durchsuche alle Dokumente
    final landlordSnapshot = await FirebaseFirestore.instance
        .collection('landlords')
        .get();

    print('Durchsuche ${landlordSnapshot.docs.length} Landlords');

    for (var doc in landlordSnapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final reviews = data['reviews'] as List<dynamic>? ?? [];
        if (reviews.isEmpty) continue;

        bool needsUpdate = false;
        final updatedReviews = <Map<String, dynamic>>[];

        for (var review in reviews) {
          if (review is Map<String, dynamic>) {
            if (review['userId'] == userId) {
              // Anonymisiere diese Bewertung
              final anonymizedReview = Map<String, dynamic>.from(review);
              anonymizedReview['userId'] = 'anonymous';
              anonymizedReview['username'] = 'Anonymous';
              anonymizedReview['profileImageUrl'] = '';
              anonymizedReview['isAnonymous'] = true;
              updatedReviews.add(anonymizedReview);
              needsUpdate = true;
              print('Anonymisiere Bewertung in Landlord ${doc.id}');
            } else {
              updatedReviews.add(review);
            }
          } else {
            updatedReviews.add(review);
          }
        }

        if (needsUpdate) {
          await FirebaseFirestore.instance
              .collection('landlords')
              .doc(doc.id)
              .update({'reviews': updatedReviews});
          print('Aktualisierte Bewertungen in Landlord ${doc.id}');
        }
      } catch (e) {
        print('Fehler beim Verarbeiten von Landlord ${doc.id}: $e');
      }
    }

    print('Anonymisierung abgeschlossen');
  } catch (e) {
    print('Schwerwiegender Fehler beim Anonymisieren der Bewertungen: $e');
    // Nicht kritisch - der Account kann trotzdem gelöscht werden
  }
}

// Separate Dialog-Klasse für die Account-Löschung
class DeleteAccountDialog extends StatefulWidget {
  final Function()? onDeleteConfirmed;

  const DeleteAccountDialog({Key? key, this.onDeleteConfirmed})
    : super(key: key);

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Account löschen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Möchten Sie Ihren Account wirklich löschen?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wichtige Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Ihr Account und alle persönlichen Daten werden gelöscht\n'
                    '• Ihre Bewertungen bleiben anonym erhalten\n'
                    '• Dieser Vorgang kann nicht rückgängig gemacht werden',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmationController,
              decoration: InputDecoration(
                labelText: 'Geben Sie "LÖSCHEN" ein, um zu bestätigen',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            if (_confirmationController.text.trim() == 'LÖSCHEN') {
              Navigator.pop(context);
              if (widget.onDeleteConfirmed != null) {
                widget.onDeleteConfirmed!();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bitte geben Sie "LÖSCHEN" ein, um zu bestätigen',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Löschen', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
