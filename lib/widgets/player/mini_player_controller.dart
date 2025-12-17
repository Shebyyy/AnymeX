import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as model;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

class MiniPlayerController extends GetxController {
  static MiniPlayerController get to => Get.find();
  
  final RxBool isVisible = false.obs;
  final RxBool isExpanded = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxString currentTime = '0:00'.obs;
  final RxString totalTime = '0:00'.obs;
  final RxBool isPlaying = false.obs;
  
  // Player data
  final Rx<anymex.Media?> currentMedia = Rx<anymex.Media?>(null);
  final Rx<Episode?> currentEpisode = Rx<Episode?>(null);
  final Rx<model.Video?> currentVideo = Rx<model.Video?>(null);
  final RxList<Episode> episodeList = RxList<Episode>();
  
  // Player reference
  Player? player;
  PlayerController? mainPlayerController;
  
  void showMiniPlayer({
    required anymex.Media media,
    required Episode episode,
    required model.Video video,
    required List<Episode> episodes,
    required PlayerController playerController,
  }) {
    currentMedia.value = media;
    currentEpisode.value = episode;
    currentVideo.value = video;
    episodeList.value = episodes;
    mainPlayerController = playerController;
    player = playerController.player;
    
    isVisible.value = true;
    _setupPlayerListeners();
  }
  
  void hideMiniPlayer() {
    isVisible.value = false;
    isExpanded.value = false;
    player = null;
    mainPlayerController = null;
  }
  
  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }
  
  void togglePlayPause() {
    if (player != null) {
      if (isPlaying.value) {
        player!.pause();
      } else {
        player!.play();
      }
    }
  }
  
  void seekForward() {
    if (player != null) {
      final newPosition = player!.state.position + const Duration(seconds: 10);
      player!.seek(newPosition);
    }
  }
  
  void seekBackward() {
    if (player != null) {
      final newPosition = player!.state.position - const Duration(seconds: 10);
      if (newPosition.inSeconds < 0) {
        player!.seek(Duration.zero);
      } else {
        player!.seek(newPosition);
      }
    }
  }
  
  void _setupPlayerListeners() {
    if (player == null) return;
    
    // Listen to position changes
    player!.stream.position.listen((position) {
      if (player!.state.duration.inMilliseconds > 0) {
        progress.value = position.inMilliseconds / player!.state.duration.inMilliseconds;
      }
      currentTime.value = _formatDuration(position);
    });
    
    // Listen to duration changes
    player!.stream.duration.listen((duration) {
      totalTime.value = _formatDuration(duration);
    });
    
    // Listen to playing state
    player!.stream.playing.listen((playing) {
      isPlaying.value = playing;
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  void returnToMainPlayer() {
    if (mainPlayerController != null) {
      // Navigate back to the main player
      Get.back();
    }
  }
  
  void playNextEpisode() {
    if (mainPlayerController != null && mainPlayerController!.hasNextEpisode) {
      final nextEp = mainPlayerController!.nextEpisode;
      if (nextEp != null) {
        currentEpisode.value = nextEp;
        mainPlayerController!.changeEpisode(nextEp);
      }
    }
  }
  
  void playPreviousEpisode() {
    if (mainPlayerController != null && mainPlayerController!.hasPreviousEpisode) {
      final prevEp = mainPlayerController!.previousEpisode;
      if (prevEp != null) {
        currentEpisode.value = prevEp;
        mainPlayerController!.changeEpisode(prevEp);
      }
    }
  }
}
