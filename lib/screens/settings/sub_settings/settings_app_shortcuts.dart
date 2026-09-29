import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/main.dart';
import 'package:anymex/models/settings/app_shortcut_slot.dart';
import 'package:anymex/services/app_shortcut_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:isar_community/isar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;

class SettingsAppShortcuts extends StatefulWidget {
  const SettingsAppShortcuts({super.key});

  @override
  State<SettingsAppShortcuts> createState() => _SettingsAppShortcutsState();
}

class _SettingsAppShortcutsState extends State<SettingsAppShortcuts> {
  AppShortcutService get _service => AppShortcutService.instance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'App Shortcuts',
      body: Builder(
        builder: (ctx) {
          final headerHeight = AnymeXHeaderScope.of(ctx);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.0, headerHeight, 16.0, 32.0),
            child: Obx(() {
              final isEnabled = _service.isEnabled.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXSectionBuilder(
                    title: 'General',
                    children: [
                      AnymeXTile.toggle(
                        icon: Icons.touch_app_rounded,
                        title: 'Enable App Shortcuts',
                        subtitle:
                            'Show quick actions when long-pressing the app icon on home screen',
                        value: isEnabled,
                        onChanged: (val) => _service.toggleEnabled(val),
                      ),
                      if (isEnabled) ...[
                        AnymeXTile.toggle(
                          icon: Iconsax.text_block,
                          title: 'Dynamic Media Titles',
                          subtitle:
                              'Show real titles and episode/chapter numbers (e.g. "Solo Leveling • Ep 12")',
                          value: _service.showDynamicTitles.value,
                          onChanged: (val) => _service.toggleDynamicTitles(val),
                        ),
                      ],
                    ],
                  ),
                  if (isEnabled) ...[
                    const SizedBox(height: 16),
                    _buildLauncherPreview(context),
                    const SizedBox(height: 20),
                    AnymeXSectionBuilder(
                      title: 'Quick Presets',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppShortcutPreset.values.map((preset) {
                              final isSelected =
                                  _service.selectedPreset.value == preset;
                              return ChoiceChip(
                                avatar: Icon(
                                  preset.iconData,
                                  size: 16,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                                label: Text(preset.displayName),
                                selected: isSelected,
                                selectedColor: colors.primary.withOpacity(0.25),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.outline.withOpacity(0.2),
                                ),
                                onSelected: (_) {
                                  _service.applyPreset(preset);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnymeXSectionBuilder(
                      title: 'Slots Configuration',
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(
                            HugeIcons.strokeRoundedLayers01,
                            color: colors.primary,
                          ),
                          title: const AnymeXText(
                            'Active Shortcut Slots',
                            size: 15,
                            variant: TextVariant.semiBold,
                          ),
                          subtitle: const AnymeXText(
                            'Most Android launchers display 3 to 4 items',
                            size: 12,
                            variant: TextVariant.regular,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _service.slotCount.value > 1
                                    ? () => _service.setSlotCount(
                                        _service.slotCount.value - 1)
                                    : null,
                              ),
                              AnymeXText(
                                '${_service.slotCount.value}',
                                size: 16,
                                variant: TextVariant.bold,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _service.slotCount.value < 4
                                    ? () => _service.setSlotCount(
                                        _service.slotCount.value + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        _buildReorderableSlotList(context),
                      ],
                    ),
                  ],
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLauncherPreview(BuildContext context) {
    final colors = context.colors;
    final shortcutItems = _service.buildShortcutItems();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(HugeIcons.strokeRoundedSmartPhone01,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  const AnymeXText(
                    'Launcher Live Preview',
                    size: 13,
                    variant: TextVariant.semiBold,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnymeXText(
                  '${shortcutItems.length} active',
                  size: 11,
                  color: colors.primary,
                  variant: TextVariant.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: colors.outline.withOpacity(0.1)),
            ),
            child: shortcutItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: AnymeXText(
                        'No active shortcuts to display',
                        size: 13,
                        variant: TextVariant.regular,
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: shortcutItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _mapDrawableNameToIcon(item.icon),
                                size: 15,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnymeXText(
                                item.localizedTitle,
                                size: 13,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                variant: TextVariant.semiBold,
                              ),
                            ),
                            Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: colors.onSurfaceVariant.withOpacity(0.35),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (_, __, ___) => Container(
                      color: colors.primary,
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const AnymeXText(
                'AnymeX',
                size: 12,
                variant: TextVariant.bold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _mapDrawableNameToIcon(String? iconName) {
    switch (iconName) {
      case 'ic_shortcut_play':
        return HugeIcons.strokeRoundedPlay;
      case 'ic_shortcut_book':
        return Iconsax.book;
      case 'ic_shortcut_novel':
        return Icons.auto_stories_outlined;
      case 'ic_shortcut_search':
        return IconlyLight.search;
      case 'ic_shortcut_library':
        return HugeIcons.strokeRoundedLibrary;
      case 'ic_shortcut_history':
        return Iconsax.clock;
      case 'ic_shortcut_download':
        return HugeIcons.strokeRoundedDownload01;
      case 'ic_shortcut_extension':
        return Icons.extension_outlined;
      case 'ic_shortcut_stats':
        return Icons.bar_chart_rounded;
      case 'ic_shortcut_shuffle':
        return Icons.shuffle_rounded;
      case 'ic_shortcut_pin':
        return Icons.push_pin_outlined;
      default:
        return HugeIcons.strokeRoundedPlay;
    }
  }

  Widget _buildReorderableSlotList(BuildContext context) {
    final colors = context.colors;
    final slots = _service.slots;
    final activeCount = _service.slotCount.value;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      onReorder: (oldIndex, newIndex) =>
          _service.reorderSlots(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isActive = index < activeCount;

        return Material(
          key: ValueKey(slot.id),
          color: Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.primary.withOpacity(0.15)
                    : colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                slot.source.iconData,
                color: isActive
                    ? colors.primary
                    : colors.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary
                        : colors.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: AnymeXText(
                    slot.source.displayName,
                    size: 14,
                    variant: TextVariant.semiBold,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              slot.source.isMedia
                  ? '${slot.tapAction.displayName} • ${slot.titleStyle.displayName}'
                  : 'Navigation Shortcut',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: () => _openSlotConfigSheet(context, index, slot),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: colors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSlotConfigSheet(
      BuildContext context, int index, AppShortcutSlotConfig slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlotConfigSheet(
        slot: slot,
        onSave: (updated) {
          _service.updateSlot(index, updated);
          Navigator.pop(ctx);
          snackBar('Slot #${index + 1} updated');
        },
      ),
    );
  }
}

class _SlotConfigSheet extends StatefulWidget {
  final AppShortcutSlotConfig slot;
  final ValueChanged<AppShortcutSlotConfig> onSave;

  const _SlotConfigSheet({
    required this.slot,
    required this.onSave,
  });

  @override
  State<_SlotConfigSheet> createState() => _SlotConfigSheetState();
}

class _SlotConfigSheetState extends State<_SlotConfigSheet> {
  late AppShortcutSource _source;
  late AppShortcutTapAction _tapAction;
  late AppShortcutTitleStyle _titleStyle;
  late AppShortcutFallbackRule _fallbackRule;
  late TextEditingController _customLabelCtrl;

  String? _pinnedMediaId;
  String? _pinnedMediaTitle;

  @override
  void initState() {
    super.initState();
    _source = widget.slot.source;
    _tapAction = widget.slot.tapAction;
    _titleStyle = widget.slot.titleStyle;
    _fallbackRule = widget.slot.fallbackRule;
    _customLabelCtrl =
        TextEditingController(text: widget.slot.customLabel ?? '');
    _pinnedMediaId = widget.slot.pinnedMediaId;
    _pinnedMediaTitle = widget.slot.pinnedMediaTitle;
  }

  @override
  void dispose() {
    _customLabelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const AnymeXText(
              'Customize Shortcut Slot',
              size: 18,
              variant: TextVariant.bold,
            ),
            const SizedBox(height: 16),
            const AnymeXText('Shortcut Source',
                size: 13, variant: TextVariant.semiBold),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outline.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppShortcutSource>(
                  value: _source,
                  isExpanded: true,
                  items: AppShortcutSource.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s.iconData, size: 18, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _source = val);
                  },
                ),
              ),
            ),
            if (_source == AppShortcutSource.pinnedMedia) ...[
              const SizedBox(height: 16),
              const AnymeXText('Pinned Item from Library',
                  size: 13, variant: TextVariant.semiBold),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.outline.withOpacity(0.2)),
                ),
                leading: const Icon(Icons.push_pin_rounded),
                title: Text(
                  _pinnedMediaTitle ?? 'Tap to pick an anime/manga',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickPinnedMedia,
              ),
            ],
            if (_source.isMedia) ...[
              const SizedBox(height: 16),
              const AnymeXText('On-Tap Action',
                  size: 13, variant: TextVariant.semiBold),
              const SizedBox(height: 8),
              SegmentedButton<AppShortcutTapAction>(
                segments: AppShortcutTapAction.values.map((action) {
                  return ButtonSegment(
                    value: action,
                    icon: Icon(action.iconData, size: 16),
                    label: Text(
                      action == AppShortcutTapAction.directPlayOrRead
                          ? 'Instant Play'
                          : 'Details Page',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                selected: {_tapAction},
                onSelectionChanged: (set) {
                  setState(() => _tapAction = set.first);
                },
              ),
              const SizedBox(height: 16),
              const AnymeXText('Title Display Style',
                  size: 13, variant: TextVariant.semiBold),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppShortcutTitleStyle>(
                    value: _titleStyle,
                    isExpanded: true,
                    items: AppShortcutTitleStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Row(
                          children: [
                            Icon(style.iconData,
                                size: 18, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                style.displayName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _titleStyle = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AnymeXText('Fallback (If item not found)',
                  size: 13, variant: TextVariant.semiBold),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppShortcutFallbackRule>(
                    value: _fallbackRule,
                    isExpanded: true,
                    items: AppShortcutFallbackRule.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Icon(f.iconData, size: 18, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.displayName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fallbackRule = val);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const AnymeXText('Custom Label (Optional)',
                size: 13, variant: TextVariant.semiBold),
            const SizedBox(height: 8),
            TextField(
              controller: _customLabelCtrl,
              decoration: InputDecoration(
                hintText: 'Leave empty for automatic label',
                hintStyle:
                    TextStyle(color: colors.onSurfaceVariant.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: colors.outline.withOpacity(0.2)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final updated = widget.slot.copyWith(
                    source: _source,
                    tapAction: _tapAction,
                    titleStyle: _titleStyle,
                    fallbackRule: _fallbackRule,
                    customLabel: _customLabelCtrl.text.trim().isEmpty
                        ? null
                        : _customLabelCtrl.text.trim(),
                    pinnedMediaId: _pinnedMediaId,
                    pinnedMediaTitle: _pinnedMediaTitle,
                  );
                  widget.onSave(updated);
                },
                child: const Text('Save Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickPinnedMedia() {
    final medias = isar.offlineMedias.where().findAllSync();
    if (medias.isEmpty) {
      snackBar('Your offline library is empty');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const AnymeXText(
                'Select Media from Library',
                size: 16,
                variant: TextVariant.bold,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: medias.length,
                  itemBuilder: (_, i) {
                    final item = medias[i];
                    return ListTile(
                      leading: Icon(
                        item.itemType == ItemType.anime
                            ? HugeIcons.strokeRoundedPlay
                            : Iconsax.book,
                      ),
                      title: Text(item.displayTitle),
                      subtitle: Text(item.itemType.name.toUpperCase()),
                      onTap: () {
                        setState(() {
                          _pinnedMediaId = item.mediaId;
                          _pinnedMediaTitle = item.displayTitle;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
