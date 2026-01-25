import 'dart:async';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/calendar_data.dart';
import 'package:anymex/controllers/services/dub_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> with SingleTickerProviderStateMixin {
  final serviceHandler = Get.find<ServiceHandler>();
  RxList<Media> calendarData = <Media>[].obs;
  RxList<Media> listData = <Media>[].obs;
  RxList<Media> rawData = <Media>[].obs;
  late TabController _tabController;
  List<DateTime> dateTabs = [];
  bool isGrid = true;
  bool isLoading = true;
  bool includeList = false;

  // Dub Variables
  bool isDubMode = false;
  bool isFetchingDubs = false;
  Map<String, List<Map<String, String>>> dubSources = {};

  @override
  void initState() {
    super.initState();
    final ids = serviceHandler.animeList.map((e) => e.id).toSet().toList();
    fetchCalendarData(calendarData).then((_) {
      if (mounted) {
        setState(() {
          rawData.value = calendarData.map((e) => e).toList();
          listData.value = calendarData.where((e) => ids.contains(e.id)).toList();
          isLoading = false;
        });
      }
    });

    dateTabs = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
    _tabController = TabController(length: dateTabs.length, vsync: this);
  }

  Future<void> toggleDubMode() async {
    if (isDubMode) {
      setState(() => isDubMode = false);
      return;
    }

    setState(() {
      isDubMode = true;
      isFetchingDubs = true;
    });

    if (dubSources.isEmpty) {
      dubSources = await DubService.fetchDubSources();
    }

    setState(() => isFetchingDubs = false);
  }

  void changeLayout() => setState(() => isGrid = !isGrid);
  void changeListType() => setState(() => includeList = !includeList);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Normalizes AniList title to match Scraper title
  String normalize(String t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<Map<String, String>> getCachedDubInfo(Media media) {
    String nTitle = normalize(media.title);
    if (dubSources.containsKey(nTitle)) return dubSources[nTitle]!;
    // Fallback: check english title if different
    if (media.titleEnglish != null) {
      String nEng = normalize(media.titleEnglish!);
      if (dubSources.containsKey(nEng)) return dubSources[nEng]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.primary)),
          actions: [
            IconButton(
              onPressed: toggleDubMode,
              icon: Icon(
                // Logic: Open Mic (Default/Off) -> Click -> Closed Mic (Dub Mode)
                isDubMode ? HugeIcons.strokeRoundedMicOff01 : HugeIcons.strokeRoundedMic01,
                color: isDubMode ? Theme.of(context).colorScheme.primary : null,
              ),
              tooltip: isDubMode ? "Show All" : "Show Dubs Only",
            ),
            const SizedBox(width: 10),
            if (serviceHandler.isLoggedIn.value) ...[
              IconButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
                  onPressed: changeListType,
                  icon: Icon(!includeList ? Icons.book_rounded : Icons.text_snippet_sharp)),
              const SizedBox(width: 10),
            ],
            IconButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
                onPressed: changeLayout,
                icon: Icon(isGrid ? Icons.grid_view_rounded : Icons.view_list)),
            const SizedBox(width: 10),
          ],
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymexText(
                text: "Calendar",
                color: Theme.of(context).colorScheme.primary,
                variant: TextVariant.semiBold,
                size: 16,
              ),
              if (isDubMode)
                AnymexText(
                  text: "Dub Schedule (LiveChart • RSS • Kuroiru)",
                  variant: TextVariant.regular,
                  size: 10,
                  color: Colors.grey,
                )
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: dateTabs.map((date) {
              return Obx(() {
                // Calculate count based on CURRENT filters (including Dub Mode)
                List<Media> filteredList = (includeList ? listData : rawData)
                    .where((media) =>
                        DateTime.fromMillisecondsSinceEpoch(media.nextAiringEpisode!.airingAt * 1000).day ==
                        date.day)
                    .toList();

                if (isDubMode && !isFetchingDubs) {
                  // Filter out items that have no Dub info AND no MAL ID (since we can't check Kuroiru)
                  // Note: This is an approximation for the tab count to stay fast
                  filteredList = filteredList.where((m) {
                    bool hasGlobal = getCachedDubInfo(m).isNotEmpty;
                    bool canFetchKuroiru = m.idMal != null;
                    return hasGlobal || canFetchKuroiru;
                  }).toList();
                }

                return Tab(
                  child: AnymexText(
                    variant: TextVariant.bold,
                    text: '${DateFormat('EEEE, MMMM d').format(date)} (${filteredList.length})',
                  ),
                );
              });
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: dateTabs.map((date) {
            return Obx(() {
              List<Media> filteredList = (includeList ? listData : rawData)
                  .where((media) =>
                      DateTime.fromMillisecondsSinceEpoch(media.nextAiringEpisode!.airingAt * 1000).day ==
                      date.day)
                  .toList();

              if (isLoading || isFetchingDubs) {
                return const Center(child: AnymexProgressIndicator());
              }

              if (isDubMode) {
                // STRICT filtering for Dub Mode:
                // Show if we have cached sources OR if we have a MAL ID to check Kuroiru
                filteredList = filteredList.where((m) {
                  return getCachedDubInfo(m).isNotEmpty || m.idMal != null;
                }).toList();
              }

              if (filteredList.isEmpty) {
                return const Center(child: Text("No Anime found for this day"));
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                itemCount: filteredList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getResponsiveCrossAxisVal(MediaQuery.of(context).size.width,
                        itemWidth: isGrid ? 120 : 400),
                    mainAxisExtent: getResponsiveSize(context,
                        mobileSize: isGrid ? 280 : 150, // Increased height for dub chips
                        desktopSize: isGrid ? 280 : 180),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 25),
                itemBuilder: (context, index) {
                  final data = filteredList[index];
                  final cachedDubs = isDubMode ? getCachedDubInfo(data) : <Map<String, String>>[];
                  return isGrid
                      ? GridAnimeCard(data: data, dubInfo: cachedDubs, isDubMode: isDubMode)
                      : BlurAnimeCard(data: data);
                },
              );
            });
          }).toList(),
        ),
      ),
    );
  }
}

class GridAnimeCard extends StatefulWidget {
  const GridAnimeCard({
    super.key,
    required this.data,
    this.dubInfo = const [],
    this.isDubMode = false,
  });
  final Media data;
  final List<Map<String, String>> dubInfo;
  final bool isDubMode;

  @override
  State<GridAnimeCard> createState() => _GridAnimeCardState();
}

class _GridAnimeCardState extends State<GridAnimeCard> {
  static const double cardWidth = 108;
  static const double cardHeight = 280; // Slightly taller
  List<Map<String, String>> streams = [];
  bool fetchedKuroiru = false;

  @override
  void initState() {
    super.initState();
    streams = List.from(widget.dubInfo);
    if (widget.isDubMode && widget.data.idMal != null && !fetchedKuroiru) {
      _fetchKuroiruLazy();
    }
  }

  void _fetchKuroiruLazy() async {
    // Only fetch if we don't have enough info or just want to be thorough
    var kStreams = await DubService.fetchKuroiruLinks(widget.data.idMal.toString());
    if (mounted && kStreams.isNotEmpty) {
      setState(() {
        // Merge without duplicates
        for (var k in kStreams) {
          if (!streams.any((s) => s['name'] == k['name'])) {
            streams.add(k);
          }
        }
        fetchedKuroiru = true;
      });
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  IconData _getBrandIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('crunchyroll')) return HugeIcons.strokeRoundedPlay; // Generic play for now
    if (name.contains('netflix')) return HugeIcons.strokeRoundedPlay;
    if (name.contains('disney')) return HugeIcons.strokeRoundedPlay;
    if (name.contains('muse')) return HugeIcons.strokeRoundedYoutube;
    if (name.contains('ani-one')) return HugeIcons.strokeRoundedYoutube;
    if (name.contains('bilibili')) return HugeIcons.strokeRoundedTv01;
    return HugeIcons.strokeRoundedLink01;
  }

  Color _getBrandColor(String name) {
    name = name.toLowerCase();
    if (name.contains('crunchyroll')) return Colors.orange;
    if (name.contains('netflix')) return Colors.red;
    if (name.contains('disney')) return Colors.blue;
    if (name.contains('muse') || name.contains('ani-one')) return Colors.redAccent;
    if (name.contains('bilibili')) return Colors.blueAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              AnymexOnTap(
                margin: 0,
                onTap: () {
                  navigate(() => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
                },
                child: Hero(
                  tag: widget.data.title,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: NetworkSizedImage(
                      radius: 12,
                      imageUrl: widget.data.poster,
                      width: cardWidth,
                      height: 160,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildEpisodeChip(widget.data),
              ),
              // Mic Icon Overlay if Dub Mode is On
              if (widget.isDubMode)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(
                      HugeIcons.strokeRoundedMic01,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // STREAM CHIPS (If Dub Mode)
          if (widget.isDubMode && streams.isNotEmpty)
            Container(
              height: 25,
              margin: const EdgeInsets.only(bottom: 5),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: streams.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (context, i) {
                  final s = streams[i];
                  return GestureDetector(
                    onTap: () => _launchUrl(s['url']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getBrandColor(s['name']!).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _getBrandColor(s['name']!).withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(_getBrandIcon(s['name']!),
                              size: 10, color: _getBrandColor(s['name']!)),
                          const SizedBox(width: 3),
                          Text(
                            s['name']!.length > 10
                                ? "${s['name']!.substring(0, 8)}..."
                                : s['name']!,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getBrandColor(s['name']!)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_filter_rounded, color: Colors.grey, size: 16),
                if (widget.data.nextAiringEpisode?.episode != null) ...[
                  const SizedBox(width: 5),
                  AnymexText(
                    text: 'EP ${widget.data.nextAiringEpisode!.episode}',
                    maxLines: 1,
                    variant: TextVariant.regular,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    size: 12,
                  ),
                ]
              ],
            ),
          const SizedBox(height: 2),
          SizedBox(
            width: cardWidth,
            child: AnymexText(
              text: widget.data.title,
              maxLines: 2,
              size: 13,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeChip(Media media) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.star5, size: 14, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 4),
          AnymexText(
            text: media.rating,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 11,
            variant: TextVariant.bold,
          ),
        ],
      ),
    );
  }
}

// RESTORED BLUR ANIME CARD
class BlurAnimeCard extends StatefulWidget {
  final Media data;
  const BlurAnimeCard({super.key, required this.data});

  @override
  State<BlurAnimeCard> createState() => _BlurAnimeCardState();
}

class _BlurAnimeCardState extends State<BlurAnimeCard> {
  RxInt timeLeft = 0.obs;

  @override
  void initState() {
    super.initState();
    timeLeft.value = widget.data.nextAiringEpisode?.timeUntilAiring ?? 0;
    if (timeLeft.value > 0) startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (timeLeft.value > 0) {
          timeLeft.value--;
        } else {
          timer.cancel();
        }
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds <= 0) return 'Aired';
    int days = seconds ~/ (24 * 3600);
    seconds %= 24 * 3600;
    int hours = seconds ~/ 3600;
    seconds %= 3600;
    int minutes = seconds ~/ 60;
    
    if (days > 0) return "$days d";
    if (hours > 0) return "$hours h";
    return "$minutes m";
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(() => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
          border: Border(right: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary))
        ),
        child: Stack(children: [
          Positioned.fill(
            child: NetworkSizedImage(
              imageUrl: widget.data.cover ?? widget.data.poster,
              radius: 0,
              width: double.infinity,
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: Blur(blur: 4, blurColor: Colors.transparent, child: Container()),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: gradientColors)),
            ),
          ),
          Row(
            children: [
              NetworkSizedImage(
                width: 110,
                height: double.infinity,
                radius: 0,
                imageUrl: widget.data.poster,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: widget.data.nextAiringEpisode != null
                            ? "EP ${widget.data.nextAiringEpisode!.episode}"
                            : "Soon",
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                        variant: TextVariant.bold,
                      ),
                      const SizedBox(height: 5),
                      AnymexText(
                        text: widget.data.title,
                        size: 16,
                        maxLines: 2,
                        variant: TextVariant.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AnymexText(
                    text: formatTime(timeLeft.value),
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                    variant: TextVariant.bold,
                  ),
                )),
          ),
        ]),
      ),
    );
  }
}

class BlurAnimeCard extends StatefulWidget {
  final Media data;

  const BlurAnimeCard({super.key, required this.data});

  @override
  State<BlurAnimeCard> createState() => _BlurAnimeCardState();
}

class _BlurAnimeCardState extends State<BlurAnimeCard> {
  RxInt timeLeft = 0.obs;

  @override
  void initState() {
    super.initState();
    timeLeft.value = widget.data.nextAiringEpisode?.timeUntilAiring ?? 0;
    if (timeLeft.value > 0) startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (timeLeft.value > 0) {
          timeLeft.value--;
        } else {
          timer.cancel();
        }
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds <= 0) {
      return 'Aired Already';
    } else {
      int days = seconds ~/ (24 * 3600);
      seconds %= 24 * 3600;
      int hours = seconds ~/ 3600;
      seconds %= 3600;
      int minutes = seconds ~/ 60;
      seconds %= 60;

      List<String> parts = [];
      if (days > 0) parts.add("$days days");
      if (hours > 0) parts.add("$hours hours");
      if (minutes > 0) parts.add("$minutes minutes");
      if (seconds > 0 || parts.isEmpty) parts.add("$seconds seconds");

      return parts.join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(
            () => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.primary)),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: widget.data.cover ?? widget.data.poster,
                radius: 0,
                width: double.infinity,
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: Blur(
                  blur: 4,
                  blurColor: Colors.transparent,
                  child: Container(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkSizedImage(
                  width: getResponsiveSize(context,
                      mobileSize: 120, desktopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 150, desktopSize: 180),
                  radius: 0,
                  imageUrl: widget.data.poster,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 10, desktopSize: 30)),
                        AnymexText(
                          text: widget.data.nextAiringEpisode != null
                              ? "Episode ${widget.data.nextAiringEpisode!.episode}"
                              : "Airing Soon",
                          size: 14,
                          maxLines: 2,
                          color: Theme.of(context).colorScheme.primary,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        AnymexText(
                          text: widget.data.title,
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Obx(() {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AnymexText(
                    text: formatTime(timeLeft.value),
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                    variant: TextVariant.bold,
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
