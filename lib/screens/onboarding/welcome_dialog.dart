import 'package:anymex/utils/logger.dart';
import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

// STORAGE PERMISSIONS
Future<bool> _requestStoragePermissions() async {
  if (!Platform.isAndroid) return true;

  try {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    Logger.i('Android SDK version: $sdkInt');

    if (sdkInt >= 33) {
      final permissions = [
        Permission.photos,
        Permission.videos,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      if (await Permission.manageExternalStorage.isDenied) {
        final manageStorageStatus =
            await Permission.manageExternalStorage.request();
        if (manageStorageStatus.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }

      return statuses.values.every((s) =>
          s == PermissionStatus.granted || s == PermissionStatus.limited);
    } else if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } else if (sdkInt >= 23) {
      final permissions = [Permission.storage];
      final statuses = await permissions.request();
      bool allGranted = statuses.values.every((s) => s.isGranted);

      if (!allGranted &&
          statuses.values.any((s) => s.isPermanentlyDenied)) {
        await openAppSettings();
        return false;
      }

      return allGranted;
    } else {
      return true;
    }
  } catch (e) {
    Logger.i('Error requesting storage permissions: $e');
    return false;
  }
}

// MAIN DIALOG
void showWelcomeDialogg(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Welcome To AnymeX",
    pageBuilder: (context, animation1, animation2) {
      final settings = Get.find<Settings>();
      final serviceHandler = Get.find<ServiceHandler>();

      final RxBool storagePermissionGranted = false.obs;
      final RxBool installPermissionGranted = false.obs;

      Future<void> requestStoragePermission() async {
        final status = await _requestStoragePermissions();
        storagePermissionGranted.value = status;
        if (!status) {
          snackBar("Storage permission is required to download updates");
        }
      }

      Future<void> requestInstallPermission() async {
        final status = await Permission.requestInstallPackages.request();
        installPermissionGranted.value = status.isGranted;
        if (!status.isGranted) {
          snackBar("Install permission is required to update the app");
        }
      }

      return Obx(() {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Container(
              width: getResponsiveSize(context,
                  mobileSize: MediaQuery.of(context).size.width - 20,
                  desktopSize: MediaQuery.of(context).size.width * 0.4),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TITLE BAR
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: const Center(
                      child: Text(
                        'Welcome To AnymeX',
                        style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                      ),
                    ),
                  ),

                  // CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PERFORMANCE MODE
                          CustomSwitchTile(
                            icon: HugeIcons.strokeRoundedCpu,
                            title: "Performance Mode",
                            description:
                                "Disable animations to improve performance",
                            switchValue: !settings.enableAnimation,
                            onChanged: (v) => settings.enableAnimation = !v,
                          ),

                          // DISABLE GRADIENT
                          CustomSwitchTile(
                            icon: HugeIcons.strokeRoundedBounceRight,
                            title: "Disable Gradient",
                            description:
                                "Disable gradients for smoother experience",
                            switchValue: settings.disableGradient,
                            onChanged: (v) => settings.disableGradient = v,
                          ),

                          // PERMISSIONS
                          if (Platform.isAndroid) ...[
                            CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedFolderSecurity,
                              title: "Storage Permission",
                              description:
                                  "Needed for downloading and saving updates",
                              switchValue: storagePermissionGranted.value,
                              onChanged: (val) {
                                if (val) requestStoragePermission();
                              },
                            ),
                            CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedDownload01,
                              title: "Install Permission",
                              description:
                                  "Needed for installing app updates",
                              switchValue: installPermissionGranted.value,
                              onChanged: (val) {
                                if (val) requestInstallPermission();
                              },
                            ),
                          ],

                          // CHANGE SERVICE
                          CustomTile(
                            description:
                                'Choose your preferred service: AniList, MAL, or Simkl',
                            icon: HugeIcons.strokeRoundedAiSetting,
                            title: 'Change Service',
                            onTap: () {
                              SettingsSheet().showServiceSelector(context);
                            },
                          ),

                          // NEW — DEFAULT START PAGE PICKER
                          CustomTile(
                            description:
                                'Choose which tab opens first when launching the app',
                            icon: IconlyBold.home,
                            title: 'Default Start Page',
                            onTap: () => _showStartPagePicker(context),
                          ),

                          const SizedBox(height: 12),

                          // LOGIN AND SKIP BUTTONS
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // LOGIN BUTTON
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Hive.box('themeData')
                                          .put('isFirstTime', false);
                                      Navigator.of(context).pop();
                                      navigate(() => const SettingsAccounts());
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Login',
                                          style: TextStyle(
                                            fontFamily: 'Poppins-SemiBold',
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inverseSurface,
                                          ),
                                        ),
                                        const Spacer(),
                                        _buildIcon(context, 'anilist-icon.png'),
                                        _buildIcon(context, 'mal-icon.png'),
                                        _buildIcon(context, 'simkl-icon.png'),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // SKIP BUTTON
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Hive.box('themeData')
                                        .put('isFirstTime', false);
                                    Get.back();
                                  },
                                  label: Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                    ),
                                  ),
                                  icon: Icon(
                                    IconlyBold.arrow_right,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                  ),
                                  iconAlignment: IconAlignment.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

// ICON BUILDER
Widget _buildIcon(BuildContext context, String url) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: CircleAvatar(
      radius: 11,
      backgroundColor: Colors.transparent,
      child: Image.asset(
        'assets/images/$url',
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

// ----------------------
// DEFAULT START PAGE PICKER
// ----------------------
void _showStartPagePicker(BuildContext context) {
  final settings = Get.find<Settings>();
  final isSimkl = Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Default Start Page",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _startPageOption(
              context,
              settings,
              0,
              "Home",
              const Icon(IconlyBold.home),
            ),
            _startPageOption(
              context,
              settings,
              1,
              "Anime",
              const Icon(Icons.movie_filter_rounded),
            ),
            _startPageOption(
              context,
              settings,
              2,
              "Manga",
              Icon(isSimkl ? Iconsax.monitor5 : Iconsax.book),
            ),
            _startPageOption(
              context,
              settings,
              3,
              "Library",
              const Icon(HugeIcons.strokeRoundedLibrary),
            ),

            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

Widget _startPageOption(
    BuildContext context,
    Settings settings,
    int index,
    String label,
    Widget icon,
    ) {
  final selected = settings.defaultStartTab.value == index;

  return ListTile(
    leading: icon,
    title: Text(label),
    trailing: selected
        ? const Icon(Icons.check_circle, color: Colors.green)
        : null,
    onTap: () {
      settings.saveDefaultStartTab(index);
      Navigator.pop(context);
    },
  );
}
