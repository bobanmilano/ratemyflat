// lib/screens/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/screens/legal_screen.dart';
import 'package:immo_app/screens/login_screen.dart';
import 'package:immo_app/screens/profile_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              SizedBox(height: 16),

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
              SizedBox(height: 8),
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
              SizedBox(height: 16),

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
                      builder: (context) => LegalScreen(documentType: 'privacy'),
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 8),
              _buildSettingsCard(
                context,
                icon: Icons.info,
                title: 'Impressum',
                subtitle: 'Informationen zum Anbieter',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LegalScreen(documentType: 'imprint'),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Account-Aktionen
              _buildSectionHeader('Account'),
              _buildSettingsCard(
                context,
                icon: Icons.delete,
                title: 'Account löschen',
                subtitle: 'Account löschen, Bewertungen bleiben anonym erhalten',
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
                isDanger: true,
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 32),

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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : Theme.of(context).primaryColor,
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDanger ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDanger ? Colors.red.withOpacity(0.7) : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDanger ? Colors.red : Colors.grey,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  // App-Informationen
  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App-Informationen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              'Build: ${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} ImmoApp',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
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
                  MaterialPageRoute(builder: (context) => LoginScreen()), // ODER deine Login-Screen-Klasse
                  (route) => false,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erfolgreich abgemeldet')),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Schließe den Dialog
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Abmelden')),
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
// In deiner _deleteUserAccount Methode:
Future<void> _deleteUserAccount(BuildContext context) async {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // Zeige Fortschrittsdialog
  BuildContext? dialogContext;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext buildContext) {
      dialogContext = buildContext;
      return AlertDialog(
        title: Text('Lösche Account...'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Bitte warten...'),
          ],
        ),
      );
    },
  );

  try {
    // Warte kurz damit der Dialog sicher angezeigt wird
    await Future.delayed(Duration(milliseconds: 100));

    // 1. Anonymisiere alle Bewertungen des Users
    await _anonymizeUserReviews(currentUser.uid);

    // 2. Lösche das User-Profil in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .delete();

    // 3. WICHTIG: Lösche den Firebase Auth Account
    await currentUser.delete();

    // Schließe Fortschrittsdialog
    if (dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.pop(dialogContext!);
    }

    // Zeige Erfolgsmeldung
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account erfolgreich gelöscht. Bewertungen bleiben anonym erhalten.'),
          backgroundColor: Colors.green,
        ),
      );
    }

  } catch (e) {
    // Schließe Fortschrittsdialog bei Fehler
    try {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
    } catch (dialogError) {
      // Ignoriere Fehler beim Schließen
    }
    
    print('Fehler beim Löschen des Accounts: $e');
    
    // Zeige Fehlermeldung
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen des Accounts: ${e.toString().split(': ').last}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // Anonymisiere User-Bewertungen
  Future<void> _anonymizeUserReviews(String userId) async {
    try {
      // 1. Anonymisiere Bewertungen in Apartments
      final apartmentSnapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in apartmentSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reviews = data['reviews'] as List<dynamic>? ?? [];
        
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
            } else {
              updatedReviews.add(review);
            }
          }
        }

        if (needsUpdate) {
          await FirebaseFirestore.instance
              .collection('apartments')
              .doc(doc.id)
              .update({'reviews': updatedReviews});
        }
      }

      // 2. Anonymisiere Bewertungen in Landlords
      final landlordSnapshot = await FirebaseFirestore.instance
          .collection('landlords')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in landlordSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reviews = data['reviews'] as List<dynamic>? ?? [];
        
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
            } else {
              updatedReviews.add(review);
            }
          }
        }

        if (needsUpdate) {
          await FirebaseFirestore.instance
              .collection('landlords')
              .doc(doc.id)
              .update({'reviews': updatedReviews});
        }
      }

    } catch (e) {
      print('Fehler beim Anonymisieren der Bewertungen: $e');
      // Nicht kritisch - der Account kann trotzdem gelöscht werden
    }
  }
}

// Separate Dialog-Klasse für die Account-Löschung
class DeleteAccountDialog extends StatefulWidget {
  final Function()? onDeleteConfirmed;

  const DeleteAccountDialog({Key? key, this.onDeleteConfirmed}) : super(key: key);

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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
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
                  content: Text('Bitte geben Sie "LÖSCHEN" ein, um zu bestätigen'),
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