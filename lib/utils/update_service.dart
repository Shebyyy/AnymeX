import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:developer';

class DownloadProgress {
  final int receivedBytes;
  final int totalBytes;

  DownloadProgress(this.receivedBytes, this.totalBytes);

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
  double get percent => progress; // Alias for convenience
}

class UpdateService {
  final Dio _dio = Dio();

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 8.0 (API 26) and above, need REQUEST_INSTALL_PACKAGES
      // For older versions, WRITE_EXTERNAL_STORAGE might be needed if not using app-specific directory
      // but getExternalStorageDirectory() for APKs usually doesn't need explicit write permission.
      // However, installing unknown apps is the main permission.
      
      var installStatus = await Permission.requestInstallPackages.status;
      log("Initial install permission status: $installStatus");

      if (!installStatus.isGranted) {
        installStatus = await Permission.requestInstallPackages.request();
        log("After request, install permission status: $installStatus");
      }
      
      if (!installStatus.isGranted) {
        log("Install packages permission not granted.");
        // Optionally, guide user to settings:
        // await openAppSettings();
        return false;
      }
      return true;
    }
    return true; // For other platforms, assume permissions are handled differently or not needed for this flow
  }

  Future<void> downloadAndInstallApk({
    required String url,
    required String fileName,
    required Function(DownloadProgress) onReceiveProgress,
    required Function() onCompleted,
    required Function(String) onError,
  }) async {
    if (!await _requestPermissions()) {
      onError("Permissions not granted to install updates.");
      return;
    }

    try {
      // Get a directory for storing the download.
      // getExternalStorageDirectory() is usually /storage/emulated/0/Android/data/<package_name>/files
      // or just /storage/emulated/0/Download on some devices if permission is there
      Directory? dir;
      if (Platform.isAndroid) {
        // Using getExternalStorageDirectory often points to a public directory like 'Downloads'
        // or an app-specific one depending on manifest and Android version.
        // For broader compatibility and easier user access if needed, getExternalStoragePublicDirectory can be an option
        // but requires more careful permission handling (MANAGE_EXTERNAL_STORAGE or legacy WRITE_EXTERNAL_STORAGE).
        // getApplicationDocumentsDirectory is private to the app.
        dir = await getTemporaryDirectory(); // Or getApplicationDocumentsDirectory()
      } else {
        dir = await getApplicationDocumentsDirectory(); // For iOS/macOS etc. (though APKs are Android specific)
      }

      if (dir == null) {
        onError("Could not get download directory.");
        return;
      }
      
      final String savePath = "${dir.path}/$fileName";
      log("Download path: $savePath");

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) { // Total size known
            onReceiveProgress(DownloadProgress(received, total));
          } else { // Total size unknown (less common for direct file downloads)
             onReceiveProgress(DownloadProgress(received, 0)); // Indicate progress without percentage
          }
        },
        deleteOnError: true, // Delete partially downloaded file if error occurs
      );

      log("Download completed: $savePath");
      onCompleted(); // Notify UI download is complete

      // Open the downloaded APK file to trigger installation
      final OpenResult openResult = await OpenFilex.open(savePath, type: "application/vnd.android.package-archive");
      log("OpenFile result: ${openResult.type}, message: ${openResult.message}");

      if (openResult.type != ResultType.done) {
        onError("Could not start installation: ${openResult.message}");
      }

    } on DioException catch (e) {
      log("DioException during download: ${e.message}", error: e);
      String errorMsg = "Network error";
      if (e.response != null) {
        errorMsg = "Download failed: ${e.response?.statusCode}";
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMsg = "Connection timeout.";
      } else if (e.type == DioExceptionType.cancel) {
        errorMsg = "Download cancelled.";
        return; // Don't show error snackbar if deliberately cancelled
      }
      onError(errorMsg);
    } catch (e) {
      log("Error during download/install: $e", error: e);
      onError("An unexpected error occurred: ${e.toString()}");
    }
  }
}
