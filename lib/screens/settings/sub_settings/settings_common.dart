// lib/widgets/non_widgets/settings_common.dart

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/general.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class SettingsCommon extends StatefulWidget {
  const SettingsCommon({super.key});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  final settings = Get.find<Settings>();
  late bool uniScrapper;
  late bool shouldAskForPermission = General.shouldAskForTrack.get(true);

  @override
  void initState() {
    super.initState();
    uniScrapper = settingsController.preferences
        .get('universal_scrapper', defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: getResponsiveValue(context,
                mobileValue: const EdgeInsets.fromLTRB(10, 50, 10, 20),
                desktopValue: const EdgeInsets.fromLTRB(25, 50, 25, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withOpacity(0.5),
                      ),
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Text("Common ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 30),

                // ---------------- Universal Section ----------------
                AnymexExpansionTile(
                    initialExpanded: true,
                    title: 'Universal',
                    content: Column(
                      children: [
                        CustomSwitchTile(
                          icon: Icons.touch_app_rounded,
                          title: 'Ask for tracking permission',
                          description:
                              'If enabled, Anymex will ask for tracking permission.',
                          switchValue: shouldAskForPermission,
                          onChanged: (e) {
                            setState(() {
                              shouldAskForPermission = e;
                              General.shouldAskForTrack.set(e);
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        /// NEW — Default Start Page
                        _buildDefaultStartPageDropdown(context),
                      ],
                    )),

                // ---------------- Anilist Section ----------------
                AnymexExpansionTile(
                    initialExpanded: true,
                    title: 'Anilist',
                    content: CustomTile(
                      icon: Icons.format_list_bulleted_sharp,
                      title: 'Manage Anilist Lists',
                      description: "Choose which list to show on home page",
                      onTap: () => _showHomePageCardsDialog(context, false),
                    )),

                // ---------------- MyAnimeList Section ----------------
                AnymexExpansionTile(
                    initialExpanded: true,
                    title: 'MyAnimeList',
                    content: CustomTile(
                      icon: Icons.format_list_bulleted_sharp,
                      title: 'Manage MyAnimeList Lists',
                      description: "Choose which list to show on home page",
                      onTap: () => _showHomePageCardsDialog(context, true),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------- DEFAULT START PAGE DROPDOWN ----------
  Widget _buildDefaultStartPageDropdown(BuildContext context) {
    return Obx(() {
      final value = settings.defaultStartTab.value;

      return ListTile(
        leading: const Icon(Icons.home_filled),
        title: const Text("Default Start Page"),
        subtitle: Text(_tabName(value)),
        trailing: DropdownButton<int>(
          value: value,
          underline: Container(),
          onChanged: (v) {
            if (v != null) {
              settings.saveDefaultStartTab(v);
              setState(() {});
            }
          },
          items: const [
            DropdownMenuItem(value: 0, child: Text("Home")),
            DropdownMenuItem(value: 1, child: Text("Anime")),
            DropdownMenuItem(value: 2, child: Text("Manga")),
            DropdownMenuItem(value: 3, child: Text("Library")),
          ],
        ),
      );
    });
  }

  String _tabName(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Anime";
      case 2:
        return "Manga";
      case 3:
        return "Library";
      default:
        return "Home";
    }
  }

  // -------- DIALOG FOR ANILIST/MAL HOMEPAGE CARDS ----------
  void _showHomePageCardsDialog(BuildContext context, bool isMal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manage Home Page Cards"),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() {
              final homePageCards =
                  isMal ? settings.homePageCardsMal : settings.homePageCards;
              return SuperListView.builder(
                shrinkWrap: true,
                itemCount: homePageCards.length,
                itemBuilder: (context, index) {
                  final key = homePageCards.keys.elementAt(index);
                  final value = homePageCards[key]!;

                  return CheckboxListTile(
                    title: Text(key),
                    value: value,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        isMal
                            ? settings.updateHomePageCardMal(key, newValue)
                            : settings.updateHomePageCard(key, newValue);
                      }
                    },
                  );
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
