// lib/widgets/address_section.dart
import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresse *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: widget.streetController,
                    decoration: InputDecoration(
                      labelText: 'Straße *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: widget.houseNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nr. *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.topStiegeHausController,
                    decoration: InputDecoration(
                      labelText: 'Top/Stiege',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: widget.zipCodeController,
                    decoration: InputDecoration(
                      labelText: 'PLZ *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: widget.cityController,
                    decoration: InputDecoration(
                      labelText: 'Stadt *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: widget.selectedCountry,
                    items: widget.countryOptions.map((String option) {
                      return DropdownMenuItem<String>(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      widget.onCountryChanged(value ?? 'Deutschland');
                    },
                    decoration: InputDecoration(labelText: 'Land'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}