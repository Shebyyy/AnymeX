import 'dart:developer';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Keep for fallback/changelog page
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Added
import 'dart:io' show Platform; // Added

// Import the new UpdateService (we'll create this next)
import 'update_service.dart';

class UpdateChecker {
  static const String _repoUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeX/releases/latest';
  final UpdateService _updateService = UpdateService(); // Instantiate the service

  Future<void> checkForUpdates(
      BuildContext context, RxBool canShowUpdate) async {
    if (canShowUpdate.value) {
      canShowUpdate.value = false;
      try {
        final currentVersion = await _getCurrentVersion();
        final latestRelease = await _fetchLatestRelease();

        if (latestRelease != null &&
            _shouldUpdate(currentVersion, latestRelease['tag_name'])) {
          String? deviceAbi;
          if (Platform.isAndroid) {
            deviceAbi = await _getDeviceAbi();
          }

          // Find the appropriate asset
          Map<String, dynamic>? suitableAsset;
          if (latestRelease['assets'] != null && deviceAbi != null) {
            suitableAsset =
                _findSuitableAsset(latestRelease['assets'], deviceAbi);
          }

          _showUpdateBottomSheet(
            context,
            currentVersion,
            latestRelease['tag_name'],
            latestRelease['body'],
            latestRelease['html_url'], // Fallback URL to release page
            suitableAsset, // Pass the found asset
          );
        }
      } catch (e) {
        debugPrint('Error checking for updates: $e');
        snackBar('Error checking for updates: $e', isError: true);
      }
    } else {
      snackBar("Skipping Update Popup");
    }
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_repoUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint(
            'Failed to fetch latest release: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching latest release: $e');
    }
    return null;
  }

  Future<String?> _getDeviceAbi() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // supportedAbis usually lists the preferred ABI first.
      // Common ABIs: arm64-v8a, armeabi-v7a, x86_64, x86
      log("Supported ABIs: ${androidInfo.supportedAbis}");
      if (androidInfo.supportedAbis.isNotEmpty) {
        return androidInfo.supportedAbis[0]; // Get the primary ABI
      }
    }
    return null; // Or handle for other platforms if needed
  }

  Map<String, dynamic>? _findSuitableAsset(
      List<dynamic> assets, String deviceAbi) {
    // Prioritize specific ABI matches
    // Assuming asset names like: AnymeX-v1.2.3-arm64-v8a.apk, AnymeX-v1.2.3-armeabi-v7a.apk
    // Or simpler: app-arm64-v8a-release.apk
    for (var asset in assets) {
      String name = asset['name'].toString().toLowerCase();
      if (name.endsWith('.apk') && name.contains(deviceAbi.toLowerCase())) {
        log("Found direct ABI match: ${asset['name']} for ABI $deviceAbi");
        return asset;
      }
    }

    // Fallback: if device is arm64-v8a, it can also run armeabi-v7a
    if (deviceAbi.toLowerCase() == 'arm64-v8a') {
      for (var asset in assets) {
        String name = asset['name'].toString().toLowerCase();
        if (name.endsWith('.apk') && name.contains('armeabi-v7a')) {
          log("Found fallback ABI match (armeabi-v7a for arm64): ${asset['name']}");
          return asset;
        }
      }
    }
    
    // Fallback: Look for a generic apk if no specific ABI match found
    // e.g. app-release.apk or AnymeX-release.apk
    for (var asset in assets) {
      String name = asset['name'].toString().toLowerCase();
      if (name.endsWith('.apk') && !name.contains('-arm') && !name.contains('-x86')) {
         // A simple heuristic: if it doesn't specify an ABI, it might be universal or a default
        log("Found generic APK: ${asset['name']}");
        return asset;
      }
    }

    log("No suitable APK asset found for ABI: $deviceAbi in assets: ${assets.map((a) => a['name']).toList()}");
    return null; // No suitable asset found
  }

  bool _shouldUpdate(String currentVersion, String latestVersion) {
    // Remove 'v' prefix and any build metadata (e.g., -beta, -alpha)
    String cleanCurrentVersion = currentVersion.replaceAll(RegExp(r'v|-.*$'), '');
    String cleanLatestVersion = latestVersion.replaceAll(RegExp(r'v|-.*$'), '');

    log("Current Ver: $cleanCurrentVersion, Latest Ver: $cleanLatestVersion");

    // Simple string comparison might not be enough for versions like 1.0.0 vs 1.0.10
    // A more robust way is to compare parts
    List<int> currentParts = cleanCurrentVersion.split('.').map(int.parse).toList();
    List<int> latestParts = cleanLatestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true; // e.g. 1.0 vs 1.0.1
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
    }
    if (latestParts.length > currentParts.length && currentParts.length < 3) return true; // e.g. current 1.2, latest 1.2.0

    return false; // Versions are identical or current is newer (should not happen with /latest)
  }

  void _showUpdateBottomSheet(
    BuildContext context,
    String currentVersion,
    String newVersion,
    String changelog,
    String releasePageUrl, // URL to the GitHub release page
    Map<String, dynamic>? suitableAsset, // The specific asset to download
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => UpdateBottomSheet(
          currentVersion: currentVersion,
          newVersion: newVersion,
          changelog: changelog,
          releasePageUrl: releasePageUrl, // For "View on GitHub" or fallback
          suitableAsset: suitableAsset, // Pass the asset
          scrollController: scrollController,
          updateService: _updateService, // Pass the service instance
        ),
      ),
    );
  }
}

// --- UpdateBottomSheet needs to be StatefulWidget to manage download state ---
class UpdateBottomSheet extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final String changelog;
  final String releasePageUrl; // URL to the GitHub release page
  final Map<String, dynamic>? suitableAsset; // The specific asset to download
  final ScrollController scrollController;
  final UpdateService updateService;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.changelog,
    required this.releasePageUrl,
    this.suitableAsset,
    required this.scrollController,
    required this.updateService,
  });

  @override
  State<UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<UpdateBottomSheet> {
  DownloadProgress _downloadProgress = DownloadProgress(0, 0);
  bool _isDownloading = false;
  String _statusMessage = '';

  Future<void> _startDownloadAndInstall() async {
    if (widget.suitableAsset == null) {
      snackBar("No suitable update file found for your device.", isError: true);
      // Optionally open the release page
      // final Uri url = Uri.parse(widget.releasePageUrl);
      // if (await canLaunchUrl(url)) {
      //   await launchUrl(url);
      // }
      return;
    }

    final String downloadUrl = widget.suitableAsset!['browser_download_url'];
    final String fileName = widget.suitableAsset!['name'];

    setState(() {
      _isDownloading = true;
      _statusMessage = "Preparing to download...";
      _downloadProgress = DownloadProgress(0, 0);
    });

    try {
      await widget.updateService.downloadAndInstallApk(
        url: downloadUrl,
        fileName: fileName,
        onReceiveProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _statusMessage =
                  "Downloading: ${(progress.percent * 100).toStringAsFixed(1)}%";
            });
          }
        },
        onCompleted: () {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _statusMessage = "Download complete. Starting installation...";
            });
            // Navigator.pop(context); // Close bottom sheet after download starts install
          }
        },
        onError: (errorMsg) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _statusMessage = "Error: $errorMsg";
            });
            snackBar("Download Error: $errorMsg", isError: true);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = "An unexpected error occurred: $e";
        });
        snackBar("Error: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canDirectDownload = widget.suitableAsset != null;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Update Available! (${widget.newVersion})',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_isDownloading) ...[
            Center(child: Text(_statusMessage, style: theme.textTheme.titleMedium)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_downloadProgress.totalSize > 0)
                  ? _downloadProgress.progress
                  : null,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                children: [
                  Text(
                    'What\'s New:',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Markdown(
                        controller: widget.scrollController,
                        data: widget.changelog,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          // Add other styles as needed
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AnymeXButton(
                            borderRadius: BorderRadius.circular(30),
                            variant: ButtonVariant.outline,
                            height: 50,
                            width: double.infinity,
                            onTap: _isDownloading ? null : () => Navigator.pop(context),
                            child: const AnymexText(
                              text: 'Later',
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnymeXButton(
                            borderRadius: BorderRadius.circular(30),
                            height: 50,
                            width: double.infinity,
                            // Filled button for primary action
                            // variant: ButtonVariant.filled, // Assuming you have this
                            backgroundColor: _isDownloading ? Colors.grey : theme.colorScheme.primary,
                            onTap: _isDownloading
                                ? null // Disable button while downloading
                                : (canDirectDownload
                                    ? _startDownloadAndInstall
                                    : () async { // Fallback to GitHub page
                                        final Uri url = Uri.parse(widget.releasePageUrl);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        } else {
                                          snackBar("Could not open update page.", isError: true);
                                        }
                                      }),
                            child: AnymexText(
                              text: canDirectDownload ? 'Update Now' : 'View on GitHub',
                              size: 16,
                              color: _isDownloading ? Colors.white70 : theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.suitableAsset != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "APK: ${widget.suitableAsset!['name']}",
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
