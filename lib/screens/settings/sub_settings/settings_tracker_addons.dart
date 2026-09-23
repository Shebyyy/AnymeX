import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/tracker_addon/addon_manager.dart';
import 'package:anymex/controllers/tracker_addon/addon_manifest.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsTrackerAddons extends StatefulWidget {
  const SettingsTrackerAddons({super.key});

  @override
  State<SettingsTrackerAddons> createState() => _SettingsTrackerAddonsState();
}

class _SettingsTrackerAddonsState extends State<SettingsTrackerAddons>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AddonManager _manager = AddonManager.to;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _manager.fetchRepositories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF7E57C2);
    }
  }

  void _showAddCustomDialog() {
    final urlController = TextEditingController();
    final jsonController = TextEditingController();
    bool isJsonMode = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AnymeXDialog(
          title: 'Add Tracker Add-on',
          confirmText: 'Install',
          onConfirm: () async {
            bool success = false;
            if (!isJsonMode) {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                success = await _manager.installFromUrl(url);
              }
            } else {
              final json = jsonController.text.trim();
              if (json.isNotEmpty) {
                success = await _manager.installFromJson(json);
              }
            }

            Get.snackbar(
              success ? 'Success' : 'Error',
              success
                  ? 'Tracker Add-on installed successfully!'
                  : 'Failed to install tracker add-on. Check the URL/JSON.',
            );
          },
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const AnymeXText('Manifest URL', size: 12),
                    selected: !isJsonMode,
                    onSelected: (val) =>
                        setDialogState(() => isJsonMode = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const AnymeXText('Paste JSON', size: 12),
                    selected: isJsonMode,
                    onSelected: (val) =>
                        setDialogState(() => isJsonMode = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isJsonMode) ...[
                const AnymeXText('Enter direct URL to manifest.json:', size: 12),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://.../manifest.json',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                const AnymeXText('Paste raw manifest JSON:', size: 12),
                const SizedBox(height: 8),
                TextField(
                  controller: jsonController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '{\n  "id": "my-tracker",\n  ...\n}',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRepoDialog() {
    final repoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Add Add-on Repository',
        confirmText: 'Add',
        onConfirm: () {
          final url = repoController.text.trim();
          if (url.isNotEmpty) {
            _manager.addRepoUrl(url);
            Get.snackbar('Success', 'Repository added');
          }
        },
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnymeXText('Enter addons.json repository URL:', size: 12),
            const SizedBox(height: 8),
            TextField(
              controller: repoController,
              decoration: const InputDecoration(
                hintText: 'https://.../addons.json',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Tracker Add-ons',
      body: Builder(
        builder: (ctx) => Column(
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: colors.primary,
                      indicatorColor: colors.primary,
                      tabs: const [
                        Tab(text: 'Installed'),
                        Tab(text: 'Repository'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.plus),
                    tooltip: 'Add Custom Add-on',
                    onPressed: _showAddCustomDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add),
                    tooltip: 'Add Repository',
                    onPressed: _showAddRepoDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () => _manager.fetchRepositories(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInstalledTab(),
                  _buildRepositoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalledTab() {
    return Obx(() {
      final list = _manager.installedAddons;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconlyLight.folder, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const AnymeXText(
                'No tracker add-ons installed',
                size: 15,
                variant: TextVariant.semiBold,
              ),
              const SizedBox(height: 6),
              const AnymeXText(
                'Browse the Repository tab or install a custom add-on.',
                size: 12,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              AnymeXButton(
                onTap: _showAddCustomDialog,
                child: const AnymeXText('Add Custom Add-on'),
              ),
            ],
          ),
        );
      }

      return ScrollWrapper(
        comfortPadding: false,
        customPadding: const EdgeInsets.all(16.0),
        children: list.map((manifest) => _buildInstalledCard(manifest)).toList(),
      );
    });
  }

  Widget _buildAddonIcon(String? iconUrl, Color brandColor, String name) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnymeXImage(
          imageUrl: iconUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          radius: 14,
          errorWidget: AnymeXContainer(
            width: 48,
            height: 48,
            color: brandColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            alignment: Alignment.center,
            child: AnymeXText(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              size: 20,
              variant: TextVariant.bold,
              color: brandColor,
            ),
          ),
        ),
      );
    }
    return AnymeXContainer(
      width: 48,
      height: 48,
      color: brandColor.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      alignment: Alignment.center,
      child: AnymeXText(
        name.isNotEmpty ? name[0].toUpperCase() : 'T',
        size: 20,
        variant: TextVariant.bold,
        color: brandColor,
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    double iconSize = 19,
    required BorderRadius borderRadius,
  }) {
    return Tooltip(
      message: tooltip,
      child: AnymeXContainerButton(
        onTap: onTap,
        color: color.withOpacity(0.7),
        borderRadius: borderRadius,
        height: 38,
        width: 38,
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: Colors.black),
      ),
    );
  }

  Widget _buildInstalledCard(AddonManifest manifest) {
    final sh = Get.find<ServiceHandler>();
    final brandColor = _parseColor(manifest.color);
    final theme = context.colors;

    return Obx(() {
      final isActive = sh.serviceType.value == ServicesType.addon &&
          sh.activeAddonId.value == manifest.id;

      RemoteAddonInfo? remoteInfo;
      for (final r in _manager.availableAddons) {
        if (r.id == manifest.id) {
          remoteInfo = r;
          break;
        }
      }
      final hasUpdate =
          remoteInfo != null && remoteInfo.version != manifest.version;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: AnymeXContainer(
          radius: 18,
          color: theme.surfaceContainerHighest.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAddonIcon(manifest.icon, brandColor, manifest.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      manifest.name,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AnymeXContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: theme.secondary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                            right: Radius.circular(4),
                          ),
                          child: AnymeXText(
                            manifest.capabilities.join(', ').toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Linotte',
                              fontSize: 10.0,
                              color: theme.secondary.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        AnymeXContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: theme.tertiary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                            right: Radius.circular(8),
                          ),
                          child: AnymeXText(
                            'v${manifest.version}'.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Linotte',
                              fontSize: 10.0,
                              color: theme.tertiary.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        if (isActive)
                          AnymeXContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            color: brandColor,
                            borderRadius: BorderRadius.circular(8),
                            child: AnymeXText(
                              'ACTIVE',
                              style: TextStyle(
                                fontFamily: 'Linotte',
                                fontWeight: FontWeight.w700,
                                fontSize: 10.0,
                                color: brandColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasUpdate) ...[
                    _actionButton(
                      icon: Icons.refresh_rounded,
                      color: theme.tertiary,
                      tooltip: 'Update to v${remoteInfo.version}',
                      onTap: () async {
                        final ok = await _manager
                            .installFromUrl(remoteInfo.manifestUrl);
                        Get.snackbar(
                          ok ? 'Updated' : 'Error',
                          ok
                              ? '${manifest.name} updated to v${remoteInfo.version}!'
                              : 'Failed to update ${manifest.name}.',
                        );
                      },
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                        right: Radius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  if (!isActive) ...[
                    _actionButton(
                      icon: Iconsax.tick_circle,
                      color: theme.secondary,
                      tooltip: 'Set Active',
                      onTap: () {
                        sh.changeToAddon(manifest.id);
                        Get.snackbar(
                          'Active Service Switched',
                          '${manifest.name} is now your active tracker.',
                        );
                      },
                      borderRadius: BorderRadius.circular(hasUpdate ? 5 : 16),
                    ),
                    const SizedBox(width: 2),
                  ],
                  _actionButton(
                    icon: Iconsax.trash,
                    color: theme.error,
                    tooltip: 'Uninstall',
                    onTap: () {
                      AnymeXDialog(
                        title: 'Uninstall Add-on',
                        message:
                            'Are you sure you want to uninstall ${manifest.name}?',
                        confirmText: 'Uninstall',
                        cancelText: 'Cancel',
                        onConfirm: () async {
                          if (isActive) {
                            sh.changeService(ServicesType.anilist);
                          }
                          await _manager.uninstallAddon(manifest.id);
                          Get.snackbar(
                              'Uninstalled', '${manifest.name} removed.');
                        },
                      ).show(context);
                    },
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular((!isActive || hasUpdate) ? 5 : 16),
                      right: const Radius.circular(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRepositoryTab() {
    return Obx(() {
      if (_manager.isLoadingRepo.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = _manager.availableAddons;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconlyLight.infoSquare, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const AnymeXText('No add-ons found in repository', size: 14),
              const SizedBox(height: 12),
              AnymeXButton(
                onTap: () => _manager.fetchRepositories(),
                child: const AnymeXText('Refresh Repository'),
              ),
            ],
          ),
        );
      }

      return ScrollWrapper(
        comfortPadding: false,
        customPadding: const EdgeInsets.all(16.0),
        children: list.map((info) => _buildRemoteCard(info)).toList(),
      );
    });
  }

  Widget _buildRemoteCard(RemoteAddonInfo info) {
    final brandColor = _parseColor(info.color);
    final theme = context.colors;

    return Obx(() {
      AddonManifest? installed;
      for (final a in _manager.installedAddons) {
        if (a.id == info.id) {
          installed = a;
          break;
        }
      }
      final isInstalled = installed != null;
      final hasUpdate = isInstalled && installed.version != info.version;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: AnymeXContainer(
          radius: 18,
          color: theme.surfaceContainerHighest.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAddonIcon(info.icon, brandColor, info.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      info.name,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AnymeXContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: theme.secondary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                            right: Radius.circular(4),
                          ),
                          child: AnymeXText(
                            info.capabilities.join(', ').toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Linotte',
                              fontSize: 10.0,
                              color: theme.secondary.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        AnymeXContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: hasUpdate ? theme.primary : theme.tertiary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                            right: Radius.circular(8),
                          ),
                          child: AnymeXText(
                            hasUpdate
                                ? 'v${installed.version} → v${info.version}'
                                : 'v${info.version}'.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Linotte',
                              fontSize: 10.0,
                              color: (hasUpdate ? theme.primary : theme.tertiary)
                                          .computeLuminance() >
                                      0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (info.description != null &&
                        info.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AnymeXText(
                        info.description!,
                        size: 11,
                        maxLines: 2,
                        color: Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!isInstalled)
                _actionButton(
                  icon: Icons.download_rounded,
                  color: theme.primary,
                  tooltip: 'Install',
                  onTap: () async {
                    final ok =
                        await _manager.installFromUrl(info.manifestUrl);
                    Get.snackbar(
                      ok ? 'Installed' : 'Error',
                      ok
                          ? '${info.name} installed successfully!'
                          : 'Failed to download manifest for ${info.name}.',
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                )
              else if (hasUpdate)
                _actionButton(
                  icon: Icons.refresh_rounded,
                  color: theme.tertiary,
                  tooltip: 'Update',
                  onTap: () async {
                    final ok =
                        await _manager.installFromUrl(info.manifestUrl);
                    Get.snackbar(
                      ok ? 'Updated' : 'Error',
                      ok
                          ? '${info.name} updated to v${info.version}!'
                          : 'Failed to download manifest for ${info.name}.',
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                )
              else
                _actionButton(
                  icon: Icons.check_rounded,
                  color: theme.secondary,
                  tooltip: 'Installed',
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                ),
            ],
          ),
        ),
      );
    });
  }
}
