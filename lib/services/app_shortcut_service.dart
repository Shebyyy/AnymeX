import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:anymex/controllers/media_mode_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/main.dart';
import 'package:anymex/models/settings/app_shortcut_slot.dart';
import 'package:anymex/screens/downloads/download_screen.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/library/history_page.dart';
import 'package:anymex/screens/library/my_library.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/stats/user_stats_page.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:quick_actions/quick_actions.dart';

class AppShortcutService extends GetxService {
  static AppShortcutService get instance => Get.find<AppShortcutService>();

  final QuickActions _quickActions = const QuickActions();

  final isEnabled = true.obs;
  final slotCount = 4.obs;
  final slots = <AppShortcutSlotConfig>[].obs;
  final selectedPreset = AppShortcutPreset.balanced.obs;
  final showDynamicTitles = true.obs;

  StreamSubscription? _animeSub;
  StreamSubscription? _mangaSub;
  StreamSubscription? _novelSub;
  Timer? _debounceTimer;

  String? _pendingShortcutType;
  bool _isAppInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _initQuickActions();
    _setupHistoryListeners();
  }

  void _loadSettings() {
    isEnabled.value = AppShortcutKeys.shortcutsEnabled.get<bool>(true);
    slotCount.value = AppShortcutKeys.shortcutSlotCount.get<int>(4).clamp(1, 4);
    showDynamicTitles.value = AppShortcutKeys.showDynamicTitles.get<bool>(true);

    final presetName = AppShortcutKeys.selectedPreset
        .get<String>(AppShortcutPreset.balanced.name);
    selectedPreset.value = AppShortcutPreset.values.firstWhere(
      (e) => e.name == presetName,
      orElse: () => AppShortcutPreset.balanced,
    );

    final rawJson = AppShortcutKeys.shortcutSlotsJson.get<String>('');
    if (rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        final loaded = decoded
            .map((e) =>
                AppShortcutSlotConfig.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (loaded.isNotEmpty) {
          slots.value = loaded;
          return;
        }
      } catch (e) {
        Logger.e('Error loading shortcut slots from storage: $e');
      }
    }

    slots.value = AppShortcutSlotConfig.getPresetSlots(selectedPreset.value);
  }

  void _saveSettings() {
    AppShortcutKeys.shortcutsEnabled.set(isEnabled.value);
    AppShortcutKeys.shortcutSlotCount.set(slotCount.value);
    AppShortcutKeys.showDynamicTitles.set(showDynamicTitles.value);
    AppShortcutKeys.selectedPreset.set(selectedPreset.value.name);

    final jsonString = jsonEncode(slots.map((e) => e.toJson()).toList());
    AppShortcutKeys.shortcutSlotsJson.set(jsonString);
  }

  void _initQuickActions() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _quickActions.initialize((String shortcutType) {
      Logger.i('App Shortcut tapped with type: $shortcutType');
      if (!_isAppInitialized) {
        _pendingShortcutType = shortcutType;
      } else {
        handleShortcutTap(shortcutType);
      }
    });

    syncShortcuts();
  }

  void markAppInitialized() {
    _isAppInitialized = true;
    if (_pendingShortcutType != null) {
      final type = _pendingShortcutType!;
      _pendingShortcutType = null;
      Future.delayed(const Duration(milliseconds: 400), () {
        handleShortcutTap(type);
      });
    }
  }

  void _setupHistoryListeners() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final mediaMode = Get.isRegistered<MediaModeController>()
        ? Get.find<MediaModeController>()
        : Get.put(MediaModeController());

    _animeSub = mediaMode.animeHistory.listen((_) => _debouncedSync());
    _mangaSub = mediaMode.mangaHistory.listen((_) => _debouncedSync());
    _novelSub = mediaMode.novelHistory.listen((_) => _debouncedSync());
  }

  void _debouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      syncShortcuts();
    });
  }

  void toggleEnabled(bool val) {
    isEnabled.value = val;
    _saveSettings();
    syncShortcuts();
  }

  void setSlotCount(int count) {
    slotCount.value = count.clamp(1, 4);
    _saveSettings();
    syncShortcuts();
  }

  void toggleDynamicTitles(bool val) {
    showDynamicTitles.value = val;
    _saveSettings();
    syncShortcuts();
  }

  void applyPreset(AppShortcutPreset preset) {
    selectedPreset.value = preset;
    slots.value = AppShortcutSlotConfig.getPresetSlots(preset);
    _saveSettings();
    syncShortcuts();
  }

  void updateSlot(int index, AppShortcutSlotConfig updatedConfig) {
    if (index >= 0 && index < slots.length) {
      slots[index] = updatedConfig;
      selectedPreset.value = AppShortcutPreset.custom;
      slots.refresh();
      _saveSettings();
      syncShortcuts();
    }
  }

  void reorderSlots(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = slots.removeAt(oldIndex);
    slots.insert(newIndex, item);
    selectedPreset.value = AppShortcutPreset.custom;
    slots.refresh();
    _saveSettings();
    syncShortcuts();
  }

  void addSlot(AppShortcutSource source) {
    if (slots.length >= 4) return;
    slots.add(AppShortcutSlotConfig(
      id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    ));
    slotCount.value = slots.length;
    selectedPreset.value = AppShortcutPreset.custom;
    _saveSettings();
    syncShortcuts();
  }

  void removeSlot(int index) {
    if (slots.length <= 1) return;
    slots.removeAt(index);
    if (slotCount.value > slots.length) {
      slotCount.value = slots.length;
    }
    selectedPreset.value = AppShortcutPreset.custom;
    _saveSettings();
    syncShortcuts();
  }

  List<ShortcutItem> buildShortcutItems() {
    if (!isEnabled.value) return [];

    final activeSlots = slots.take(slotCount.value).toList();
    final List<ShortcutItem> items = [];

    final mediaMode = Get.isRegistered<MediaModeController>()
        ? Get.find<MediaModeController>()
        : Get.put(MediaModeController());

    for (final slot in activeSlots) {
      final item = _resolveSlotToShortcutItem(slot, mediaMode);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  void syncShortcuts() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    if (!isEnabled.value) {
      _quickActions.clearShortcutItems();
      return;
    }

    try {
      final items = buildShortcutItems();
      _quickActions.setShortcutItems(items);
    } catch (e) {
      Logger.e('Error syncing quick actions: $e');
    }
  }

  ShortcutItem? _resolveSlotToShortcutItem(
    AppShortcutSlotConfig slot,
    MediaModeController mediaMode,
  ) {
    final source = slot.source;

    if (source.isMedia) {
      OfflineMedia? media;
      ItemType itemType = ItemType.anime;

      if (source.name.startsWith('recentAnime')) {
        itemType = ItemType.anime;
        final list = mediaMode.animeHistory;
        if (slot.source.rankIndex < list.length) {
          media = list[slot.source.rankIndex];
        }
      } else if (source.name.startsWith('recentManga')) {
        itemType = ItemType.manga;
        final list = mediaMode.mangaHistory;
        if (slot.source.rankIndex < list.length) {
          media = list[slot.source.rankIndex];
        }
      } else if (source.name.startsWith('recentNovel')) {
        itemType = ItemType.novel;
        final list = mediaMode.novelHistory;
        if (slot.source.rankIndex < list.length) {
          media = list[slot.source.rankIndex];
        }
      } else if (source.name.startsWith('smartResume')) {
        final combined = <OfflineMedia>[
          ...mediaMode.animeHistory,
          ...mediaMode.mangaHistory,
          ...mediaMode.novelHistory,
        ]..sort((a, b) {
            final timeA = a.currentEpisode?.lastWatchedTime ??
                a.currentChapter?.lastReadTime ??
                0;
            final timeB = b.currentEpisode?.lastWatchedTime ??
                b.currentChapter?.lastReadTime ??
                0;
            return timeB.compareTo(timeA);
          });
        if (slot.source.rankIndex < combined.length) {
          media = combined[slot.source.rankIndex];
          itemType = media.itemType;
        }
      } else if (source == AppShortcutSource.pinnedMedia) {
        if (slot.pinnedMediaId != null && isar.isOpen) {
          media = isar.offlineMedias
              .filter()
              .mediaIdEqualTo(slot.pinnedMediaId!)
              .findFirstSync();
          if (media != null) {
            itemType = media.itemType;
          }
        }
      }

      if (media != null) {
        final label = _formatMediaTitle(media, slot, itemType);
        final payload =
            'media_${itemType.name}_${media.mediaId}_${slot.tapAction.name}';
        return ShortcutItem(
          type: payload,
          localizedTitle: label,
          icon: Platform.isAndroid ? source.androidIconName : null,
        );
      }

      switch (slot.fallbackRule) {
        case AppShortcutFallbackRule.hide:
          return null;
        case AppShortcutFallbackRule.fallbackLibrary:
          return ShortcutItem(
            type: 'nav_library',
            localizedTitle: 'My Library',
            icon: Platform.isAndroid ? 'ic_shortcut_library' : null,
          );
        case AppShortcutFallbackRule.fallbackSearch:
          return ShortcutItem(
            type: 'nav_search',
            localizedTitle: 'Search',
            icon: Platform.isAndroid ? 'ic_shortcut_search' : null,
          );
      }
    }

    final androidIcon = Platform.isAndroid ? source.androidIconName : null;

    switch (source) {
      case AppShortcutSource.search:
        return ShortcutItem(
          type: 'nav_search',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'Search',
          icon: androidIcon,
        );
      case AppShortcutSource.library:
        return ShortcutItem(
          type: 'nav_library',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'My Library',
          icon: androidIcon,
        );
      case AppShortcutSource.history:
        return ShortcutItem(
          type: 'nav_history',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'History',
          icon: androidIcon,
        );
      case AppShortcutSource.downloads:
        return ShortcutItem(
          type: 'nav_downloads',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'Downloads',
          icon: androidIcon,
        );
      case AppShortcutSource.extensions:
        return ShortcutItem(
          type: 'nav_extensions',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'Extensions',
          icon: androidIcon,
        );
      case AppShortcutSource.stats:
        return ShortcutItem(
          type: 'nav_stats',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'Stats',
          icon: androidIcon,
        );
      case AppShortcutSource.surpriseMe:
        return ShortcutItem(
          type: 'nav_surprise',
          localizedTitle: slot.customLabel?.trim().isNotEmpty == true
              ? slot.customLabel!
              : 'Surprise Me',
          icon: androidIcon,
        );
      default:
        return null;
    }
  }

  String _formatMediaTitle(
    OfflineMedia media,
    AppShortcutSlotConfig slot,
    ItemType itemType,
  ) {
    if (!showDynamicTitles.value) {
      if (slot.customLabel?.trim().isNotEmpty == true) {
        return slot.customLabel!;
      }
      return itemType == ItemType.anime
          ? 'Continue Watching'
          : itemType == ItemType.manga
              ? 'Continue Reading'
              : 'Continue Novel';
    }

    final rawTitle = media.displayTitle;
    final cleanTitle =
        rawTitle.length > 20 ? '${rawTitle.substring(0, 18)}...' : rawTitle;

    switch (slot.titleStyle) {
      case AppShortcutTitleStyle.dynamicFull:
        final epOrCh = itemType == ItemType.anime
            ? 'Ep ${media.currentEpisode?.number ?? '?'}'
            : 'Ch ${media.currentChapter?.number ?? '?'}';
        return '$cleanTitle • $epOrCh';

      case AppShortcutTitleStyle.dynamicShort:
        return cleanTitle;

      case AppShortcutTitleStyle.actionPrefix:
        final prefix = itemType == ItemType.anime ? 'Watch' : 'Read';
        return '$prefix: $cleanTitle';

      case AppShortcutTitleStyle.custom:
        if (slot.customLabel?.trim().isNotEmpty == true) {
          return slot.customLabel!;
        }
        return cleanTitle;
    }
  }

  void handleShortcutTap(String shortcutType) {
    Logger.i('Handling shortcut navigation for: $shortcutType');

    try {
      if (shortcutType == 'nav_search') {
        Get.to(() => const SearchPage(searchTerm: ''));
        return;
      }

      if (shortcutType == 'nav_library') {
        Get.to(() => const MyLibrary());
        return;
      }

      if (shortcutType == 'nav_history') {
        Get.to(() => const AnymeXHistoryPage());
        return;
      }

      if (shortcutType == 'nav_downloads') {
        Get.to(() => const DownloadScreen());
        return;
      }

      if (shortcutType == 'nav_extensions') {
        Get.to(() => const ExtensionScreen());
        return;
      }

      if (shortcutType == 'nav_stats') {
        Get.to(() => const UserStatsPage());
        return;
      }

      if (shortcutType == 'nav_surprise') {
        _handleSurpriseMe();
        return;
      }

      if (shortcutType.startsWith('media_')) {
        _handleMediaShortcut(shortcutType);
        return;
      }
    } catch (e) {
      Logger.e('Error handling shortcut tap: $e');
    }
  }

  void _handleMediaShortcut(String shortcutType) {
    final parts = shortcutType.split('_');
    if (parts.length < 4) return;

    final typeStr = parts[1];
    final mediaId = parts[2];
    final actionStr = parts[3];

    ItemType itemType = ItemType.anime;
    if (typeStr == 'manga') itemType = ItemType.manga;
    if (typeStr == 'novel') itemType = ItemType.novel;

    final media = isar.offlineMedias
        .filter()
        .mediaIdEqualTo(mediaId)
        .and()
        .mediaTypeIndexEqualTo(itemType.index)
        .findFirstSync();

    if (media == null) {
      Get.to(() => const MyLibrary());
      return;
    }

    final historyModel = HistoryModel.fromOfflineMedia(media, itemType);

    if (actionStr == AppShortcutTapAction.openDetails.name) {
      historyModel.onCoverTap?.call();
    } else {
      historyModel.onTap?.call();
    }
  }

  void _handleSurpriseMe() {
    try {
      final allMedias = isar.offlineMedias.where().findAllSync();
      if (allMedias.isNotEmpty) {
        final randomMedia = allMedias[Random().nextInt(allMedias.length)];
        final type = randomMedia.itemType;
        final historyModel = HistoryModel.fromOfflineMedia(randomMedia, type);
        historyModel.onCoverTap?.call();
      } else {
        Get.to(() => const SearchPage(searchTerm: ''));
      }
    } catch (e) {
      Get.to(() => const SearchPage(searchTerm: ''));
    }
  }

  @override
  void onClose() {
    _animeSub?.cancel();
    _mangaSub?.cancel();
    _novelSub?.cancel();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
