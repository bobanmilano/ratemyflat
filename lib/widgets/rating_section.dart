// lib/widgets/ratings_section.dart
import 'package:flutter/material.dart';
import 'package:immo_app/widgets/star_rating_widget.dart';
import 'package:immo_app/utils/rating_helper.dart';

class RatingsSection extends StatefulWidget {
  final Map<String, int> ratings;
  final bool isLandlord; // true für Vermieter, false für Wohnung

  const RatingsSection({
    Key? key,
    required this.ratings,
    this.isLandlord = false,
  }) : super(key: key);

  @override
  _RatingsSectionState createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<RatingsSection> {
  @override
  Widget build(BuildContext context) {
    final categories = widget.isLandlord 
        ? _getLandlordCategories()
        : _getApartmentCategories();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bewertungen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...categories.map((category) {
              return _buildRatingWidget(category);
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<String> _getApartmentCategories() {
    return [
      'condition', 'cleanliness', 'landlord', 'equipment', 'location',
      'transport', 'parking', 'neighbors', 'accessibility', 'leisure',
      'shopping', 'safety', 'valueForMoney'
    ];
  }

  List<String> _getLandlordCategories() {
    return [
      'communication', 'helpfulness', 'fairness', 'transparency',
      'responseTime', 'respect', 'renovationManagement', 'leaseAgreement',
      'operatingCosts', 'depositHandling'
    ];
  }

  Widget _buildRatingWidget(String key) {
    return Tooltip(
      message: RatingHelper.getTooltip(key),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(RatingHelper.getTooltip(key))),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  RatingHelper.getLabel(key),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.help_outline, size: 16, color: Colors.grey),
              ],
            ),
            SizedBox(height: 4),
            InteractiveStarRating(
              initialRating: widget.ratings[key] ?? 1,
              onRatingChanged: (rating) {
                setState(() {
                  widget.ratings[key] = rating;
                });
              },
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}