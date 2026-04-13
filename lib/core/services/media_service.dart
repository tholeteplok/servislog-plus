import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Initial quality hint for picker
      maxWidth: 1920,   // High-res enough for details
    );

    if (pickedFile == null) return null;

    // Further compression using specialized library
    return await _compressImage(pickedFile);
  }

  Future<XFile?> _compressImage(XFile file) async {
    try {
      final String targetPath = p.join(
        (await getTemporaryDirectory()).path,
        "temp_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70, // Balanced quality vs size
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );

      return compressedFile;
    } catch (e) {
      // Fallback to original if compression fails
      return file;
    }
  }

  Future<String?> saveImageLocally(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(directory.path, 'media'));

      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final localPath = p.join(mediaDir.path, fileName);

      final File localFile = await File(image.path).copy(localPath);
      return localFile.path;
    } catch (e) {
      // Silently fail or use a logger (STEP 3+)
      return null;
    }
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
