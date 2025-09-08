// lib/services/image_upload_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:immo_app/services/image_processing_service.dart';

class ImageUploadService {
static Future<List<String>> uploadImages(List<File> images) async {
  List<String> downloadUrls = [];
  
  for (var image in images) {
    try {
      // Optimize image before upload
      final optimizedImage = await ImageProcessingService.optimizeForMobile(image);
      
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('apartment_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(optimizedImage);
      TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
      String downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      
      // Delete temporary file
      if (optimizedImage.path != image.path) {
        await optimizedImage.delete();
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  return downloadUrls;
}
}