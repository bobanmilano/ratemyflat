// lib/widgets/comments_section.dart
import 'package:flutter/material.dart';

class CommentsSection extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;

  const CommentsSection({
    Key? key,
    required this.controller,
    this.labelText = 'Zusätzliche Kommentare *',
    this.hintText = 'Beschreiben Sie Ihre Erfahrung...',
  }) : super(key: key);

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
              labelText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: null,
              minLines: 4,
              maxLength: 800,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Kommentar *',
                hintText: hintText,
                alignLabelWithHint: true,
                helperText: 'Mindestens 20, maximal 800 Zeichen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}