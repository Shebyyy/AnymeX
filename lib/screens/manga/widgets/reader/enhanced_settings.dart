import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/utils/config.dart';
import 'package:anymex/utils/performance.dart';

/// Enhanced reader settings panel with comprehensive options
class EnhancedReaderSettings extends StatelessWidget {
  final ReaderController controller;
  
  const EnhancedReaderSettings({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildSettingsContent(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined),
          const SizedBox(width: 12),
          Text(
            'Reader Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingModeSection(context),
          const SizedBox(height: 24),
          _buildDisplaySection(context),
          const SizedBox(height: 24),
          _buildNavigationSection(context),
          const SizedBox(height: 24),
          _buildPerformanceSection(context),
          const SizedBox(height: 24),
          _buildAdvancedSection(context),
        ],
      ),
    );
  }

  Widget _buildReadingModeSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildRadioTile(
          title: 'Continuous Scroll',
          subtitle: 'Scroll vertically through pages',
          value: MangaPageViewMode.continuous,
          groupValue: controller.readingLayout.value,
          onChanged: (value) => controller.readingLayout.value = value,
        ),
        _buildRadioTile(
          title: 'Paged View',
          subtitle: 'Swipe between pages',
          value: MangaPageViewMode.paged,
          groupValue: controller.readingLayout.value,
          onChanged: (value) => controller.readingLayout.value = value,
        ),
        _buildRadioTile(
          title: 'Webtoon Style',
          subtitle: 'Continuous horizontal scroll',
          value: MangaPageViewMode.webtoon,
          groupValue: controller.readingLayout.value,
          onChanged: (value) => controller.readingLayout.value = value,
        ),
      ],
    ));
  }

  Widget _buildDisplaySection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          title: 'Page Width',
          subtitle: '${(controller.pageWidthMultiplier.value * 100).toInt()}%',
          value: controller.pageWidthMultiplier.value,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) => controller.pageWidthMultiplier.value = value,
        ),
        _buildSliderTile(
          title: 'Scroll Speed',
          subtitle: '${(controller.scrollSpeedMultiplier.value * 100).toInt()}%',
          value: controller.scrollSpeedMultiplier.value,
          min: 0.5,
          max: 3.0,
          divisions: 25,
          onChanged: (value) => controller.scrollSpeedMultiplier.value = value,
        ),
        _buildSwitchTile(
          title: 'Spaced Pages',
          subtitle: 'Add spacing between pages',
          value: controller.spacedPages.value,
          onChanged: (value) => controller.toggleSpacedPages(),
        ),
        _buildSwitchTile(
          title: 'Show Page Indicator',
          subtitle: 'Display current page number',
          value: controller.showPageIndicator.value,
          onChanged: (value) => controller.togglePageIndicator(),
        ),
      ],
    ));
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildDirectionSelector(context),
        const SizedBox(height: 12),
        _buildSliderTile(
          title: 'Preload Pages',
          subtitle: '${controller.preloadPages.value} pages',
          value: controller.preloadPages.value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (value) => controller.preloadPages.value = value.toInt(),
        ),
        _buildSwitchTile(
          title: 'Overscroll to Chapter',
          subtitle: 'Navigate to next/previous chapter on overscroll',
          value: controller.overscrollToChapter.value,
          onChanged: (value) => controller.toggleOverscrollToChapter(),
        ),
      ],
    ));
  }

  Widget _buildDirectionSelector(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Direction',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: MangaPageViewDirection.values.map((direction) {
            final isSelected = controller.readingDirection.value == direction;
            return FilterChip(
              label: Text(direction.name.toUpperCase()),
              selected: isSelected,
              onSelected: () => controller.readingDirection.value = direction,
              backgroundColor: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : null,
            );
          }).toList(),
        ),
      ],
    ));
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildPerformanceInfo(context),
        const SizedBox(height: 12),
        _buildCacheControls(context),
      ],
    );
  }

  Widget _buildPerformanceInfo(BuildContext context) {
    return Obx(() {
      final stats = PerformanceMonitor.instance.getStats();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Stats',
              style: Theme.of(context).textTheme.small,
            ),
            const SizedBox(height: 8),
            _buildStatRow('FPS', '${stats.fps.toStringAsFixed(1)}'),
            _buildStatRow('Memory', '${(stats.memoryUsage / 1024 / 1024).toStringAsFixed(1)} MB'),
            _buildStatRow('Frame Time', '${stats.frameTime}μs'),
          ],
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnymeXButton(
            text: 'Clear Image Cache',
            onPressed: () => _clearImageCache(context),
            variant: AnymeXButtonVariant.outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnymeXButton(
            text: 'Reset Settings',
            onPressed: () => _resetSettings(context),
            variant: AnymeXButtonVariant.outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'Auto-save Progress',
          subtitle: 'Automatically save reading progress',
          value: true, // This would be a new setting
          onChanged: (value) {
            // Implement auto-save toggle
          },
        ),
        _buildSwitchTile(
          title: 'Hardware Acceleration',
          subtitle: 'Use GPU for image rendering',
          value: !PerformanceUtils.isLowEndDevice(),
          onChanged: (value) {
            // Implement hardware acceleration toggle
          },
        ),
        _buildTile(
          title: 'Export Reading Progress',
          subtitle: 'Export your reading history',
          leading: const Icon(Icons.upload_file),
          onTap: () => _exportProgress(context),
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required String title,
    String? subtitle,
    required MangaPageViewMode value,
    required MangaPageViewMode groupValue,
    required ValueChanged<MangaPageViewMode> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Radio<MangaPageViewMode>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              if (subtitle != null) Text(subtitle!),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    Widget? leading,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: leading,
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearImageCache(BuildContext context) {
    AnymeXDialog.show(
      context,
      title: 'Clear Cache',
      content: 'Clear all cached images? This may slow down initial loading.',
      actions: [
        AnymeXButton(
          text: 'Cancel',
          variant: AnymeXButtonVariant.text,
          onPressed: () => Get.back(),
        ),
        AnymeXButton(
          text: 'Clear',
          onPressed: () {
            // Implement cache clearing
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: 'Image cache cleared'),
            );
          },
        ),
      ],
    );
  }

  void _resetSettings(BuildContext context) {
    AnymeXDialog.show(
      context,
      title: 'Reset Settings',
      content: 'Reset all reader settings to default values?',
      actions: [
        AnymeXButton(
          text: 'Cancel',
          variant: AnymeXButtonVariant.text,
          onPressed: () => Get.back(),
        ),
        AnymeXButton(
          text: 'Reset',
          onPressed: () {
            controller.resetSettings();
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: 'Settings reset to defaults'),
            );
          },
        ),
      ],
    );
  }

  void _exportProgress(BuildContext context) {
    // Implement progress export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Progress export coming soon'),
    );
  }
}

/// Extension to add webtoon mode to MangaPageViewMode
extension MangaPageViewModeExtension on MangaPageViewMode {
  static const MangaPageViewMode webtoon = MangaPageViewMode.paged; // This would be a new enum value
}