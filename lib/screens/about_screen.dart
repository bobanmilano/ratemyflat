// lib/screens/about_screen.dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Über uns'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-Bild oder Icon (optional)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.house,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Hauptüberschrift
            Text(
              'Unsere Mission',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            
            // Beschreibungstext
            Text(
              'Willkommen bei Ihrer Mieter-Schutz-App! Wir glauben daran, '
              'dass jeder Mieter das Recht auf eine faire und transparente '
              'Wohnungssuche hat. Unser Ziel ist es, die Macht des Wissens '
              'zurück an die Mieter zu geben.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24),
            
            // Hauptpunkte als Karten
            _buildInfoCard(
              context,
              icon: Icons.shield,
              title: 'Schutz vor unseriösen Vermietern',
              content: 'Wir schützen Mieter vor unseriösen Vermietern und '
                  'betrügerischen Angeboten. Durch transparente Bewertungen '
                  'und Erfahrungsberichte können Sie fundierte Entscheidungen treffen.',
            ),
            
            SizedBox(height: 16),
            
            _buildInfoCard(
              context,
              icon: Icons.share,
              title: 'Erfahrungen teilen',
              content: 'Mieter können ihre Erfahrungen mit bestimmten '
                  'Wohnungen und Vermietern teilen. Positive wie negative '
                  'Erfahrungen helfen anderen Mieterinnen und Mietern bei '
                  'ihrer Entscheidungsfindung.',
            ),
            
            SizedBox(height: 16),
            
            _buildInfoCard(
              context,
              icon: Icons.warning,
              title: 'Problematische Angebote melden',
              content: 'Warnen Sie die Community vor problematischen '
                  'Vermietern und Wohnungen. Gemeinsam schaffen wir '
                  'Transparenz im Mietmarkt und verhindern betrügerische Praktiken.',
            ),
            
            SizedBox(height: 24),
            
            // Zusätzliche Punkte
            Text(
              'Weitere Vorteile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
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
              'Keine versteckten Gebühren oder Werbung',
            ),
            
            _buildFeatureItem(
              context,
              'Datenschutz',
              'Ihre Daten gehören Ihnen - wir respektieren Ihre Privatsphäre',
            ),
            
            SizedBox(height: 24),
            
            // Abschluss-Text
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handshake,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gemeinsam für faire Mietbedingungen!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Treten Sie unserer Community bei und tragen Sie dazu bei, '
                    'den Mietmarkt transparenter und fairer zu machen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Kontakt-Info (optional)
            Text(
              'Haben Sie Fragen oder Feedback?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Wir freuen uns über Ihre Rückmeldung! Kontaktieren Sie uns über '
              'die Einstellungen oder schreiben Sie uns direkt eine Nachricht.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
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
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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