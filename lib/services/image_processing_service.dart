// lib/services/image_processing_service.dart
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  /// Optimiert Bilder automatisch auf max. 200KB
  static Future<File> optimizeForMobile(File imageFile) async {
    try {
      // Prüfe zuerst ob Bild bereits klein genug ist
      if (isImageSizeValid(imageFile)) {
        return imageFile; // Keine Optimierung nötig
      }

      // Lese das Originalbild
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Konnte Bild nicht decodieren');
      }

      // Schrittweise Optimierung bis Zielgröße erreicht
      int maxWidth = 1024;
      int quality = 80;
      
      while (maxWidth >= 400 && quality >= 30) {
        // Verkleinere das Bild
        final resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.width <= image.height ? maxWidth : null,
        );

        // Konvertiere zu JPEG
        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);
        
        // Speichere temporär und prüfe Größe
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(resizedBytes);
        
        // Prüfe ob Größe okay ist
        if (isImageSizeValid(tempFile)) {
          print('Bild optimiert: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${getImageSizeInKB(tempFile).toStringAsFixed(1)}KB');
          return tempFile;
        }
        
        // Aufräumen
        await tempFile.delete();
        
        // Reduziere Qualität oder Größe
        if (quality > 40) {
          quality -= 10;
        } else {
          maxWidth -= 100;
          quality = 80; // Reset Qualität
        }
      }
      
      // Letzter Versuch mit minimalen Einstellungen
      final finalResized = img.copyResize(image, width: 400, height: 400);
      final finalBytes = img.encodeJpg(finalResized, quality: 30);
      final finalTempFile = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_final.jpg');
      await finalTempFile.writeAsBytes(finalBytes);
      
      return finalTempFile;
      
    } catch (e) {
      print('Fehler bei der Bildoptimierung: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Validiert die Bildgröße (max. 200KB)
  static bool isImageSizeValid(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    final sizeInKB = sizeInBytes / 1024;
    return sizeInKB <= 200; // Max. 200KB
  }

  /// Berechne Bildgröße in KB
  static double getImageSizeInKB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / 1024;
  }
}