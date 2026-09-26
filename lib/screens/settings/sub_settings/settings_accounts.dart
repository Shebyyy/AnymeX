import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/controllers/tracker_addon/addon_manager.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/settings/sub_settings/settings_anilist_api.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tracker_addons.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

class SettingsAccounts extends StatefulWidget {
  const SettingsAccounts({super.key});

  @override
  State<SettingsAccounts> createState() => _SettingsAccountsState();
}

class _SettingsAccountsState extends State<SettingsAccounts> {
  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final addonManager = Get.find<AddonManager>();

    final services = [
      {
        'serviceIcon': 'anilist-icon.png',
        'service': serviceHandler.anilistService,
        'title': 'Anilist',
      },
      {
        'serviceIcon': 'mal-icon.png',
        'service': serviceHandler.malService,
        'title': 'MyAnimeList',
      },
      {
        'serviceIcon': 'simkl-icon.png',
        'service': serviceHandler.simklService,
        'title': 'Simkl',
      },
    ];

    services.sort((a, b) =>
        (b['service'] == serviceHandler.onlineService ? 1 : 0)
            .compareTo(a['service'] == serviceHandler.onlineService ? 1 : 0));

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Accounts',
      body: Builder(
        builder: (ctx) => ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),
            AnymeXSectionBuilder(
              title: 'Tracking Services',
              children: services
                  .map((s) => TrackingServiceCard(
                        serviceIcon: s['serviceIcon'] as String,
                        service: s['service'] as OnlineService,
                        title: s['title'] as String,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final addons = addonManager.installedAddons;
              return AnymeXSectionBuilder(
                title: 'Tracker Add-ons',
                children: [
                  AnymeXTile(
                    title: 'Manage Add-ons',
                    subtitle: 'Browse, install, and update external trackers',
                    icon: IconlyLight.folder,
                    onTap: () => navigate(() => const SettingsTrackerAddons()),
                  ),
                  ...addons.map((manifest) {
                    final addonService =
                        serviceHandler.getOrInitAddonService(manifest.id);
                    if (addonService == null) return const SizedBox.shrink();
                    return TrackingServiceCard(
                      serviceIcon: manifest.icon ?? '',
                      service: addonService,
                      title: manifest.name,
                      isUrlIcon: manifest.icon != null &&
                          manifest.icon!.startsWith('http'),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class TrackingServiceCard extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;
  final String title;
  final bool isUrlIcon;

  const TrackingServiceCard({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
    this.isUrlIcon = false,
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
                    _buildServiceIcon(context, avatar, isLogged),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            title,
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText(
                            isLogged
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
                      child: AnymeXText(
                        isLogged ? "Manage" : "Connect",
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

  Widget _buildServiceIcon(
      BuildContext context, String? avatarUrl, bool isLogged) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final primaryColor = theme.colorScheme.primary;

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
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (isUrlIcon && serviceIcon.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogged
              ? primaryColor.opaque(0.2, iReallyMeanIt: true)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: serviceIcon,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorWidget: (c, o, s) => const Icon(
            Icons.extension_rounded,
            size: 24,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLogged
            ? primaryColor.opaque(0.2, iReallyMeanIt: true)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/images/$serviceIcon',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        color: isLogged ? primaryColor : theme.iconTheme.color,
        errorBuilder: (c, o, s) => AnymeXText(
          title.isNotEmpty ? title[0] : 'T',
          variant: TextVariant.bold,
          size: 18,
        ),
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
