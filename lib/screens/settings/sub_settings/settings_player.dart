import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/watch/controller/pip_service.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:outlined_text/outlined_text.dart';

class SettingsPlayer extends StatefulWidget {
  final bool isModal;
  const SettingsPlayer({super.key, this.isModal = false});

  @override
  State<SettingsPlayer> createState() => _SettingsPlayerState();
}

class _SettingsPlayerState extends State<SettingsPlayer> {
  final settings = Get.find<Settings>();
  RxDouble speed = 0.0.obs;
  final styles = ['Regular', 'Accent', 'Blurred Accent'];
  final selectedStyleIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    speed.value = settings.speed;
    selectedStyleIndex.value = settings.playerStyle;
  }

  String numToPlayerStyle(int i) => (i >= 0 && i < styles.length) ? styles[i] : 'Unknown';

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: getResponsiveValue(context, mobileValue: null, desktopValue: 500.0),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PlayBack Speeds', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: SuperListView.builder(
                    shrinkWrap: true,
                    itemCount: cursedSpeed.length,
                    itemBuilder: (context, index) {
                      double speedd = cursedSpeed[index];
                      return Obx(
                        () => Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          child: ListTileWithCheckMark(
                            leading: const Icon(Icons.speed),
                            color: Theme.of(context).colorScheme.primary,
                            active: speedd == speed.value,
                            title: '${speedd.toStringAsFixed(2)}x',
                            onTap: () {
                              speed.value = speedd;
                              settings.speed = speedd;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: widget.isModal
            ? Theme.of(context).colorScheme.surfaceContainer
            : Colors.transparent,
        body: SingleChildScrollView(
          padding: getResponsiveValue(
            context,
            mobileValue: const EdgeInsets.fromLTRB(10, 50, 10, 50),
            desktopValue: const EdgeInsets.fromLTRB(25, 50, 25, 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isModal)
                const Center(
                  child: Text("Player Settings",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("Player Settings",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),

              const SizedBox(height: 30),

              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexExpansionTile(
                      initialExpanded: true,
                      title: 'Common',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            icon: Icons.play_arrow_rounded,
                            padding: const EdgeInsets.all(10),
                            title: "Use Old Player",
                            description: "As many features are missing in the new player",
                            switchValue: settings.preferences
                                .get('useOldPlayer', defaultValue: false),
                            onChanged: (val) {
                              settings.preferences.put('useOldPlayer', val);
                              setState(() {});
                            },
                          ),
                          CustomTile(
                            padding: 10,
                            isDescBold: true,
                            icon: HugeIcons.strokeRoundedPlaySquare,
                            descColor: Theme.of(context).colorScheme.primary,
                            title: "Player Theme",
                            description: numToPlayerStyle(settings.playerStyle),
                            onTap: () => showSelectionDialog<int>(
                              title: "Player Theme",
                              items: [0, 1, 2],
                              selectedItem: selectedStyleIndex,
                              getTitle: (i) => numToPlayerStyle(i),
                              onItemSelected: (i) {
                                selectedStyleIndex.value = i;
                                settings.playerStyle = i;
                              },
                            ),
                          ),
                                              // ----------------------
                    // Picture-in-Picture
                    // ----------------------
                    AnymexExpansionTile(
                      title: 'Picture-in-Picture',
                      content: Column(
                        children: [
                          if (PipService.isPipAvailable)
                            CustomSwitchTile(
                              padding: const EdgeInsets.all(10),
                              icon: Icons.picture_in_picture_alt_rounded,
                              title: "Auto-enable on Home Button",
                              description:
                                  "Automatically enter PiP mode when pressing home button during playback",
                              switchValue: PipService.autoPipEnabled,
                              onChanged: (val) async {
                                await PipService.setAutoPipEnabled(val);
                                setState(() {});
                              },
                            )
                          else
                            CustomTile(
                              padding: 10,
                              icon: Icons.info_outline_rounded,
                              title: "PiP Not Supported",
                              description:
                                  "Your device or OS does not support Picture-in-Picture.",
                              descColor: Theme.of(context).colorScheme.primary,
                            ),

                          CustomTile(
                            padding: 10,
                            icon: Icons.smart_display_rounded,
                            title: 'Manual PiP',
                            description:
                                'You can always use the PiP button inside the player controls.',
                            isDescBold: false,
                            descColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    // ----------------------
                    // Subtitle Settings
                    // ----------------------
                    AnymexExpansionTile(
                      title: 'Subtitles',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.lightbulb,
                            title: 'Transition Subtitle',
                            description:
                                'Disable to avoid fade transitions between subtitles.',
                            switchValue: settings.transitionSubtitle,
                            onChanged: (v) => settings.transitionSubtitle = v,
                          ),

                          CustomTile(
                            padding: 10,
                            icon: Icons.palette,
                            title: 'Subtitle Color',
                            description: 'Change subtitle colors',
                            onTap: () {
                              _showColorSelectionDialog(
                                'Select Subtitle Color',
                                fontColorOptions[settings.subtitleColor]!,
                                (color) => settings.subtitleColor = color,
                              );
                            },
                          ),

                          CustomTile(
                            padding: 10,
                            icon: Icons.palette_outlined,
                            title: 'Subtitle Outline Color',
                            description: 'Change subtitle outline color',
                            onTap: () {
                              _showColorSelectionDialog(
                                'Select Subtitle Outline Color',
                                colorOptions[settings.subtitleOutlineColor]!,
                                (color) => settings.subtitleOutlineColor = color,
                              );
                            },
                          ),

                          CustomTile(
                            padding: 10,
                            icon: Icons.format_color_fill,
                            title: 'Subtitle Background Color',
                            description: 'Change subtitle background',
                            onTap: () {
                              _showColorSelectionDialog(
                                'Select Subtitle Background Color',
                                colorOptions[settings.subtitleBackgroundColor]!,
                                (color) => settings.subtitleBackgroundColor = color,
                              );
                            },
                          ),

                          CustomSliderTile(
                            sliderValue: settings.subtitleSize.toDouble(),
                            min: 12,
                            max: 90,
                            divisions: 18,
                            onChanged: (v) => settings.subtitleSize = v.toInt(),
                            title: 'Subtitle Size',
                            description: 'Adjust subtitle size',
                            icon: Iconsax.subtitle5,
                          ),

                          CustomSliderTile(
                            sliderValue: settings.subtitleOutlineWidth.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            onChanged: (v) =>
                                settings.subtitleOutlineWidth = v.toInt(),
                            title: 'Outline Width',
                            description: 'Adjust subtitle outline width',
                            icon: Iconsax.subtitle5,
                          ),

                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subtitle Preview',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        colorOptions[settings.subtitleBackgroundColor],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: OutlinedText(
                                    text: Text(
                                      'Subtitle Preview Text',
                                      style: TextStyle(
                                        color: colorOptions[settings.subtitleColor],
                                        fontSize:
                                            settings.subtitleSize.toDouble(),
                                      ),
                                    ),
                                    strokes: [
                                      OutlinedTextStroke(
                                        color: fontColorOptions[
                                            settings.subtitleOutlineColor]!,
                                        width: settings.subtitleOutlineWidth.toDouble(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


