// lib/widgets/image_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSection extends StatefulWidget {
  final List<File> imageFiles;
  final Function(List<File>) onImagesChanged;

  const ImageSection({
    Key? key,
    required this.imageFiles,
    required this.onImagesChanged,
  }) : super(key: key);

  @override
  _ImageSectionState createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection> {
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    
    if (images != null) {
      final selectedImages = images.length > 5 ? images.take(5).toList() : images;
      final imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();
      
      widget.onImagesChanged(imageFiles);
      
      if (images.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Es können maximal 5 Bilder ausgewählt werden. ${images.length - 5} Bilder wurden ignoriert.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.imageFiles.length}/5 Bilder',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.imageFiles.length >= 5 ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.imageFiles.length >= 5 ? null : _pickImages,
              child: Text('Bilder auswählen (max. 5)'),
            ),
            if (widget.imageFiles.length >= 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Maximale Anzahl von 5 Bildern erreicht',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            SizedBox(height: 12),
            if (widget.imageFiles.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.imageFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}