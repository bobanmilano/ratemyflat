// lib/screens/tenant_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:immo_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

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
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        // ScrollView hinzugefügt
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bestätigung',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              'Für: ${widget.targetName}',
              style: TextStyle(
                color: AppColors.textSecondary, // ✅ THEME FARBE
                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            Container(
              padding: EdgeInsets.all(AppSpacing.s), // ✅ THEME ABSTAND
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1), // ✅ THEME FARBE
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ), // ✅ THEME RADIUS
                border: Border.all(color: AppColors.warning), // ✅ THEME FARBE
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: AppColors.success, // ✅ THEME FARBE
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                      Text(
                        'Wichtige Hinweise',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Container(
                    padding: EdgeInsets.all(AppSpacing.s), // ✅ THEME ABSTAND
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.1,
                      ), // ✅ THEME FARBE
                      borderRadius: BorderRadius.circular(
                        AppRadius.medium,
                      ), // ✅ THEME RADIUS
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                          0.3,
                        ), // ✅ THEME FARBE
                      ),
                    ),
                    child: Text(
                      'Unser Ziel ist es Mietern eine faire, aktuelle und objektive '
                      'Beurteilung von Wohnungen und Vermietern zur Verfügung zu stellen! '
                      'Bitte beachten Sie bei Ihrer Beurteilung folgende Punkte:',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                        color: AppColors.primary, // ✅ THEME FARBE
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

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

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            CheckboxListTile(
              title: Text(
                   widget.isApartment ? 'Ich bestätige, dass ich Mieter dieser Wohnung bin/war und die Angaben wahr sind' 
                   : 'Ich bestätige, dass ich Kunde dieses Vermieters bin/war und die Angaben wahr sind',
             
                style: TextStyle(
                  fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                  fontWeight: FontWeight.w500,
                ),
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

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            // Kompakte Button-Leiste
            // Kompakte Button-Leiste
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(fontSize: AppTypography.bodySmall),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.s),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isChecked
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Weiter',
                      style: TextStyle(fontSize: AppTypography.bodySmall),
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
      padding: EdgeInsets.only(bottom: AppSpacing.s), // ✅ THEME ABSTAND
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success, // ✅ THEME FARBE
            size: 16,
          ),
          SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTypography.caption, // ✅ THEME TYPOGRAFIE
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
