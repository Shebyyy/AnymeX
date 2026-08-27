import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/discord/discord_login.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/controllers/tracker_addon/community_trackers.dart';
import 'package:anymex/controllers/tracker_addon/generic_tracker_service.dart';
import 'package:anymex/controllers/tracker_addon/tracker_addon_manager.dart';
import 'package:anymex/controllers/tracker_addon/tracker_manifest.dart';
import 'package:anymex/controllers/tracker_addon/tracker_registry.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/settings/sub_settings/settings_anilist_api.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class SettingsAccounts extends StatefulWidget {
  const SettingsAccounts({super.key});

  @override
  State<SettingsAccounts> createState() => _SettingsAccountsState();
}

class _SettingsAccountsState extends State<SettingsAccounts> {
  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final builtInServices = [
      {
        'serviceIcon': 'anilist.png',
        'service': serviceHandler.anilistService,
        'title': 'Anilist',
      },
      {
        'serviceIcon': 'mal.png',
        'service': serviceHandler.malService,
        'title': 'MyAnimeList',
      },
      {
        'serviceIcon': 'simkl.png',
        'service': serviceHandler.simklService,
        'title': 'Simkl',
      },
    ];

    builtInServices.sort((a, b) =>
        (b['service'] == serviceHandler.onlineService ? 1 : 0)
            .compareTo(a['service'] == serviceHandler.onlineService ? 1 : 0));

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Accounts',
      body: Builder(
        builder: (ctx) => ScrollWrapper(
                  comfortPadding: false,
                  customPadding:
                      const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
                  children: [
                    SizedBox(height: AnymeXHeaderScope.of(ctx)),
                    const AnymeXSectionBuilder(
                      title: 'Social Presence',
                      borderRadius: 24,
                      children: [
                        DiscordTile(),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Tracking Services',
                      children: [
                        ...builtInServices
                            .map((s) => TrackingServiceCard(
                                  serviceIcon: s['serviceIcon'] as String,
                                  service: s['service'] as OnlineService,
                                  title: s['title'] as String,
                                )),
                        // ── Add-on Tracker Section ─────────────
                        _AddonTrackerSection(),
                      ],
                    ),
                    // ── Add-on Store Section ───────────────────
                    const _AddonStoreSection(),
                  ],
                )
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Add-on Tracker Section — shows installed add-on trackers
// ════════════════════════════════════════════════════════════════════

class _AddonTrackerSection extends StatefulWidget {
  @override
  State<_AddonTrackerSection> createState() => _AddonTrackerSectionState();
}

class _AddonTrackerSectionState extends State<_AddonTrackerSection> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GetX<TrackerAddonManager>(builder: (manager) {
      if (manager.installedAddonIds.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          AnymeXText(
            'Add-on Trackers',
            variant: TextVariant.semiBold,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          ...manager.installedAddonIds.map((id) {
            final service = manager.getService(id);
            if (service == null) return const SizedBox.shrink();
            final genericService = service as GenericTrackerService;
            final manifest = genericService.manifest;
            final registry = TrackerRegistry();
            final isActive =
                Get.find<ServiceHandler>().activeAddonId.value == id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AddonTrackerCard(
                service: genericService,
                manifest: manifest,
                trackerName: registry.getTrackerName(id),
                trackerColor: registry.getTrackerColor(id),
                isActive: isActive,
                onSetActive: () {
                  Get.find<ServiceHandler>().changeToAddonTracker(id);
                  successSnackBar('Tracking via ${manifest.name}');
                },
                onUninstall: () {
                  _showUninstallDialog(context, id, manifest.name, () {
                    manager.uninstall(id);
                    if (Get.find<ServiceHandler>().activeAddonId.value ==
                        id) {
                      Get.find<ServiceHandler>().clearAddonTracker();
                    }
                    successSnackBar('Removed ${manifest.name}');
                  });
                },
              ),
            );
          }),
        ],
      );
    });
  }

  void _showUninstallDialog(
    BuildContext context,
    String id,
    String name,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceContainer,
        title: AnymeXText("Remove $name?", variant: TextVariant.bold),
        content: AnymeXText(
          "This will disconnect your account and remove the tracker. "
          "Your tracking data on $name's servers will NOT be deleted.",
          size: 13,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AnymeXText("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: AnymeXText("Remove",
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Add-on Tracker Card — individual addon tracker tile
// ════════════════════════════════════════════════════════════════════

class _AddonTrackerCard extends StatelessWidget {
  final GenericTrackerService service;
  final TrackerManifest manifest;
  final String trackerName;
  final String trackerColor;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onUninstall;

  const _AddonTrackerCard({
    required this.service,
    required this.manifest,
    required this.trackerName,
    required this.trackerColor,
    required this.isActive,
    required this.onSetActive,
    required this.onUninstall,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = _parseColor(trackerColor);

    return Obx(() {
      final isLogged = service.isLoggedIn.value;

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? accentColor
                : isLogged
                    ? accentColor.withOpacity(0.5)
                    : Colors.transparent,
            width: isActive ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLogged) {
                _showAddonServiceOptions(context);
              } else {
                service.login(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildIcon(isLogged, accentColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: AnymeXText(
                                trackerName,
                                variant: TextVariant.semiBold,
                                size: 16,
                                maxLines: 1,
                              ),
                            ),
                            if (isActive)
                              Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AnymeXText(
                                'Active',
                                size: 9,
                                color: Colors.white,
                                variant: TextVariant.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          isLogged
                              ? 'Connected as ${service.profileData.value.name ?? "User"}'
                              : 'Not connected',
                          size: 12,
                          color: isLogged
                              ? accentColor
                              : colors.onSurfaceVariant,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLogged
                          ? colors.surfaceContainerHigh
                          : accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnymeXText(
                      isLogged ? "Manage" : "Connect",
                      variant: TextVariant.bold,
                      size: 12,
                      color: isLogged ? colors.onSurface : accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildIcon(bool isLogged, Color accentColor) {
    final avatarUrl = isLogged ? service.profileData.value.avatar : null;
    final iconUrl = manifest.icon;

    if (isLogged && avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: CachedNetworkImageProvider(
                  avatarUrl,
                  cacheManager: AnymeXCacheManager.instance,
                ),
                fit: BoxFit.cover)),
      );
    }

    if (iconUrl != null && iconUrl.startsWith('http')) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: iconUrl,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => Icon(IconlyBold.danger,
                color: accentColor, size: 24),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.extension_outlined, color: accentColor, size: 24),
    );
  }

  void _showAddonServiceOptions(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText("Manage $trackerName",
                  variant: TextVariant.bold, size: 18),
              const SizedBox(height: 20),
              // Set as active tracking service
              ListTile(
                leading: Icon(
                    isActive
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isActive ? _parseColor(trackerColor) : null),
                title: AnymeXText(
                  isActive ? 'Active Tracking Service' : 'Set as Active',
                  color: isActive ? _parseColor(trackerColor) : null,
                ),
                subtitle: const AnymeXText(
                  'Track progress updates through this service',
                  size: 11,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onSetActive();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: colors.surfaceContainer,
              ),
              const SizedBox(height: 8),
              // Capabilities info
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const AnymeXText('Capabilities'),
                subtitle: AnymeXText(
                  manifest.capabilities.map((c) =>
                      c[0].toUpperCase() + c.substring(1)).join(', '),
                  size: 11,
                  color: colors.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: colors.surfaceContainer,
              ),
              const SizedBox(height: 8),
              // Export manifest
              ListTile(
                leading: const Icon(Icons.share),
                title: const AnymeXText('Share Manifest'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportManifest();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: colors.surfaceContainer,
              ),
              const SizedBox(height: 8),
              // Logout
              ListTile(
                leading: const Icon(IconlyLight.logout),
                title: const AnymeXText("Log Out"),
                onTap: () {
                  service.logout();
                  Navigator.pop(ctx);
                  successSnackBar('Logged out from $trackerName');
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: colors.surfaceContainer,
              ),
              const SizedBox(height: 8),
              // Uninstall
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: colors.error),
                title: AnymeXText("Remove Tracker",
                    color: colors.error),
                onTap: () {
                  Navigator.pop(ctx);
                  onUninstall();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: colors.surfaceContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportManifest() {
    Clipboard.setData(ClipboardData(text: manifest.toJson()));
    successSnackBar('${trackerName} manifest copied to clipboard');
  }
}

// ════════════════════════════════════════════════════════════════════
// Add-on Store Section — install community/addon trackers
// ════════════════════════════════════════════════════════════════════

class _AddonStoreSection extends StatelessWidget {
  const _AddonStoreSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final community = CommunityTrackers.all;

    return AnymeXSectionBuilder(
      title: 'Tracker Add-ons',
      children: [
        ...community.map((manifest) {
          final registry = TrackerRegistry();
          final isInstalled = registry.isAddon(manifest.id);
          final color = _parseHexColor(manifest.color);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isInstalled
                    ? color.withOpacity(0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isInstalled
                    ? null
                    : () => _installFromCommunity(context, manifest),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: manifest.icon != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  manifest.icon!,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.extension,
                                          color: color, size: 20),
                                ),
                              )
                            : Icon(Icons.extension, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymeXText(
                              manifest.name,
                              variant: TextVariant.semiBold,
                              size: 15,
                            ),
                            const SizedBox(height: 2),
                            AnymeXText(
                              isInstalled
                                  ? 'Installed'
                                  : (manifest.description ??
                                      'Tap to install'),
                              size: 11,
                              color: isInstalled
                                  ? color
                                  : colors.onSurfaceVariant,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      // Capabilities badges
                      ...manifest.capabilities
                          .take(2)
                          .map((cap) => Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AnymeXText(
                                  cap[0].toUpperCase() + cap.substring(1),
                                  size: 9,
                                  color: colors.onSurfaceVariant,
                                ),
                              )),
                      const SizedBox(width: 8),
                      // Action
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isInstalled
                              ? colors.surfaceContainerHigh
                              : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnymeXText(
                          isInstalled ? 'Installed' : 'Install',
                          variant: TextVariant.bold,
                          size: 11,
                          color: isInstalled
                              ? colors.onSurfaceVariant
                              : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        // Import from file
        const SizedBox(height: 8),
        _ImportFromJsonTile(),
        _ImportFromClipboardTile(),
      ],
    );
  }

  Color _parseHexColor(String? hex) {
    if (hex == null) return const Color(0xFF666666);
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return const Color(0xFF666666);
    }
  }

  void _installFromCommunity(
    BuildContext context,
    TrackerManifest manifest,
  ) async {
    try {
      final manager = Get.find<TrackerAddonManager>();
      final error = manager.installFromManifest(manifest);
      if (error != null) {
        errorSnackBar(error);
      } else {
        successSnackBar('${manifest.name} installed! Go to Accounts to connect.');
      }
    } catch (e) {
      errorSnackBar('Failed to install: $e');
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Import Tiles
// ════════════════════════════════════════════════════════════════════

class _ImportFromJsonTile extends StatelessWidget {
  const _ImportFromJsonTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _importFromFile(context),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open,
                      size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        'Import from File',
                        variant: TextVariant.semiBold,
                        size: 15,
                      ),
                      AnymeXText(
                        'Select a .json tracker manifest',
                        size: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final content = await File(file.path!).readAsString();
        final manager = Get.find<TrackerAddonManager>();
        final error = manager.installFromJson(content);
        if (error != null) {
          errorSnackBar(error);
        } else {
          successSnackBar(
              'Tracker installed from ${file.name}');
        }
      }
    } catch (e) {
      errorSnackBar('Import failed: $e');
    }
  }
}

class _ImportFromClipboardTile extends StatelessWidget {
  const _ImportFromClipboardTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _importFromClipboard(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.content_paste,
                      size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        'Import from Clipboard',
                        variant: TextVariant.semiBold,
                        size: 15,
                      ),
                      AnymeXText(
                        'Paste a tracker manifest JSON',
                        size: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        errorSnackBar('Clipboard is empty');
        return;
      }
      final manager = Get.find<TrackerAddonManager>();
      final error = manager.installFromJson(clipboardData.text!);
      if (error != null) {
        errorSnackBar(error);
      } else {
        successSnackBar('Tracker installed from clipboard!');
      }
    } catch (e) {
      errorSnackBar('Import failed: $e');
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Original built-in widgets (unchanged)
// ════════════════════════════════════════════════════════════════════

class DiscordTile extends StatelessWidget {
  const DiscordTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final rpc = DiscordRPCController.instance;
      final isDesktop = !rpc.isMobile;
      final isLoggedIn = rpc.isLoggedIn;
      final userData = isLoggedIn ? rpc.profile.value : null;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLoggedIn
                ? colors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildAvatar(isDesktop ? null : userData?.avatarUrl,
                      isLoggedIn, colors),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(isDesktop
                              ? 'Discord Desktop'
                              : (isLoggedIn
                                  ? (userData?.displayName ?? 'Discord User')
                                  : 'Connect Discord'),
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isLoggedIn && rpc.isEnabled
                                    ? const Color(0xFF43B581)
                                    : colors.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnymeXText(isDesktop
                                  ? (rpc.isConnected
                                      ? 'Connected'
                                      : 'Disconnected')
                                  : (isLoggedIn
                                      ? (rpc.isEnabled
                                          ? 'Rich Presence Active'
                                          : 'Rich Presence Disabled')
                                      : 'Not Connected'),
                              color: isLoggedIn && rpc.isEnabled
                                  ? const Color(0xFF43B581)
                                  : colors.onSurfaceVariant,
                              size: 12,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDesktop && isLoggedIn)
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context, rpc),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconlyBold.logout,
                          color: colors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  if (!isDesktop && !isLoggedIn)
                    GestureDetector(
                      onTap: () => context.showDiscordLogin(
                          (token) => rpc.onLoginSuccess(token)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AnymeXText('Login',
                          variant: TextVariant.bold,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (isDesktop || isLoggedIn) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: colors.outline.withOpacity(0.12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnymeXText('Discord Rich Presence',
                            variant: TextVariant.semiBold,
                            size: 14,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText('Share your activity on Discord',
                            size: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: Switch(
                        value: rpc.isEnabled,
                        onChanged: (e) => rpc.setEnabled(e),
                        activeColor: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatar(String? url, bool isLoggedIn, dynamic colors) {
    if (isLoggedIn && url != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: colors.surfaceContainerHighest,
          backgroundImage: CachedNetworkImageProvider(
            url,
            cacheManager: AnymeXCacheManager.instance,
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF5865F2).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(IconlyBold.game, color: Color(0xFF5865F2), size: 28),
    );
  }

  void _showLogoutDialog(BuildContext context, DiscordRPCController rpc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceContainer,
        title: const AnymeXText("Disconnect Discord?", variant: TextVariant.bold),
        content: const AnymeXText("Your rich presence activity will stop updating."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AnymeXText("Cancel"),
          ),
          TextButton(
            onPressed: () {
              rpc.logout();
              Navigator.pop(context);
            },
            child: AnymeXText("Disconnect",
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}

class TrackingServiceCard extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;
  final String title;

  const TrackingServiceCard({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return HighlightDecorator(
      title: title,
      child: Obx(() {
        final bool isLogged = service.isLoggedIn.value;

        final String username =
            isLogged ? (service.profileData.value.name ?? "User") : "";
        final String? avatar =
            isLogged ? service.profileData.value.avatar : null;

        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLogged
                  ? (colors.primary).withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isLogged) {
                  _showServiceOptions(context);
                } else {
                  service.login(context);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    _buildServiceIcon(avatar, isLogged),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(title,
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText(isLogged
                                ? 'Connected as $username'
                                : 'Not connected',
                            size: 12,
                            color: isLogged
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLogged
                            ? colors.surfaceContainerHigh
                            : (colors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnymeXText(isLogged ? "Manage" : "Connect",
                        variant: TextVariant.bold,
                        size: 12,
                        color: isLogged ? colors.onSurface : (colors.primary),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildServiceIcon(String? avatarUrl, bool isLogged) {
    if (isLogged && avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: CachedNetworkImageProvider(
                  avatarUrl,
                  cacheManager: AnymeXCacheManager.instance,
                ),
                fit: BoxFit.cover)),
      );
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/icons/$serviceIcon',
        errorBuilder: (c, o, s) => const Icon(IconlyBold.danger),
      ),
    );
  }

  void _showServiceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymeXText("Manage $title", variant: TextVariant.bold, size: 18),
            const SizedBox(height: 20),
            if (title.toLowerCase() == 'anilist')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/anilist-icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const AnymeXText('Anilist Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    navigate(() => const SettingsAnilistApi());
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: context.colors.surfaceContainer,
                ),
              ),
            ListTile(
              leading: const Icon(IconlyLight.logout),
              title: const AnymeXText("Log Out"),
              onTap: () {
                service.logout();
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: context.colors.surfaceContainer,
            )
          ],
        ),
      ),
    );
  }
}
