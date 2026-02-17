import 'package:anymex/models/custom_themes/theme_widgets/json_theme_config.dart';
import 'package:anymex/models/custom_themes/theme_widgets/json_widget_builder.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomReaderTheme implements ReaderControlTheme {
  final String id;
  final String name;
  final String author;
  final Map<String, dynamic> config;

  CustomReaderTheme({
    required this.id,
    required this.name,
    this.author = 'Unknown',
    required this.config,
  });

  factory CustomReaderTheme.fromJson(Map<String, dynamic> json) {
    return CustomReaderTheme(
      id: json['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Custom Theme',
      author: json['author'] ?? 'Unknown',
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'reader',
      'id': id,
      'name': name,
      'author': author,
      'version': '2.0',
      'config': config,
    };
  }

  @override
  String get name => this.name;

  @override
  String get id => this.id;

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    final topControlsConfig = config['top_controls'] as Map<String, dynamic>?;
    
    if (topControlsConfig != null && topControlsConfig.containsKey('components')) {
      return _buildRichTopControls(context, controller, topControlsConfig);
    } else {
      return _buildSimpleTopControls(context, controller, topControlsConfig ?? {});
    }
  }

  Widget _buildRichTopControls(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> config,
  ) {
    final decoration = JsonThemeDecoration.fromJson(config['decoration'] as Map?);
    final layout = JsonThemeLayout.fromJson(config['layout'] as Map?);
    final childrenJson = config['components'] as List?;

    final contextData = {
      'manga': controller.manga?.title ?? 'Unknown',
      'title': controller.manga?.title ?? 'Unknown',
      'chapter': 'Chapter ${controller.currentChapter.value}',
      'controller': controller,
    };

    List<Widget> children = [];
    if (childrenJson != null) {
      children = JsonWidgetBuilder.buildComponents(childrenJson, contextData);
    }

    Widget child;
    if (layout.type == 'column') {
      child = Column(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    } else {
      child = Row(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    }

    if (decoration.blur?.enabled == true) {
      child = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: child,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: decoration.build(),
        padding: (layout.padding?.padding) as EdgeInsets?,
        child: child,
      ),
    );
  }

  Widget _buildSimpleTopControls(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> config,
  ) {
    final colors = Theme.of(context).colorScheme;
    final showBackground = config['show_background'] ?? true;
    final backgroundColor = _parseColor(config['background_color'], Colors.black54);
    final showTitle = config['show_title'] ?? true;
    final showChapter = config['show_chapter'] ?? true;
    final padding = EdgeInsets.symmetric(
      horizontal: (config['horizontal_padding'] as num?)?.toDouble() ?? 16.0,
      vertical: (config['vertical_padding'] as num?)?.toDouble() ?? 12.0,
    );

    return Container(
      color: showBackground ? backgroundColor : Colors.transparent,
      padding: padding,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildBackButton(context, config),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTitle)
                    Text(
                      controller.manga?.title ?? 'Unknown',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: (config['title_size'] as num?)?.toDouble() ?? 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (showChapter && showTitle) const SizedBox(height: 4),
                  if (showChapter)
                    Obx(() => Text(
                          'Chapter ${controller.currentChapter.value}',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.7),
                            fontSize: (config['subtitle_size'] as num?)?.toDouble() ?? 14.0,
                          ),
                        )),
                ],
              ),
            ),
            _buildTopActions(context, controller, config),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBottomControls(BuildContext context, ReaderController controller) {
    final bottomControlsConfig = config['bottom_controls'] as Map<String, dynamic>?;
    
    if (bottomControlsConfig != null && bottomControlsConfig.containsKey('components')) {
      return _buildRichBottomControls(context, controller, bottomControlsConfig);
    } else {
      return _buildSimpleBottomControls(context, controller, bottomControlsConfig ?? {});
    }
  }

  Widget _buildRichBottomControls(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> config,
  ) {
    final decoration = JsonThemeDecoration.fromJson(config['decoration'] as Map?);
    final layout = JsonThemeLayout.fromJson(config['layout'] as Map?);
    final childrenJson = config['components'] as List?;

    final contextData = {
      'controller': controller,
      'current_page': controller.currentPage.value,
      'total_pages': controller.totalPages.value,
      'progress': controller.totalPages.value > 0 
          ? controller.currentPage.value / controller.totalPages.value 
          : 0.0,
    };

    List<Widget> children = [];
    if (childrenJson != null) {
      children = JsonWidgetBuilder.buildComponents(childrenJson, contextData);
    }

    Widget child;
    if (layout.type == 'column') {
      child = Column(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    } else {
      child = Row(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    }

    if (decoration.blur?.enabled == true) {
      child = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: child,
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: decoration.build(),
        padding: (layout.padding?.padding) as EdgeInsets?,
        child: child,
      ),
    );
  }

  Widget _buildSimpleBottomControls(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> config,
  ) {
    final colors = Theme.of(context).colorScheme;
    final showBackground = config['show_background'] ?? true;
    final backgroundColor = _parseColor(config['background_color'], Colors.black54);
    final showNavigation = config['show_navigation'] ?? true;
    final showSettings = config['show_settings'] ?? true;
    final showProgress = config['show_progress'] ?? true;
    final padding = EdgeInsets.symmetric(
      horizontal: (config['horizontal_padding'] as num?)?.toDouble() ?? 16.0,
      vertical: (config['vertical_padding'] as num?)?.toDouble() ?? 12.0,
    );

    return Container(
      color: showBackground ? backgroundColor : Colors.transparent,
      padding: padding,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) _buildProgressBar(context, controller, config),
            if (showProgress && (showNavigation || showSettings)) const SizedBox(height: 12),
            Row(
              children: [
                if (showNavigation) _buildNavigationControls(context, controller, config),
                if (showNavigation && showSettings) const Spacer(),
                if (showSettings) _buildSettingsButton(context, controller, config),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, Map<String, dynamic> themeConfig) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 24.0;

    return IconButton(
      icon: Icon(Icons.arrow_back_rounded),
      color: iconColor,
      iconSize: iconSize,
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildTopActions(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 24.0;
    final showMore = themeConfig['show_more_button'] ?? true;

    return Row(
      children: [
        if (showMore)
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            color: iconColor,
            iconSize: iconSize,
            onPressed: () => controller.openSettings(),
          ),
      ],
    );
  }

  Widget _buildNavigationControls(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 28.0;
    final showTextLabels = themeConfig['show_text_labels'] ?? false;

    return Row(
      children: [
        _buildNavButton(
          context,
          Icons.first_page_rounded,
          'First',
          () => controller.jumpToFirst(),
          iconSize,
          iconColor,
          showTextLabels,
        ),
        const SizedBox(width: 8),
        _buildNavButton(
          context,
          Icons.chevron_left_rounded,
          'Prev',
          () => controller.prevPage(),
          iconSize,
          iconColor,
          showTextLabels,
        ),
        const SizedBox(width: 16),
        Obx(() => Text(
              '${controller.currentPage.value}/${controller.totalPages.value}',
              style: TextStyle(
                color: iconColor,
                fontSize: (themeConfig['page_text_size'] as num?)?.toDouble() ?? 16.0,
                fontWeight: FontWeight.bold,
              ),
            )),
        const SizedBox(width: 16),
        _buildNavButton(
          context,
          Icons.chevron_right_rounded,
          'Next',
          () => controller.nextPage(),
          iconSize,
          iconColor,
          showTextLabels,
        ),
        const SizedBox(width: 8),
        _buildNavButton(
          context,
          Icons.last_page_rounded,
          'Last',
          () => controller.jumpToLast(),
          iconSize,
          iconColor,
          showTextLabels,
        ),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    double size,
    Color color,
    bool showLabel,
  ) {
    return showLabel
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(icon),
                color: color,
                iconSize: size,
                onPressed: onTap,
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          )
        : IconButton(
            icon: Icon(icon),
            color: color,
            iconSize: size,
            onPressed: onTap,
          );
  }

  Widget _buildSettingsButton(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 24.0;

    return IconButton(
      icon: Icon(Icons.settings_rounded),
      color: iconColor,
      iconSize: iconSize,
      onPressed: () => controller.openSettings(),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ReaderController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final progressColor = _parseColor(themeConfig['progress_color'], Colors.blue);
    final trackColor = _parseColor(themeConfig['track_color'], Colors.white24);
    final height = (themeConfig['progress_height'] as num?)?.toDouble() ?? 4.0;

    return Obx(() {
      final current = controller.currentPage.value;
      final total = controller.totalPages.value;
      final progress = total > 0 ? current / total : 0.0;

      return SliderTheme(
        data: SliderThemeData(
          trackHeight: height,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          activeTrackColor: progressColor,
          inactiveTrackColor: trackColor,
          thumbColor: progressColor,
          overlayColor: progressColor.withOpacity(0.3),
        ),
        child: Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: (value) {
            final page = (value * total).round().clamp(1, total);
            controller.jumpToPage(page);
          },
        ),
      );
    });
  }

  Color? _parseColor(dynamic colorValue, Color defaultColor) {
    if (colorValue == null) return defaultColor;
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      if (colorValue.startsWith('0x')) {
        return Color(int.parse(colorValue));
      }
      return Color(int.parse(colorValue));
    }
    return defaultColor;
  }
}
