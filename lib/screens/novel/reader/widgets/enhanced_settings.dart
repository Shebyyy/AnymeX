import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/novel/reader/controller/enhanced_reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/utils/performance.dart';

/// Comprehensive reader settings panel
class EnhancedReaderSettings extends StatelessWidget {
  final EnhancedNovelReaderController controller;
  
  const EnhancedReaderSettings({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.8,
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
            'Enhanced Reader Settings',
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
          _buildAutoReadingSection(context),
          const SizedBox(24),
          _buildThemeSection(context),
          const SizedBox(height: 24),
          _buildAdvancedSection(context),
          const SizedBox(height: 24),
          _buildPerformanceSection(context),
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
          title: 'Standard',
          subtitle: 'Traditional reading experience',
          value: EnhancedReadingMode.standard,
          groupValue: controller.readingMode.value,
          onChanged: (value) => controller.readingMode.value = value,
        ),
        _buildRadioTile(
          title: 'Focus Mode',
          subtitle: 'Reduce distractions with minimal UI',
          value: EnhancedReadingMode.focus,
          groupValue: controller.readingMode.value,
          onChanged: (value) => controller.readingMode.value = value,
        ),
        _buildRadioTile(
          title: 'Speed Mode',
          subtitle: 'Optimized for fast reading',
          value: EnhancedReadingMode.speed,
          groupValue: controller.readingMode.value,
          onChanged: (value) => controller.readingMode.value = value,
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
          title: 'Font Size',
          subtitle: '${controller.fontSize.value.toInt()}px',
          value: controller.fontSize.value,
          min: 12.0,
          max: 24.0,
          divisions: 12,
          onChanged: (value) => controller.fontSize.value = value,
        ),
        _buildSliderTile(
          title: 'Line Height',
          subtitle: '${controller.lineHeight.value.toStringAsFixed(1)}',
          value: controller.lineHeight.value,
          min: 1.2,
          max: 2.0,
          divisions: 8,
          onChanged: (value) => controller.lineHeight.value = value,
        ),
        _buildSliderTile(
          title: 'Text Width',
          subtitle: '${(controller.textWidth.value * 100).toInt()}%',
          value: controller.textWidth.value,
          min: 0.3,
          max: 1.0,
          divisions: 7,
          onChanged: (value) => controller.textWidth.value = value,
        ),
        _buildSliderTile(
          title: 'Column Count',
          subtitle: '${controller.columnCount.value}',
          value: controller.columnCount.value.toDouble(),
          min: 1,
          max: 3,
          divisions: 2,
          onChanged: (value) => controller.columnCount.value = value.toInt(),
        ),
        _buildSwitchTile(
          title: 'Enable Animations',
          subtitle: 'Smooth transitions and effects',
          value: controller.enableAnimations.value,
          onChanged: (value) => controller.enableAnimations.value = value,
        ),
        _buildSwitchTile(
          title: 'Enable Page Transitions',
          subtitle: 'Animated page turns',
          value: controller.enablePageTransitions.value,
          onChanged: (value) => controller.enablePageTransitions.value = value,
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
        _buildRadioTile(
          title: 'Smooth Scrolling',
          subtitle: 'Fluid scrolling experience',
          value: EnhancedScrollMode.smooth,
          groupValue: controller.scrollMode.value,
          onChanged: (value) => controller.scrollMode.value = value,
        ),
        _buildRadioTile(
          title: 'Momentum Scrolling',
          subtitle: 'Physics-based scrolling',
          value: EnhancedScrollMode.momentum,
          groupValue: controller.scrollMode.value,
          onChanged: (value) => controller.scrollMode.value = value,
        ),
        _buildRadioTile(
          title: 'Virtual Scrolling',
          subtitle: 'Optimized for long content',
          value: EnhancedScrollMode.virtual,
          groupValue: controller.scrollMode.value,
          onChanged: (value) => controller.scrollMode.value = value,
        ),
      ],
    ));
  }

  Widget _buildAutoReadingSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto Reading',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'Auto Scroll',
          subtitle: 'Continuous scrolling',
          value: controller.autoScrollEnabled.value,
          onChanged: (value) => controller.toggleAutoScroll(),
        ),
        _buildSliderTile(
          title: 'Scroll Speed',
          subtitle: '${controller.autoScrollSpeed.value.toStringAsFixed(1)}x',
          value: controller.autoScrollSpeed.value,
          min: 0.2,
          max: 3.0,
          divisions: 14,
          onChanged: (value) => controller.increaseAutoScrollSpeed(),
        ),
        _buildSwitchTile(
          title: 'Auto Page Turn',
          subtitle: 'Automatic page turning',
          value: controller.autoPageTurn.value,
          onChanged: (value) => controller.toggleAutoPageTurn(),
        ),
        _buildSliderTile(
          title: 'Page Delay',
          subtitle: '${controller.autoPageDelay.value} seconds',
          value: controller.autoPageDelay.value.toDouble(),
          min: 10,
          max: 120,
          divisions: 11,
          onChanged: (value) => controller.adjustAutoPageDelay(value.toInt()),
        ),
      ],
    ));
  }

  Widget _buildThemeSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildThemeChip('Light', EnhancedThemeMode.light),
            _buildThemeChip('Dark', EnhancedThemeMode.dark),
            _buildThemeChip('Sepia', EnhancedThemeMode.sepia),
            _buildThemeChip('Custom', EnhancedThemeMode.custom),
          ],
        ),
        const SizedBox(height: 16),
        _buildSliderTile(
          title: 'Background Opacity',
          subtitle: '${(controller.backgroundOpacity.value * 100).toInt()}%',
          value: controller.backgroundOpacity.value,
          min: 0.3,
          max: 1.0,
          divisions: 7,
          onChanged: (value) => controller.adjustBackgroundOpacity(value),
        ),
        _buildSwitchTile(
          title: 'Sepia Effect',
          subtitle: 'Reduce eye strain',
          value: controller.enableSepiaEffect.value,
          onChanged: (value) => controller.toggleSepiaEffect(),
        ),
        if (controller.themeMode.value == EnhancedThemeMode.custom) ...[
          const SizedBox(height: 16),
          _buildColorPickerTile(
            title: 'Custom Background',
            subtitle: controller.customBackgroundColor.value.isNotEmpty 
                ? 'Custom color selected'
                : 'Tap to select color',
            color: controller.customBackgroundColor.value.isNotEmpty 
                ? controller.customBackgroundColor.value
                : Colors.grey,
            onTap: () => _showColorPicker(context),
          ),
        ],
      ],
    ));
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Features',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'Text-to-Speech',
          subtitle: 'Read content aloud',
          value: controller.enableTextToSpeech.value,
          onChanged: (value) => controller.enableTextToSpeech.value = value,
        ),
        _buildSwitchTile(
          title: 'Translation',
          subtitle: 'Translate text content',
          value: controller.enableTranslation.value,
          onChanged: (value) => controller.enableTranslation.value = value,
        ),
        _buildTile(
          title: 'Export Reading Progress',
          subtitle: 'Export your reading history',
          leading: const Icon(Icons.upload_file),
          onTap: () => _exportProgress(context),
        ),
        _buildTile(
          title: 'Import Bookmarks',
          subtitle: 'Import bookmarks from backup',
          leading: const Icon(Icons.download),
          onTap: () => _importBookmarks(context),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildPerformanceInfo(context),
        const SizedBox(height: 12),
        _buildPerformanceControls(context),
      ],
    ));
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

  Widget _buildPerformanceControls(BuildContext context) {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Hardware Acceleration',
          subtitle: 'Use GPU for rendering',
          value: controller.enableHardwareAcceleration.value,
          onChanged: (value) => controller.enableHardwareAcceleration.value = value,
        ),
        _buildSwitchTile(
          title: 'Virtual Scrolling',
          subtitle: 'Optimize for long content',
          value: controller.enableVirtualScrolling.value,
          onChanged: (value) => controller.enableVirtualScrolling.value = value,
        ),
        _buildSliderTile(
          title: 'Cache Size',
          subtitle: '${controller.cacheSize.value} MB',
          value: controller.cacheSize.value.toDouble(),
          min: 10,
          max: 500,
          divisions: 49,
          onChanged: (value) => controller.cacheSize.value = value.toInt(),
        ),
        Row(
          children: [
            Expanded(
              child: AnymeXButton(
                text: 'Clear Cache',
                onPressed: () => _clearCache(context),
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
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required String title,
    String? subtitle,
    required EnhancedReadingMode value,
    required EnhancedReadingMode groupValue,
    required ValueChanged<EnhancedReadingMode> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Radio<EnhancedReadingMode>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildRadioTile({
    required String title,
    String? subtitle,
    required EnhancedScrollMode value,
    required EnhancedScrollMode groupValue,
    required ValueChanged<EnhancedScrollMode> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Radio<EnhancedScrollMode>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildThemeChip(String label, EnhancedThemeMode value) {
    return Obx(() => FilterChip(
      label: Text(label),
      selected: controller.themeMode.value == value,
      onSelected: () => controller.toggleThemeMode(value),
      backgroundColor: controller.themeMode.value == value
          ? Theme.of(Get.context!).primaryColor.withOpacity(0.2)
          : null,
    ));
  }

  Widget _buildColorPickerTile({
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: const CircleBorder(),
        ),
      ),
      onTap: onTap,
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
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Background Color'),
        content: _buildColorPickerGrid(context),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerGrid(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.grey[100],
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.brown,
      Colors.indigo,
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
      mainAxisExtent: 60,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      crossAxisExtent: 60,
    ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        return GestureDetector(
          onTap: () {
              controller.setCustomBackgroundColor(color.value.toHexColor());
              Get.back();
            },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: const BoxShape.circle,
              border: Border.all(
                color: controller.customBackgroundColor.value == color.value.toHexColor()
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  void _clearCache(BuildContext context) {
    AnymeXDialog.show(
      context,
      title: 'Clear Cache',
      content: 'Clear all cached content? This may slow down initial loading.',
      actions: [
        AnymeXButton(
          text: 'Cancel',
          variant: AnymeXButtonVariant.text,
          onPressed: () => Get.back(),
        ),
        AnymeXButton(
          text: 'Clear',
          onPressed: () {
            controller.clearCache();
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: 'Cache cleared'),
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
      content: 'Reset all enhanced reader settings to default values?',
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
      const SnackBar(content: 'Export functionality coming soon'),
    );
  }

  void _importBookmarks(BuildContext context) {
    // Implement bookmark import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Import functionality coming soon'),
    );
  }
}