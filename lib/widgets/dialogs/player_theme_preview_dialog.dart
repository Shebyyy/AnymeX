/// Player Theme Preview Dialog
/// Provides a live preview of player control themes with interactive selection
/// Similar to logo animation preview dialog

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as model;
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayerThemePreviewDialog extends StatefulWidget {
  final String initialThemeId;
  final Function(String) onConfirm;

  const PlayerThemePreviewDialog({
    Key? key,
    required this.initialThemeId,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PlayerThemePreviewDialog> createState() => _PlayerThemePreviewDialogState();
}

class _PlayerThemePreviewDialogState extends State<PlayerThemePreviewDialog> {
  late String _selectedThemeId;
  late PlayerControlTheme _selectedTheme;
  Key _previewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.initialThemeId;
    _selectedTheme = PlayerControlThemeRegistry.resolve(_selectedThemeId);
  }

  void _replayPreview() {
    setState(() {
      _previewKey = UniqueKey();
    });
  }

  void _selectTheme(String themeId) {
    setState(() {
      _selectedThemeId = themeId;
      _selectedTheme = PlayerControlThemeRegistry.resolve(themeId);
      _previewKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;

    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 900 : 700,
          maxHeight: screenHeight * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Player Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: context.colors.surfaceContainer,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(_selectedThemeId);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: context.colors.primaryFixed,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "LexendDeca",
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Section (Fixed height, not scrollable)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildPreviewContainer(),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Replay Preview'),
                onPressed: _replayPreview,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Theme List (Scrollable)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildThemeList(),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Preview
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildPreviewContainer(),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay Preview'),
                  onPressed: _replayPreview,
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right side - List
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildThemeList(),
                ),
              ],
            ),
          ],
        ],
      );
  }

  Widget _buildPreviewContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient simulating video
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F0F23),
                ],
              ),
            ),
          ),

          // Mock video content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample Video',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Theme controls overlay
          Positioned.fill(
            child: _ThemePreviewWidget(
              key: _previewKey,
              theme: _selectedTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList() {
    return ListView.builder(
      itemCount: PlayerControlThemeRegistry.themes.length,
      itemBuilder: (context, index) {
        final theme = PlayerControlThemeRegistry.themes[index];
        final isSelected = _selectedThemeId == theme.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? context.colors.primaryContainer
                : context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectTheme(theme.id),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? context.colors.onPrimaryContainer
                                  : context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getThemeDescription(theme.id),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? context.colors.onPrimaryContainer.withOpacity(0.7)
                                  : context.colors.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getThemeDescription(String themeId) {
    switch (themeId) {
      case 'default':
        return 'Default AnymeX player with clean controls and modern design';
      case 'ios26':
        return 'iOS 26 style with smooth animations and glass-morphism effects';
      case 'netflix_desktop':
        return 'Netflix desktop layout with clean interface and spacious controls';
      case 'netflix_mobile':
        return 'Netflix mobile style with vertical scrim overlay and smooth transitions';
      case 'prime_video':
        return 'Amazon Prime Video inspired controls with distinctive styling';
      case 'youtube':
        return 'YouTube-inspired design with signature red accent colors and familiar layout';
      case 'minimal':
        return 'Minimal design with subtle text shadows and unobtrusive controls';
      case 'cyberpunk':
        return 'Futuristic cyberpunk theme with neon cyan/magenta colors and glowing effects';
      case 'floating_orbs':
        return 'Unique floating orb button design with circular animated controls';
      case 'retro_vhs':
        return 'Retro 80s VHS aesthetic with amber/green colors and nostalgic feel';
      default:
        return 'Custom player theme with unique design';
    }
  }
}

/// Widget that renders a theme preview in the dialog
class _ThemePreviewWidget extends StatelessWidget {
  final PlayerControlTheme theme;

  const _ThemePreviewWidget({
    Key? key,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top controls placeholder
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sample Episode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Episode 1',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Center controls placeholder
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fast_rewind,
                  size: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fast_forward,
                  size: 24,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Bottom controls placeholder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '1:23',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
