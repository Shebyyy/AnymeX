import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../constants/theme_paths.dart';
import '../utils/logger.dart';

/// File utilities for custom theme management
class FileUtils {
  /// Request storage permission (Android only)
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if theme directory exists and is accessible
  static Future<bool> isThemeDirectoryAccessible() async {
    try {
      final dir = Directory(ThemePaths.baseDir);
      return await dir.exists();
    } catch (e) {
      Logger.i('Error checking theme directory: $e');
      return false;
    }
  }

  /// Get list of all custom theme files by type
  static Future<List<File>> getThemeFiles(String type) async {
    String dirPath;
    switch (type) {
      case 'player':
        dirPath = ThemePaths.playerThemesDir;
        break;
      case 'reader':
        dirPath = ThemePaths.readerThemesDir;
        break;
      case 'media_indicator':
        dirPath = ThemePaths.mediaIndicatorThemesDir;
        break;
      default:
        return [];
    }

    final directory = Directory(dirPath);
    if (!await directory.exists()) return [];

    try {
      return directory
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
    } catch (e) {
      Logger.i('Error getting theme files: $e');
      return [];
    }
  }

  /// Read a theme file content
  static Future<String?> readThemeFile(String fileName, String type) async {
    try {
      String dirPath;
      switch (type) {
        case 'player':
          dirPath = ThemePaths.playerThemesDir;
          break;
        case 'reader':
          dirPath = ThemePaths.readerThemesDir;
          break;
        case 'media_indicator':
          dirPath = ThemePaths.mediaIndicatorThemesDir;
          break;
        default:
          return null;
      }

      final file = File('$dirPath/$fileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      Logger.i('Failed to read theme file: $e');
      return null;
    }
  }

  /// Write content to a theme file
  static Future<bool> writeThemeFile(
    String fileName,
    String type,
    String content,
  ) async {
    try {
      String dirPath;
      switch (type) {
        case 'player':
          dirPath = ThemePaths.playerThemesDir;
          break;
        case 'reader':
          dirPath = ThemePaths.readerThemesDir;
          break;
        case 'media_indicator':
          dirPath = ThemePaths.mediaIndicatorThemesDir;
          break;
        default:
          return false;
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('$dirPath/$fileName');
      await file.writeAsString(content);
      Logger.i('Wrote theme file: ${file.path}');
      return true;
    } catch (e) {
      Logger.i('Failed to write theme file: $e');
      return false;
    }
  }

  /// Delete a theme file
  static Future<bool> deleteThemeFile(String fileName, String type) async {
    try {
      String dirPath;
      switch (type) {
        case 'player':
          dirPath = ThemePaths.playerThemesDir;
          break;
        case 'reader':
          dirPath = ThemePaths.readerThemesDir;
          break;
        case 'media_indicator':
          dirPath = ThemePaths.mediaIndicatorThemesDir;
          break;
        default:
          return false;
      }

      final file = File('$dirPath/$fileName');
      if (await file.exists()) {
        await file.delete();
        Logger.i('Deleted theme file: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Failed to delete theme file: $e');
      return false;
    }
  }
}
