import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'auth_service.dart';
import 'zip_utility.dart';
import 'settings_backup_service.dart';

class DriveBackupService {
  static final DriveBackupService _instance = DriveBackupService._internal();
  factory DriveBackupService() => _instance;
  DriveBackupService._internal();

  final AuthService _authService = AuthService();

  /// Uploads a new backup ZIP to the hidden appDataFolder.
  Future<void> uploadBackup() async {
    final client = await _authService.getAuthenticatedClient();
    final drive = drive_api.DriveApi(client);

    try {
      final settingsJson = await SettingsBackupService.exportToJson();
      final zipFile = await ZipUtility.createBackupZip(settingsJson);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'servislog_backup_v1_$timestamp.zip';

      final media = drive_api.Media(zipFile.openRead(), zipFile.lengthSync());
      final driveFile = drive_api.File()
        ..name = fileName
        ..parents = ['appDataFolder'];

      await drive.files.create(driveFile, uploadMedia: media);

      // Cleanup temp zip
      if (await zipFile.exists()) await zipFile.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Finds and downloads the latest backup from Drive.
  Future<File?> downloadLatestBackup() async {
    final client = await _authService.getAuthenticatedClient();
    final drive = drive_api.DriveApi(client);

    try {
      // List files in appDataFolder, ordered by createdTime descending
      final fileList = await drive.files.list(
        q: "name contains 'servislog_backup_v1' and trashed = false",
        spaces: 'appDataFolder',
        orderBy: 'createdTime desc',
        pageSize: 1,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }

      final latestFile = fileList.files!.first;
      final fileId = latestFile.id!;

      final drive_api.Media media =
          await drive.files.get(
                fileId,
                downloadOptions: drive_api.DownloadOptions.fullMedia,
              )
              as drive_api.Media;

      final tempDir = await getTemporaryDirectory();
      final destinationFile = File(
        p.join(tempDir.path, 'downloaded_backup.zip'),
      );

      final IOSink sink = destinationFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return destinationFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if any backup exists in Drive.
  Future<bool> hasBackupOnDrive() async {
    final client = await _authService.getAuthenticatedClient();
    final drive = drive_api.DriveApi(client);

    final fileList = await drive.files.list(
      q: "name contains 'servislog_backup_v1' and trashed = false",
      spaces: 'appDataFolder',
      pageSize: 1,
    );

    return fileList.files != null && fileList.files!.isNotEmpty;
  }

  /// Deletes all backup files from Drive appDataFolder.
  Future<void> deleteAllBackups() async {
    final client = await _authService.getAuthenticatedClient();
    final drive = drive_api.DriveApi(client);

    try {
      // List all backup files
      final fileList = await drive.files.list(
        q: "name contains 'servislog_backup_v1' and trashed = false",
        spaces: 'appDataFolder',
      );

      if (fileList.files == null || fileList.files!.isEmpty) return;

      for (var file in fileList.files!) {
        if (file.id != null) {
          await drive.files.delete(file.id!);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
