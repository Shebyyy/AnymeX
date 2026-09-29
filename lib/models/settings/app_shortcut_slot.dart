import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

enum AppShortcutSource {
  recentAnime1,
  recentAnime2,
  recentAnime3,
  recentAnime4,
  recentManga1,
  recentManga2,
  recentManga3,
  recentManga4,
  recentNovel1,
  recentNovel2,
  recentNovel3,
  recentNovel4,
  smartResume1,
  smartResume2,
  smartResume3,
  smartResume4,
  pinnedMedia,
  search,
  library,
  history,
  downloads,
  extensions,
  stats,
  surpriseMe;

  String get displayName {
    switch (this) {
      case AppShortcutSource.recentAnime1:
        return 'Recent Anime #1 (Latest)';
      case AppShortcutSource.recentAnime2:
        return 'Recent Anime #2';
      case AppShortcutSource.recentAnime3:
        return 'Recent Anime #3';
      case AppShortcutSource.recentAnime4:
        return 'Recent Anime #4';
      case AppShortcutSource.recentManga1:
        return 'Recent Manga #1 (Latest)';
      case AppShortcutSource.recentManga2:
        return 'Recent Manga #2';
      case AppShortcutSource.recentManga3:
        return 'Recent Manga #3';
      case AppShortcutSource.recentManga4:
        return 'Recent Manga #4';
      case AppShortcutSource.recentNovel1:
        return 'Recent Novel #1 (Latest)';
      case AppShortcutSource.recentNovel2:
        return 'Recent Novel #2';
      case AppShortcutSource.recentNovel3:
        return 'Recent Novel #3';
      case AppShortcutSource.recentNovel4:
        return 'Recent Novel #4';
      case AppShortcutSource.smartResume1:
        return 'Smart Resume #1 (Latest Media)';
      case AppShortcutSource.smartResume2:
        return 'Smart Resume #2';
      case AppShortcutSource.smartResume3:
        return 'Smart Resume #3';
      case AppShortcutSource.smartResume4:
        return 'Smart Resume #4';
      case AppShortcutSource.pinnedMedia:
        return 'Pinned Library Media';
      case AppShortcutSource.search:
        return 'Search';
      case AppShortcutSource.library:
        return 'My Library';
      case AppShortcutSource.history:
        return 'History';
      case AppShortcutSource.downloads:
        return 'Downloads';
      case AppShortcutSource.extensions:
        return 'Extensions / Sources';
      case AppShortcutSource.stats:
        return 'Stats & Analytics';
      case AppShortcutSource.surpriseMe:
        return 'Surprise Me (Random Pick)';
    }
  }

  String get category {
    if (name.startsWith('recentAnime')) return 'Anime';
    if (name.startsWith('recentManga')) return 'Manga';
    if (name.startsWith('recentNovel')) return 'Novel';
    if (name.startsWith('smartResume')) return 'Smart Resume';
    if (this == AppShortcutSource.pinnedMedia) return 'Pinned';
    return 'Navigation & Utility';
  }

  bool get isMedia =>
      name.startsWith('recentAnime') ||
      name.startsWith('recentManga') ||
      name.startsWith('recentNovel') ||
      name.startsWith('smartResume') ||
      this == AppShortcutSource.pinnedMedia;

  int get rankIndex {
    if (name.endsWith('1')) return 0;
    if (name.endsWith('2')) return 1;
    if (name.endsWith('3')) return 2;
    if (name.endsWith('4')) return 3;
    return 0;
  }

  String get androidIconName {
    if (name.startsWith('recentAnime')) return 'ic_shortcut_play';
    if (name.startsWith('recentManga')) return 'ic_shortcut_book';
    if (name.startsWith('recentNovel')) return 'ic_shortcut_novel';
    if (name.startsWith('smartResume')) return 'ic_shortcut_play';
    switch (this) {
      case AppShortcutSource.pinnedMedia:
        return 'ic_shortcut_pin';
      case AppShortcutSource.search:
        return 'ic_shortcut_search';
      case AppShortcutSource.library:
        return 'ic_shortcut_library';
      case AppShortcutSource.history:
        return 'ic_shortcut_history';
      case AppShortcutSource.downloads:
        return 'ic_shortcut_download';
      case AppShortcutSource.extensions:
        return 'ic_shortcut_extension';
      case AppShortcutSource.stats:
        return 'ic_shortcut_stats';
      case AppShortcutSource.surpriseMe:
        return 'ic_shortcut_shuffle';
      default:
        return 'ic_shortcut_play';
    }
  }

  IconData get iconData {
    if (name.startsWith('recentAnime')) return HugeIcons.strokeRoundedPlay;
    if (name.startsWith('recentManga')) return Iconsax.book;
    if (name.startsWith('recentNovel')) return Icons.auto_stories_outlined;
    if (name.startsWith('smartResume')) return HugeIcons.strokeRoundedPlayList;
    switch (this) {
      case AppShortcutSource.pinnedMedia:
        return Icons.push_pin_outlined;
      case AppShortcutSource.search:
        return IconlyLight.search;
      case AppShortcutSource.library:
        return HugeIcons.strokeRoundedLibrary;
      case AppShortcutSource.history:
        return Iconsax.clock;
      case AppShortcutSource.downloads:
        return HugeIcons.strokeRoundedDownload01;
      case AppShortcutSource.extensions:
        return Icons.extension_outlined;
      case AppShortcutSource.stats:
        return Icons.bar_chart_rounded;
      case AppShortcutSource.surpriseMe:
        return Icons.shuffle_rounded;
      default:
        return HugeIcons.strokeRoundedPlay;
    }
  }
}

enum AppShortcutTapAction {
  directPlayOrRead,
  openDetails;

  String get displayName {
    switch (this) {
      case AppShortcutTapAction.directPlayOrRead:
        return 'Direct Play / Read (Instant)';
      case AppShortcutTapAction.openDetails:
        return 'Open Media Details Page';
    }
  }

  IconData get iconData {
    switch (this) {
      case AppShortcutTapAction.directPlayOrRead:
        return HugeIcons.strokeRoundedPlay;
      case AppShortcutTapAction.openDetails:
        return HugeIcons.strokeRoundedInformationCircle;
    }
  }
}

enum AppShortcutTitleStyle {
  dynamicFull,
  dynamicShort,
  actionPrefix,
  custom;

  String get displayName {
    switch (this) {
      case AppShortcutTitleStyle.dynamicFull:
        return 'Dynamic Full (Title • Ep/Ch)';
      case AppShortcutTitleStyle.dynamicShort:
        return 'Dynamic Title Only';
      case AppShortcutTitleStyle.actionPrefix:
        return 'Prefix + Title (e.g. Watch: Title)';
      case AppShortcutTitleStyle.custom:
        return 'Custom Static Label';
    }
  }

  IconData get iconData {
    switch (this) {
      case AppShortcutTitleStyle.dynamicFull:
        return Iconsax.text_block;
      case AppShortcutTitleStyle.dynamicShort:
        return Iconsax.text;
      case AppShortcutTitleStyle.actionPrefix:
        return Iconsax.textalign_left;
      case AppShortcutTitleStyle.custom:
        return Icons.edit_note_rounded;
    }
  }
}

enum AppShortcutFallbackRule {
  hide,
  fallbackLibrary,
  fallbackSearch;

  String get displayName {
    switch (this) {
      case AppShortcutFallbackRule.hide:
        return 'Hide Shortcut';
      case AppShortcutFallbackRule.fallbackLibrary:
        return 'Open My Library';
      case AppShortcutFallbackRule.fallbackSearch:
        return 'Open Search';
    }
  }

  IconData get iconData {
    switch (this) {
      case AppShortcutFallbackRule.hide:
        return Icons.visibility_off_outlined;
      case AppShortcutFallbackRule.fallbackLibrary:
        return HugeIcons.strokeRoundedLibrary;
      case AppShortcutFallbackRule.fallbackSearch:
        return IconlyLight.search;
    }
  }
}

enum AppShortcutPreset {
  balanced,
  allAnime,
  allManga,
  speedNav,
  custom;

  String get displayName {
    switch (this) {
      case AppShortcutPreset.balanced:
        return 'Balanced';
      case AppShortcutPreset.allAnime:
        return 'All Anime';
      case AppShortcutPreset.allManga:
        return 'All Manga';
      case AppShortcutPreset.speedNav:
        return 'Speed Nav';
      case AppShortcutPreset.custom:
        return 'Custom';
    }
  }

  IconData get iconData {
    switch (this) {
      case AppShortcutPreset.balanced:
        return Icons.balance_rounded;
      case AppShortcutPreset.allAnime:
        return HugeIcons.strokeRoundedPlay;
      case AppShortcutPreset.allManga:
        return Iconsax.book;
      case AppShortcutPreset.speedNav:
        return HugeIcons.strokeRoundedCompass;
      case AppShortcutPreset.custom:
        return HugeIcons.strokeRoundedSlidersHorizontal;
    }
  }

  String get description {
    switch (this) {
      case AppShortcutPreset.balanced:
        return 'Anime + Manga + Search + Library';
      case AppShortcutPreset.allAnime:
        return 'Last 4 watched anime episodes';
      case AppShortcutPreset.allManga:
        return 'Last 4 read manga chapters';
      case AppShortcutPreset.speedNav:
        return 'Search + Library + History + Downloads';
      case AppShortcutPreset.custom:
        return 'Custom slot configurations';
    }
  }
}

class AppShortcutSlotConfig {
  final String id;
  AppShortcutSource source;
  AppShortcutTapAction tapAction;
  AppShortcutTitleStyle titleStyle;
  String? customLabel;
  String? pinnedMediaId;
  String? pinnedMediaTitle;
  int? pinnedMediaTypeIndex;
  AppShortcutFallbackRule fallbackRule;

  AppShortcutSlotConfig({
    required this.id,
    required this.source,
    this.tapAction = AppShortcutTapAction.directPlayOrRead,
    this.titleStyle = AppShortcutTitleStyle.dynamicFull,
    this.customLabel,
    this.pinnedMediaId,
    this.pinnedMediaTitle,
    this.pinnedMediaTypeIndex,
    this.fallbackRule = AppShortcutFallbackRule.hide,
  });

  AppShortcutSlotConfig copyWith({
    String? id,
    AppShortcutSource? source,
    AppShortcutTapAction? tapAction,
    AppShortcutTitleStyle? titleStyle,
    String? customLabel,
    String? pinnedMediaId,
    String? pinnedMediaTitle,
    int? pinnedMediaTypeIndex,
    AppShortcutFallbackRule? fallbackRule,
  }) {
    return AppShortcutSlotConfig(
      id: id ?? this.id,
      source: source ?? this.source,
      tapAction: tapAction ?? this.tapAction,
      titleStyle: titleStyle ?? this.titleStyle,
      customLabel: customLabel ?? this.customLabel,
      pinnedMediaId: pinnedMediaId ?? this.pinnedMediaId,
      pinnedMediaTitle: pinnedMediaTitle ?? this.pinnedMediaTitle,
      pinnedMediaTypeIndex: pinnedMediaTypeIndex ?? this.pinnedMediaTypeIndex,
      fallbackRule: fallbackRule ?? this.fallbackRule,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'tapAction': tapAction.name,
        'titleStyle': titleStyle.name,
        'customLabel': customLabel,
        'pinnedMediaId': pinnedMediaId,
        'pinnedMediaTitle': pinnedMediaTitle,
        'pinnedMediaTypeIndex': pinnedMediaTypeIndex,
        'fallbackRule': fallbackRule.name,
      };

  factory AppShortcutSlotConfig.fromJson(Map<String, dynamic> json) {
    AppShortcutSource parseSource(String? val) {
      return AppShortcutSource.values.firstWhere(
        (e) => e.name == val,
        orElse: () => AppShortcutSource.search,
      );
    }

    AppShortcutTapAction parseTapAction(String? val) {
      return AppShortcutTapAction.values.firstWhere(
        (e) => e.name == val,
        orElse: () => AppShortcutTapAction.directPlayOrRead,
      );
    }

    AppShortcutTitleStyle parseTitleStyle(String? val) {
      return AppShortcutTitleStyle.values.firstWhere(
        (e) => e.name == val,
        orElse: () => AppShortcutTitleStyle.dynamicFull,
      );
    }

    AppShortcutFallbackRule parseFallbackRule(String? val) {
      return AppShortcutFallbackRule.values.firstWhere(
        (e) => e.name == val,
        orElse: () => AppShortcutFallbackRule.hide,
      );
    }

    return AppShortcutSlotConfig(
      id: json['id'] as String? ??
          'slot_${DateTime.now().millisecondsSinceEpoch}',
      source: parseSource(json['source'] as String?),
      tapAction: parseTapAction(json['tapAction'] as String?),
      titleStyle: parseTitleStyle(json['titleStyle'] as String?),
      customLabel: json['customLabel'] as String?,
      pinnedMediaId: json['pinnedMediaId'] as String?,
      pinnedMediaTitle: json['pinnedMediaTitle'] as String?,
      pinnedMediaTypeIndex: json['pinnedMediaTypeIndex'] as int?,
      fallbackRule: parseFallbackRule(json['fallbackRule'] as String?),
    );
  }

  static List<AppShortcutSlotConfig> getPresetSlots(AppShortcutPreset preset) {
    switch (preset) {
      case AppShortcutPreset.allAnime:
        return [
          AppShortcutSlotConfig(
            id: 'slot_1',
            source: AppShortcutSource.recentAnime1,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_2',
            source: AppShortcutSource.recentAnime2,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_3',
            source: AppShortcutSource.recentAnime3,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_4',
            source: AppShortcutSource.recentAnime4,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
        ];

      case AppShortcutPreset.allManga:
        return [
          AppShortcutSlotConfig(
            id: 'slot_1',
            source: AppShortcutSource.recentManga1,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_2',
            source: AppShortcutSource.recentManga2,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_3',
            source: AppShortcutSource.recentManga3,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_4',
            source: AppShortcutSource.recentManga4,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
        ];

      case AppShortcutPreset.speedNav:
        return [
          AppShortcutSlotConfig(
            id: 'slot_1',
            source: AppShortcutSource.search,
          ),
          AppShortcutSlotConfig(
            id: 'slot_2',
            source: AppShortcutSource.library,
          ),
          AppShortcutSlotConfig(
            id: 'slot_3',
            source: AppShortcutSource.history,
          ),
          AppShortcutSlotConfig(
            id: 'slot_4',
            source: AppShortcutSource.downloads,
          ),
        ];

      case AppShortcutPreset.balanced:
      case AppShortcutPreset.custom:
        return [
          AppShortcutSlotConfig(
            id: 'slot_1',
            source: AppShortcutSource.recentAnime1,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_2',
            source: AppShortcutSource.recentManga1,
            tapAction: AppShortcutTapAction.directPlayOrRead,
          ),
          AppShortcutSlotConfig(
            id: 'slot_3',
            source: AppShortcutSource.search,
          ),
          AppShortcutSlotConfig(
            id: 'slot_4',
            source: AppShortcutSource.library,
          ),
        ];
    }
  }
}
