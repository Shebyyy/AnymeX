import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/player/media_kit_player.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/anime/watch/pip/pip_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FloatingPlayerManager extends GetxController {
  static FloatingPlayerManager get to => Get.find<FloatingPlayerManager>();

  final isFloating = false.obs;
  PlayerController? _playerController;
  PlayerController? get playerController => _playerController;

  @override
  void onInit() {
    super.onInit();
    PipService().onPipStateChanged = _onPipStateChanged;
  }

  void _onPipStateChanged(bool isPipActive) {
    if (!isPipActive && isFloating.value && settingsController.returnToFullscreenAfterPip) {
      expandToFullScreen();
    }
  }

  void startFloating(PlayerController controller) {
    if (isFloating.value) return;
    _playerController = controller;
    isFloating.value = true;

    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void stopFloating() {
    if (!isFloating.value) return;
    isFloating.value = false;

    final controller = _playerController;
    _playerController = null;

    if (controller != null) {
      controller.delete();
    }

    Get.delete<PlayerController>(force: true);
    PipService().dispose();
  }

  void expandToFullScreen() {
    if (!isFloating.value || _playerController == null) return;

    final controller = _playerController!;
    _playerController = null;
    isFloating.value = false;

    Get.to(
      () => WatchScreen(
        episodeSrc: controller.selectedVideo.value ?? controller.episodeTracks.first,
        currentEpisode: controller.currentEpisode.value,
        episodeList: controller.episodeList,
        anilistData: controller.anilistData,
        episodeTracks: controller.episodeTracks,
        shouldTrack: controller.shouldTrack,
        existingController: controller,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void onClose() {
    stopFloating();
    super.onClose();
  }
}

class FloatingPlayerOverlay extends StatefulWidget {
  const FloatingPlayerOverlay({super.key});

  @override
  State<FloatingPlayerOverlay> createState() => _FloatingPlayerOverlayState();
}

class _FloatingPlayerOverlayState extends State<FloatingPlayerOverlay> {
  Offset _position = Offset.zero;
  bool _isDragging = false;

  static const Map<String, Size> _sizeMap = {
    'small': Size(160, 90),
    'medium': Size(200, 113),
    'large': Size(280, 158),
  };

  Size get _currentSize {
    final sizeKey = settingsController.floatingPlayerSize;
    return _sizeMap[sizeKey] ?? _sizeMap['medium']!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPosition();
    });
  }

  void _initPosition() {
    final screenSize = MediaQuery.of(context).size;
    final size = _currentSize;

    if (settingsController.rememberFloatingPosition) {
      final savedX = PlayerSettingsKeys.floatingPlayerPositionX.get<double?>(null);
      final savedY = PlayerSettingsKeys.floatingPlayerPositionY.get<double?>(null);
      if (savedX != null && savedY != null) {
        final clampedX = savedX.clamp(0.0, screenSize.width - size.width);
        final clampedY = savedY.clamp(
          MediaQuery.of(context).padding.top,
          screenSize.height - size.height - MediaQuery.of(context).padding.bottom - 60,
        );
        setState(() {
          _position = Offset(clampedX, clampedY);
        });
        return;
      }
    }

    setState(() {
      _position = Offset(
        screenSize.width - size.width - 12,
        screenSize.height * 0.3,
      );
    });
  }

  void _savePosition() {
    if (!settingsController.rememberFloatingPosition) return;
    PlayerSettingsKeys.floatingPlayerPositionX.set(_position.dx);
    PlayerSettingsKeys.floatingPlayerPositionY.set(_position.dy);
  }

  void _snapToNearestCorner() {
    final screenSize = MediaQuery.of(context).size;
    final size = _currentSize;
    final centerX = _position.dx + size.width / 2;
    final isLeft = centerX < screenSize.width / 2;

    setState(() {
      _position = Offset(
        isLeft ? 8 : screenSize.width - size.width - 8,
        _position.dy.clamp(
          MediaQuery.of(context).padding.top + 8,
          screenSize.height - size.height - MediaQuery.of(context).padding.bottom - 60,
        ),
      );
    });
    _savePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final manager = FloatingPlayerManager.to;
      if (!manager.isFloating.value || manager.playerController == null) {
        return const SizedBox.shrink();
      }

      final controller = manager.playerController!;
      final size = _currentSize;

      return Stack(
        children: [
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onPanStart: (_) => _isDragging = true,
              onPanUpdate: (details) {
                setState(() {
                  final screenSize = MediaQuery.of(context).size;
                  _position = Offset(
                    (_position.dx + details.delta.dx)
                        .clamp(0, screenSize.width - size.width),
                    (_position.dy + details.delta.dy).clamp(
                      MediaQuery.of(context).padding.top,
                      screenSize.height - size.height - MediaQuery.of(context).padding.bottom - 60,
                    ),
                  );
                });
              },
              onPanEnd: (_) {
                _isDragging = false;
                _snapToNearestCorner();
              },
              child: AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildVideo(controller),
                    _buildSubtitles(controller),
                    _buildControls(controller, manager),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVideo(PlayerController controller) {
    try {
      if (controller.basePlayer is MediaKitPlayer) {
        final nativeController =
            (controller.basePlayer as MediaKitPlayer).nativeVideoController;
        return Video(
          controller: nativeController,
          controls: null,
          fit: BoxFit.cover,
        );
      }
    } catch (_) {}
    return Container(color: Colors.black);
  }

  Widget _buildSubtitles(PlayerController controller) {
    return Obx(() {
      final useLibass = PlayerKeys.useLibass.get<bool>(false);
      if (useLibass) return const SizedBox.shrink();

      final subtitleLines = controller.subtitleText;
      final translated = controller.translatedSubtitle.value;

      if (subtitleLines.isEmpty && translated.isEmpty) {
        return const SizedBox.shrink();
      }

      final displayLines = translated.isNotEmpty
          ? translated.split('\n')
          : subtitleLines;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            displayLines.join('\n'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });
  }

  Widget _buildControls(PlayerController controller, FloatingPlayerManager manager) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: GestureDetector(
                  onTap: () => manager.expandToFullScreen(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: GestureDetector(
                  onTap: () => manager.stopFloating(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => controller.seekTo(controller.currentPosition.value - const Duration(seconds: 10)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.replay_10_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => controller.togglePlayPause(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Obx(() => Icon(
                      controller.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => controller.seekTo(controller.currentPosition.value + const Duration(seconds: 10)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.forward_10_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
