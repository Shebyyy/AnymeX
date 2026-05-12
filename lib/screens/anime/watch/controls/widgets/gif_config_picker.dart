import 'package:anymex/utils/gif_recorder.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class GifConfig {
  final int durationSeconds;
  final GifQuality quality;

  const GifConfig({
    required this.durationSeconds,
    required this.quality,
  });
}

class GifConfigPickerDialog extends StatefulWidget {
  const GifConfigPickerDialog({super.key});

  @override
  State<GifConfigPickerDialog> createState() => _GifConfigPickerDialogState();
}

class _GifConfigPickerDialogState extends State<GifConfigPickerDialog>
    with SingleTickerProviderStateMixin {
  int _selectedDuration = 5;
  GifQuality _selectedQuality = GifQuality.medium;
  static const List<int> _presetDurations = [2, 3, 5, 7, 10, 15, 20, 30];

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? cs.surface : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outline.opaque(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.opaque(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Symbols.gif_rounded,
                      size: 32,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Record GIF',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose duration and quality',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.opaque(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel(theme, cs, 'Duration'),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.primary.opaque(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.primary.opaque(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_selectedDuration',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'sec',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.primary.opaque(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text('1s',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.opaque(0.4))),
                      Expanded(
                        child: Slider(
                          value: _selectedDuration.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          year2023: false,
                          activeColor: cs.primary,
                          onChanged: (val) {
                            setState(() {
                              _selectedDuration = val.round();
                            });
                          },
                        ),
                      ),
                      Text('30s',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.opaque(0.4))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _presetDurations.map((duration) {
                      final isSelected = duration == _selectedDuration;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedDuration = duration);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary
                                : cs.surfaceVariant.opaque(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: cs.outline.opaque(0.2), width: 0.5),
                          ),
                          child: Text(
                            '${duration}s',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? cs.onPrimary
                                  : cs.onSurface.opaque(0.7),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel(theme, cs, 'Quality'),
                  const SizedBox(height: 12),

                  Row(
                    children: GifQuality.values.map((q) {
                      final isSelected = q == _selectedQuality;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedQuality = q);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : cs.surfaceVariant.opaque(0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: cs.outline.opaque(0.2),
                                      width: 0.5),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  q == GifQuality.high
                                      ? Symbols.hd_rounded
                                      : q == GifQuality.medium
                                          ? Symbols.sd_rounded
                                          : Symbols.image_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? cs.onPrimary
                                      : cs.onSurface.opaque(0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  q.label,
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? cs.onPrimary
                                        : cs.onSurface.opaque(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  q.sizeLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? cs.onPrimary.opaque(0.7)
                                        : cs.onSurface.opaque(0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.tertiary.opaque(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: cs.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          '~${_estimateFileSize()} at 10fps, ${_selectedQuality.sizeLabel}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                                color: cs.outline.opaque(0.3), width: 1),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(
                            context,
                            GifConfig(
                              durationSeconds: _selectedDuration,
                              quality: _selectedQuality,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Symbols.fiber_manual_record_rounded,
                                  size: 18, color: cs.onPrimary),
                              const SizedBox(width: 6),
                              const Text('Record'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, ColorScheme cs, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.onSurface.opaque(0.5),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _estimateFileSize() {
    final kbPerFrame = switch (_selectedQuality) {
      GifQuality.low => 8,
      GifQuality.medium => 15,
      GifQuality.high => 25,
    };
    final frames = _selectedDuration * 10;
    final sizeKB = frames * kbPerFrame;
    if (sizeKB < 1024) return '${sizeKB}KB';
    return '${(sizeKB / 1024).toStringAsFixed(1)}MB';
  }
}

Future<GifConfig?> showGifConfigPicker(BuildContext context) {
  return showDialog<GifConfig>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const GifConfigPickerDialog(),
  );
}
