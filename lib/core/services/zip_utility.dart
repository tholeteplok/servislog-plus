import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'settings_backup_service.dart';

class ZipUtility {
  /// Creates a ZIP archive containing settings, media, and database.
  static Future<File> createBackupZip(String settingsJson) async {
    final archive = Archive();
    final appDocDir = await getApplicationDocumentsDirectory();

    // Add settings.json
    final settingsData = utf8.encode(settingsJson);
    archive.addFile(
      ArchiveFile('settings.json', settingsData.length, settingsData),
    );

    // Directories to backup
    final directories = ['media', 'objectbox'];

    for (final dirName in directories) {
      final dir = Directory(p.join(appDocDir.path, dirName));
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (var entity in files) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: appDocDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }
      }
    }

    // Encode ZIP and save to temp
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData == null) throw Exception('Gagal membuat arsip ZIP');

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File(
      p.join(tempDir.path, 'servislog_backup_temp_$timestamp.zip'),
    );
    return await zipFile.writeAsBytes(zipData);
  }

  /// Extracts a ZIP archive and overwrites local data.
  static Future<void> extractRestoreZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(bytes);
    final appDocDir = await getApplicationDocumentsDirectory();

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;

        if (filename == 'settings.json') {
          // Special handling for settings to ensure Cross-Platform Compatibility
          final jsonStr = utf8.decode(data);
          await SettingsBackupService.importFromJson(jsonStr);
        } else {
          // General files (Media, ObjectBox)
          final outFile = File(p.join(appDocDir.path, filename));
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }
    }
  }
}
