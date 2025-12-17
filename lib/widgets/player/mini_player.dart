import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as model;
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/player/mini_player_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MiniPlayerController());
    
    return Obx(() {
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 16,
        right: 16,
        bottom: controller.isExpanded.value ? 100 : 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: controller.isExpanded.value ? 200 : 70,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.toggleExpanded,
                child: Column(
                  children: [
                    // Main mini player content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: controller.currentMedia.value?.coverImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: controller.currentMedia.value!.coverImage!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.movie),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Media info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnymexText(
                                    controller.currentMedia.value?.title?.english ?? 
                                    controller.currentMedia.value?.title?.romaji ?? 
                                    'Unknown Title',
                                    variant: TextVariant.bold,
                                    fontSize: 14,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  AnymexText(
                                    'Episode ${controller.currentEpisode.value?.number ?? '1'}',
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 4),
                                  // Progress bar
                                  LinearProgressIndicator(
                                    value: controller.progress.value,
                                    backgroundColor: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Control buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Previous button
                                AnymexButton(
                                  onTap: controller.playPreviousEpisode,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.skip_previous,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                
                                // Play/Pause button
                                AnymexButton(
                                  onTap: controller.togglePlayPause,
                                  padding: const EdgeInsets.all(8),
                                  color: Theme.of(context).colorScheme.primary,
                                  child: Icon(
                                    controller.isPlaying.value 
                                        ? Icons.pause 
                                        : Icons.play_arrow,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                
                                // Next button
                                AnymexButton(
                                  onTap: controller.playNextEpisode,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.skip_next,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                
                                // Close button
                                AnymexButton(
                                  onTap: controller.hideMiniPlayer,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded controls (visible when expanded)
                    if (controller.isExpanded.value)
                      Container(
                        height: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Time display and progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AnymexText(
                                  controller.currentTime.value,
                                  fontSize: 12,
                                ),
                                AnymexText(
                                  controller.totalTime.value,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Progress slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(
                                value: controller.progress.value.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  // Handle seek
                                  if (controller.player != null) {
                                    final newPosition = Duration(
                                      milliseconds: (value * controller.player!.state.duration.inMilliseconds).round(),
                                    );
                                    controller.player!.seek(newPosition);
                                  }
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                                inactiveColor: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.2),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Seek backward
                                AnymexButton(
                                  onTap: controller.seekBackward,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.replay_10,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                
                                // Seek forward
                                AnymexButton(
                                  onTap: controller.seekForward,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.forward_10,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                
                                // Return to main player
                                AnymexButton(
                                  onTap: controller.returnToMainPlayer,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  color: Theme.of(context).colorScheme.primary,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fullscreen,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      AnymexText(
                                        'Full Player',
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
