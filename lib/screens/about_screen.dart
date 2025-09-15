// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:immo_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Über uns'), 
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-Bild oder Icon (optional)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1), // ✅ THEME FARBE
                  borderRadius: BorderRadius.circular(60),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            // Hauptüberschrift
            Text(
              'Die Mission von RateMyFlat',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            // Beschreibungstext
            Text(
              'Willkommen bei Ihrer Mieter-Schutz-App RateMyFlat! Wir glauben daran, '
              'dass jeder Mieter das Recht auf eine faire und transparente '
              'Wohnungssuche hat. Unser Ziel ist es, die Macht des Wissens '
              'zurück an die Mieter zu geben.',
              style: TextStyle(
                fontSize: AppTypography.bodyLarge, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            // Hauptpunkte als Karten
            _buildInfoCard(
              context,
              icon: Icons.shield,
              title: 'Schutz vor unseriösen Vermietern',
              content:
                  'Wir schützen Mieter vor unseriösen Vermietern und '
                  'betrügerischen Angeboten. Durch transparente Bewertungen '
                  'und Erfahrungsberichte können Sie fundierte Entscheidungen treffen.',
            ),

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildInfoCard(
              context,
              icon: Icons.share,
              title: 'Erfahrungen teilen',
              content:
                  'Mieter können ihre Erfahrungen mit bestimmten '
                  'Wohnungen und Vermietern teilen. Positive wie negative '
                  'Erfahrungen helfen anderen Mieterinnen und Mietern bei '
                  'ihrer Entscheidungsfindung.',
            ),

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildInfoCard(
              context,
              icon: Icons.warning,
              title: 'Problematische Angebote melden',
              content:
                  'Warnen Sie die Community vor problematischen '
                  'Vermietern und Wohnungen. Gemeinsam schaffen wir '
                  'Transparenz im Mietmarkt und verhindern betrügerische Praktiken.',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            // Zusätzliche Punkte
            Text(
              'Weitere Vorteile',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildFeatureItem(
              context,
              'Transparente Bewertungen',
              'Ehrliche Meinungen von echten Mietern',
            ),

            _buildFeatureItem(
              context,
              'Community-basiert',
              'Von Mietern für Mieter - keine kommerziellen Interessen',
            ),

            _buildFeatureItem(
              context,
              'Aktuelle Informationen',
              'Immer auf dem neuesten Stand über Vermieter und Wohnungen',
            ),

            _buildFeatureItem(
              context,
              'Kostenlos & unabhängig',
              'Keine versteckten Kosten oder Gebühren',
            ),

            _buildFeatureItem(
              context,
              'Datenschutz',
              'Ihre Daten gehören Ihnen - wir respektieren Ihre Privatsphäre',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            // Abschluss-Text
            Container(
              padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // ✅ THEME FARBE
                borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handshake,
                    size: 40,
                    color: AppColors.primary, // ✅ THEME FARBE
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Text(
                    'Gemeinsam für faire Mietbedingungen!',
                    style: TextStyle(
                      fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary, // ✅ THEME FARBE
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Text(
                    'Treten Sie unserer Community bei und tragen Sie dazu bei, '
                    'den Mietmarkt transparenter und fairer zu machen.',
                    style: TextStyle(
                      fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                      color: AppColors.textPrimary, // ✅ THEME FARBE
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            // Kontakt-Info (optional)
            Text(
              'Haben Sie Fragen oder Feedback?',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              'Wir freuen uns über Ihre Rückmeldung! Kontaktieren Sie uns über '
              'die Einstellungen oder schreiben Sie uns direkt eine E-Mail-Nachricht.',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  size: 32, 
                  color: AppColors.primary, // ✅ THEME FARBE
                ),
                SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // ✅ THEME FARBE
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              content, 
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.s), // ✅ THEME ABSTAND
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary, // ✅ THEME FARBE
            size: 20,
          ),
          SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary, // ✅ THEME FARBE
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                    color: AppColors.textSecondary, // ✅ THEME FARBE
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}