import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../json_reader_controls_config.dart';
import '../../json_theme_config.dart';
import '../../json_theme_elements.dart';

/// Builder for JSON reader themes
class JsonReaderThemeBuilder {
  static Widget buildTopControls({
    required BuildContext context,
    required ReaderController controller,
    required JsonReaderTopControlsConfig config,
  }) {
    final background = config.background;
    final layout = config.layout;

    List<Widget> children = config.elements.map((element) => _buildElement(context, controller, element)).toList();

    Widget child = Row(
      children: children,
    );

    if (background != null && background.color != null) {
      child = _applyBackground(context, child, background, layout);
    }

    if (layout != null) {
      child = Padding(
        padding: layout.padding,
        child: child,
      );
    }

    return SafeArea(
      bottom: false,
      child: child,
    );
  }

  static Widget buildBottomControls({
    required BuildContext context,
    required ReaderController controller,
    required JsonReaderBottomControlsConfig config,
  }) {
    final background = config.background;
    final layout = config.layout;
    final progressBar = config.progressBar;
    final navigation = config.navigation;

    List<Widget> children = [];

    // Progress bar
    if (progressBar != null && navigation?.showPageSlider == true) {
      children.add(_buildProgressBar(context, controller, progressBar));
      children.add(const SizedBox(height: 8));
    }

    // Navigation
    if (navigation != null) {
      children.add(_buildNavigation(context, controller, navigation));
    }

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (background != null && background.color != null) {
      child = _applyBackground(context, child, background, layout);
    }

    if (layout != null) {
      child = Padding(
        padding: layout?.padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    return SafeArea(
      top: false,
      child: child,
    );
  }

  static Widget _buildElement(
    BuildContext context,
    ReaderController controller,
    JsonThemeElement element,
  ) {
    final color = element.parsedColor;

    switch (element.type) {
      case 'back_button':
        return _buildBackButton(context, element, controller);

      case 'title':
        return _buildTitle(context, controller, element);

      default:
        return const SizedBox.shrink();
    }
  }

  static Widget _buildBackButton(
    BuildContext context,
    JsonThemeElement element,
    ReaderController controller,
  ) {
    return IconButton(
      icon: Icons.arrow_back_rounded,
      color: element.parsedColor ?? Colors.white,
      iconSize: element.size ?? 24,
      onPressed: () => Get.back(),
    );
  }

  static Widget _buildTitle(
    BuildContext context,
    ReaderController controller,
    JsonThemeElement element,
  ) {
    return Expanded(
      child: Text(
        controller.media.title ?? 'Unknown',
        style: TextStyle(
          color: element.parsedColor ?? Colors.white,
          fontSize: element.fontSize ?? 14,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  static Widget _buildProgressBar(
    BuildContext context,
    ReaderController controller,
    JsonProgressBarConfig progressBar,
  ) {
    return Obx(() {
      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return SliderTheme(
        data: SliderThemeData(
          trackHeight: progressBar.height ?? 4,
          thumbShape: SliderComponentShape.noThumb,
          trackShape: const IOSSliderTrackShape(),
          activeTrackColor: progressBar.parsedColor ?? Colors.white,
          inactiveTrackColor: progressBar.parsedTrackColor ?? Colors.white.withOpacity(0.2),
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: value,
          min: 1,
          max: pageCount,
          onChanged: (v) {
            final idx = v.toInt();
            controller.currentPageIndex.value = idx;
            controller.navigateToPage(idx - 1);
          },
        ),
      );
    });
  }

  static Widget _buildNavigation(
    BuildContext context,
    ReaderController controller,
    JsonNavigationConfig navigation,
  ) {
    final iconColor = navigation.parsedIconColor ?? Colors.white;
    final iconSize = navigation.iconSize ?? 24;

    return Row(
      children: [
        _buildNavButton(
          Icons.chevron_left,
          controller.canGoPrev,
          () => controller.navigateBackward(),
          iconSize,
          iconColor,
        ),
        const SizedBox(width: 8),
        Obx(() => Text(
          '\${controller.currentPageIndex.value}/\${controller.pageList.length}',
          style: TextStyle(
            color: iconColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        )),
        const SizedBox(width: 8),
        _buildNavButton(
          Icons.chevron_right,
          controller.canGoNext,
          () => controller.navigateForward(),
          iconSize,
          iconColor,
        ),
      ],
    );
  }

  static Widget _buildNavButton(
    IconData icon,
    RxBool canNav,
    VoidCallback onTap,
    double size,
    Color color,
  ) {
    return Obx(() {
      return AnimatedOpacity(
        opacity: canNav.value ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 180),
        child: _buildIconButton(
          icon,
          onTap: canNav.value ? onTap : null,
          size,
          color,
        ),
      );
    });
  }

  static Widget _buildIconButton(
    IconData icon,
    VoidCallback? onTap,
    double size,
    Color color,
  ) {
    return IconButton(
      icon: icon,
      onPressed: onTap,
      color: color,
      iconSize: size,
    );
  }

  static Widget _applyBackground(
    BuildContext context,
    Widget child,
    JsonBackgroundConfig background,
    JsonLayoutConfig? layout,
  ) {
    Widget result = Container(
      decoration: background.buildDecoration(context),
      child: child,
    );

    if (background.blur != null && background.blur! > 0) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(layout?.cornerRadius ?? 0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: background.blur!, sigmaY: background.blur!),
          child: result,
        ),
      );
    }

    return result;
  }
}
