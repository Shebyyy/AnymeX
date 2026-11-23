import 'dart:io';

import 'package:anymex/addons/addons_hub.dart';
import 'package:anymex/addons/clip/clip_addon.dart';
import 'package:anymex/addons/clip/clip_models.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

String _mmss(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// True when the add-on has what it needs on this device.
Future<bool> clipAvailable() async => AddonsHub.clip.isInstalled();

/// Bottom sheet of the player's Clip button.
Future<void> showClipSheet(
  BuildContext context,
  PlayerController controller,
) async {
  final clip = AddonsHub.clip;
  if (!await clip.isInstalled()) {
    errorSnackBar('Install the Clip Recorder add-on in Settings > Add-ons');
    return;
  }
  if (!context.mounted) return;

  Duration? markIn;
  Duration? markOut;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> run(Duration start, Duration end) async {
            final total = controller.episodeDuration.value;
            if (total > Duration.zero && end > total) end = total;
            if (start < Duration.zero) start = Duration.zero;
            if (end <= start) {
              errorSnackBar('Choose a range longer than zero seconds');
              return;
            }
            final video = controller.selectedVideo.value;
            final ClipRequest request;
            try {
              // What the player really opened (for torrents this is the
              // TorrServer stream URL, not the extension's magnet link).
              request = ClipRequest.fromPlayerSource(
                source: controller.playingUrl ?? video?.url,
                headers: controller.playingHeaders ?? video?.headers,
                start: start,
                end: end,
                title: controller.anilistData.title,
                episode: controller.currentEpisode.value.number.toString(),
              );
            } catch (e) {
              errorSnackBar(e.toString());
              return;
            }
            try {
              final result = await clip.createClip(request);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              _showResult(result, request);
            } on ClipCancelled {
              // user cancelled; nothing to report
            } catch (e) {
              errorSnackBar(e.toString());
            }
          }

          Widget chip(String label, Duration start, Duration end) => ActionChip(
            label: Text(label),
            onPressed: clip.activeClip.value ? null : () => run(start, end),
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Obx(() {
                final pos = controller.currentPosition.value;
                final busy = clip.activeClip.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clip', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Now at ${_mmss(pos)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Text('Last seconds'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final n in const [15, 30, 60])
                          chip('Last ${n}s', pos - Duration(seconds: n), pos),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Next seconds'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final n in const [15, 30, 60])
                          chip('Next ${n}s', pos, pos + Duration(seconds: n)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Custom range'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => setState(() => markIn = pos),
                          child: Text(
                            markIn == null
                                ? 'Set start here'
                                : 'Start ${_mmss(markIn!)}',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => setState(() => markOut = pos),
                          child: Text(
                            markOut == null
                                ? 'Set end here'
                                : 'End ${_mmss(markOut!)}',
                          ),
                        ),
                        FilledButton(
                          onPressed: busy || markIn == null || markOut == null
                              ? null
                              : () => run(markIn!, markOut!),
                          child: const Text('Create clip'),
                        ),
                      ],
                    ),
                    if (busy) ...[
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: clip.clipProgress.value > 0
                            ? clip.clipProgress.value
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Text('Creating clip...')),
                          TextButton(
                            onPressed: clip.cancel,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      Platform.isIOS
                          ? 'On iOS clips work for HLS streams only and start at a segment boundary, so they can begin a few seconds early.'
                          : 'Clips start at the nearest keyframe, so they can begin a few seconds early.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          );
        },
      );
    },
  );
}

void _showResult(ClipResult result, ClipRequest request) {
  final seconds = (request.start - result.actualStart).inSeconds.abs();
  final note = seconds >= 2
      ? '\nIt starts about ${seconds}s before the chosen time (keyframe).'
      : '';
  Get.dialog(
    AlertDialog(
      title: const Text('Clip saved'),
      content: Text('${result.path}$note'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Close')),
        if (Platform.isAndroid || Platform.isIOS)
          FilledButton(
            onPressed: () {
              Get.back();
              SharePlus.instance.share(
                ShareParams(files: [XFile(result.path)]),
              );
            },
            child: const Text('Share'),
          ),
      ],
    ),
  );
}
