import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/tracker_addon/addon_manager.dart';
import 'package:anymex/controllers/tracker_addon/addon_manifest.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

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

  Widget _buildInstalledCard(AddonManifest manifest) {
    final sh = Get.find<ServiceHandler>();
    final brandColor = _parseColor(manifest.color);

    return Obx(() {
      final isActive = sh.serviceType.value == ServicesType.addon &&
          sh.activeAddonId.value == manifest.id;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: AnymeXContainer(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: brandColor.withOpacity(0.2),
                    child: AnymeXText(
                      manifest.name.isNotEmpty ? manifest.name[0] : 'T',
                      color: brandColor,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnymeXText(
                              manifest.name,
                              size: 16,
                              variant: TextVariant.bold,
                            ),
                            const SizedBox(width: 8),
                            AnymeXText(
                              'v${manifest.version}',
                              size: 11,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        if (manifest.author != null)
                          AnymeXText(
                            'by ${manifest.author}',
                            size: 11,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandColor),
                      ),
                      child: AnymeXText(
                        'ACTIVE',
                        size: 10,
                        variant: TextVariant.bold,
                        color: brandColor,
                      ),
                    ),
                ],
              ),
              if (manifest.description != null) ...[
                const SizedBox(height: 8),
                AnymeXText(
                  manifest.description!,
                  size: 12,
                  maxLines: 2,
                  color: Colors.grey,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: manifest.capabilities
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AnymeXText(
                                c.toUpperCase(),
                                size: 9,
                                variant: TextVariant.semiBold,
                              ),
                            ))
                        .toList(),
                  ),
                  const Spacer(),
                  if (!isActive)
                    AnymeXButton(
                      variant: ButtonVariant.outline,
                      height: 32,
                      width: 90,
                      onTap: () {
                        sh.changeToAddon(manifest.id);
                        Get.snackbar(
                          'Active Service Switched',
                          '${manifest.name} is now your active tracker.',
                        );
                      },
                      child: const AnymeXText('Set Active', size: 12),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(IconlyLight.delete, size: 20),
                    color: Colors.redAccent,
                    tooltip: 'Uninstall',
                    onPressed: () async {
                      if (isActive) {
                        sh.changeService(ServicesType.anilist);
                      }
                      await _manager.uninstallAddon(manifest.id);
                      Get.snackbar('Uninstalled', '${manifest.name} removed.');
                    },
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

    return Obx(() {
      final isInstalled = _manager.isInstalled(info.id);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: AnymeXContainer(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: brandColor.withOpacity(0.2),
                    child: AnymeXText(
                      info.name.isNotEmpty ? info.name[0] : 'T',
                      color: brandColor,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnymeXText(
                              info.name,
                              size: 16,
                              variant: TextVariant.bold,
                            ),
                            const SizedBox(width: 8),
                            AnymeXText(
                              'v${info.version}',
                              size: 11,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        if (info.author != null)
                          AnymeXText(
                            'by ${info.author}',
                            size: 11,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                  AnymeXButton(
                    variant: isInstalled
                        ? ButtonVariant.outline
                        : ButtonVariant.simple,
                    height: 34,
                    width: 90,
                    onTap: () async {
                      if (!isInstalled) {
                        final ok = await _manager.installFromUrl(info.manifestUrl);
                        Get.snackbar(
                          ok ? 'Installed' : 'Error',
                          ok
                              ? '${info.name} installed successfully!'
                              : 'Failed to download manifest for ${info.name}.',
                        );
                      }
                    },
                    child: AnymeXText(
                      isInstalled ? 'Installed' : 'Install',
                      size: 12,
                    ),
                  ),
                ],
              ),
              if (info.description != null) ...[
                const SizedBox(height: 8),
                AnymeXText(
                  info.description!,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
