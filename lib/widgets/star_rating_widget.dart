// lib/widgets/star_rating_widget.dart
import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingWidget({
    Key? key,
    required this.rating,
    this.maxStars = 5,
    this.size = 24,
    this.activeColor = Colors.orange,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    double fractionalPart = rating - fullStars;
    
    if (fractionalPart < 0.5) {
      fractionalPart = 0;
    } else if (fractionalPart >= 0.5 && fractionalPart < 1) {
      fractionalPart = 0.5;
    } else {
      fractionalPart = 1;
    }

    int emptyStars = maxStars - fullStars - (fractionalPart > 0 ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++) 
          Icon(Icons.star, color: activeColor, size: size),
        if (fractionalPart == 0.5) 
          Icon(Icons.star_half, color: activeColor, size: size),
        for (int i = 0; i < emptyStars; i++) 
          Icon(Icons.star_border, color: inactiveColor, size: size),
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final Function(int) onRatingChanged;
  final int initialRating; // Diesen Parameter behalten
  final int maxStars;
  final double size;

  const InteractiveStarRating({
    Key? key,
    required this.onRatingChanged,
    this.initialRating = 1, // Default auf 1 statt 0
    this.maxStars = 5,
    this.size = 32,
  }) : super(key: key);

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxStars, (index) {
        return InkWell(
          onTap: () {
            setState(() {
              _rating = index + 1;
              widget.onRatingChanged(_rating);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}