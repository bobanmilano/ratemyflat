// lib/screens/tenant_verification_screen.dart
import 'package:flutter/material.dart';

class TenantVerificationScreen extends StatefulWidget {
  final bool isApartment;
  final String targetName;

  const TenantVerificationScreen({
    Key? key,
    required this.isApartment,
    required this.targetName,
  }) : super(key: key);

  @override
  _TenantVerificationScreenState createState() =>
      _TenantVerificationScreenState();
}

class _TenantVerificationScreenState extends State<TenantVerificationScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isApartment ? 'Wohnung bewerten' : 'Vermieter bewerten',
        ),
      ),
      body: SingleChildScrollView(
        // ScrollView hinzugefügt
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bestätigung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Für: ${widget.targetName}',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Wichtige Hinweise',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Unser Ziel ist es Mietern eine faire, aktuelle und objektive '
                      'Beurteilung von Wohnungen und Vermietern zur Verfügung zu stellen! '
                      'Bitte beachten Sie bei Ihrer Beurteilung folgende Punkte:',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(height: 12),

                  _buildVerificationPoint(
                    'Persönliche Erfahrung',
                    'Ich bin/war ${widget.isApartment ? 'Mieter dieser Wohnung' : 'Kunde dieses Vermieters'}',
                  ),

                  _buildVerificationPoint(
                    'Wahrheitsgemäße Angaben',
                    'Meine Bewertung basiert auf tatsächlicher Erfahrung',
                  ),

                  _buildVerificationPoint(
                    'Keine Diffamierung',
                    'Ich mache keine falschen oder beleidigenden Aussagen',
                  ),

                  _buildVerificationPoint(
                    'Keine kommerziellen Interessen',
                    'Ich habe kein geschäftliches Interesse',
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            CheckboxListTile(
              title: Text(
                'Ich bestätige, dass ich Mieter bin/war und die Angaben wahr sind',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              value: _isChecked,
              onChanged: (value) {
                setState(() {
                  _isChecked = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true, // Kompakter
            ),

            SizedBox(height: 16),

            // Kompakte Button-Leiste
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40, // Feste Höhe
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Abbrechen', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40, // Feste Höhe
                    child: ElevatedButton(
                      onPressed: _isChecked
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: Text('Weiter', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
