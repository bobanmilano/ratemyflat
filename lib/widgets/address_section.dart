// lib/widgets/address_section.dart
import 'package:flutter/material.dart';
import 'package:immo_app/theme/app_theme.dart';

class AddressSection extends StatefulWidget {
  final TextEditingController streetController;
  final TextEditingController houseNumberController;
  final TextEditingController topStiegeHausController;
  final TextEditingController zipCodeController;
  final TextEditingController cityController;
  final String selectedCountry;
  final List<String> countryOptions;
  final Function(String) onCountryChanged;

  const AddressSection({
    Key? key,
    required this.streetController,
    required this.houseNumberController,
    required this.topStiegeHausController,
    required this.zipCodeController,
    required this.cityController,
    required this.selectedCountry,
    required this.countryOptions,
    required this.onCountryChanged,
  }) : super(key: key);

  @override
  _AddressSectionState createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresse *',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ Korrekte Konstante
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s),
            // Erste Zeile - Straße, Hausnummer, Top/Stiege
            LayoutBuilder(
              builder: (context, constraints) {
                // Prüfe ob genug Platz für alle Felder ist
                if (constraints.maxWidth > 600) {
                  // Auf großen Bildschirmen: Alle Felder nebeneinander
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: widget.streetController,
                          decoration: InputDecoration(
                            labelText: 'Straße *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: widget.houseNumberController,
                          decoration: InputDecoration(
                            labelText: 'Nr. *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: widget.topStiegeHausController,
                          decoration: InputDecoration(
                            labelText: 'Top/Stiege',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Auf kleinen Bildschirmen: Stapeln
                  return Column(
                    children: [
                      TextField(
                        controller: widget.streetController,
                        decoration: InputDecoration(
                          labelText: 'Straße *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.houseNumberController,
                              decoration: InputDecoration(
                                labelText: 'Nr. *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: TextField(
                              controller: widget.topStiegeHausController,
                              decoration: InputDecoration(
                                labelText: 'Top/Stiege',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: AppSpacing.s),
            // Zweite Zeile - PLZ, Stadt, Land
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  // Auf größeren Bildschirmen: Nebeneinander
                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: widget.zipCodeController,
                          decoration: InputDecoration(
                            labelText: 'PLZ *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: widget.cityController,
                          decoration: InputDecoration(
                            labelText: 'Stadt *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: widget.selectedCountry,
                          items: widget.countryOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option, 
                              child: Text(
                                option,
                                style: TextStyle(fontSize: AppTypography.bodySmall),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            widget.onCountryChanged(value ?? 'Deutschland');
                          },
                          decoration: InputDecoration(
                            labelText: 'Land',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Auf kleinen Bildschirmen: Stapeln
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.zipCodeController,
                              decoration: InputDecoration(
                                labelText: 'PLZ *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: TextField(
                              controller: widget.cityController,
                              decoration: InputDecoration(
                                labelText: 'Stadt *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: widget.selectedCountry,
                        items: widget.countryOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option, 
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          widget.onCountryChanged(value ?? 'Deutschland');
                        },
                        decoration: InputDecoration(
                          labelText: 'Land',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}