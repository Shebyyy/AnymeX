import 'dart:async';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/calendar_data.dart';
// Updated import to match where you created the file
import 'package:anymex/screens/anime/misc/dub_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
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

  // Dub Mode
  RxBool isDubMode = false.obs;
  RxBool isFetching = false.obs;
  Map<String, List<Map<String, String>>> dubCache = {};

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

  Future<void> _toggleDub() async {
    isDubMode.value = !isDubMode.value;
    if (isDubMode.value && dubCache.isEmpty) {
      isFetching.value = true;
      dubCache = await DubService.fetchDubSources();
      isFetching.value = false;
    }
  }

  // Normalizer for matching titles
  String _norm(String t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<Map<String, String>> _getDubs(Media m) {
    String t = _norm(m.title);
    if (dubCache.containsKey(t)) return dubCache[t]!;
    // Removed titleEnglish check because Media model doesn't have it
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
          title: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnymexText(text: "Calendar", color: Theme.of(context).colorScheme.primary, variant: TextVariant.semiBold, size: 16),
                if (isDubMode.value)
                  AnymexText(text: isFetching.value ? "Fetching..." : "Showing Dubs Only", variant: TextVariant.regular, size: 10, color: Colors.grey)
              ])),
          actions: [
            Obx(() => IconButton(
                onPressed: _toggleDub,
                icon: Icon(isDubMode.value ? HugeIcons.strokeRoundedMicOff01 : HugeIcons.strokeRoundedMic01,
                    color: isDubMode.value ? Theme.of(context).colorScheme.primary : null))),
            const SizedBox(width: 10),
            if (serviceHandler.isLoggedIn.value) ...[
              IconButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
                  onPressed: () => setState(() => includeList = !includeList),
                  icon: Icon(!includeList ? Icons.book_rounded : Icons.text_snippet_sharp)),
              const SizedBox(width: 10),
            ],
            IconButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
                onPressed: () => setState(() => isGrid = !isGrid),
                icon: Icon(isGrid ? Icons.grid_view_rounded : Icons.view_list)),
            const SizedBox(width: 10),
          ],
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: dateTabs.map((date) {
              return Obx(() {
                var list = (includeList ? listData : rawData).where((m) =>
                    DateTime.fromMillisecondsSinceEpoch(m.nextAiringEpisode!.airingAt * 1000).day == date.day).toList();
                
                // Smart Count: If Dub Mode, count only matches
                if (isDubMode.value && !isFetching.value) {
                  list = list.where((m) => _getDubs(m).isNotEmpty || m.idMal != null).toList();
                }
                
                return Tab(child: AnymexText(variant: TextVariant.bold, text: '${DateFormat('EEEE, MMM d').format(date)} (${list.length})'));
              });
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: dateTabs.map((date) {
            return Obx(() {
              if (isFetching.value) return const Center(child: AnymexProgressIndicator());
              
              var list = (includeList ? listData : rawData).where((m) =>
                  DateTime.fromMillisecondsSinceEpoch(m.nextAiringEpisode!.airingAt * 1000).day == date.day).toList();

              if (isDubMode.value) {
                // Filter List
                list = list.where((m) => _getDubs(m).isNotEmpty || m.idMal != null).toList();
              }

              if (list.isEmpty) return const Center(child: Text("No Anime Found"));

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: list.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getResponsiveCrossAxisVal(MediaQuery.of(context).size.width, itemWidth: isGrid ? 120 : 400),
                    mainAxisExtent: getResponsiveSize(context, mobileSize: isGrid ? 280 : 150, desktopSize: isGrid ? 280 : 180),
                    crossAxisSpacing: 10, mainAxisSpacing: 25),
                itemBuilder: (context, index) {
                  final data = list[index];
                  final dubs = isDubMode.value ? _getDubs(data) : <Map<String, String>>[];
                  return isGrid 
                    ? GridAnimeCard(data: data, dubInfo: dubs, isDubMode: isDubMode.value) 
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
  final Media data;
  final List<Map<String, String>> dubInfo;
  final bool isDubMode;
  const GridAnimeCard({super.key, required this.data, this.dubInfo = const [], this.isDubMode = false});

  @override
  State<GridAnimeCard> createState() => _GridAnimeCardState();
}

class _GridAnimeCardState extends State<GridAnimeCard> {
  List<Map<String, String>> streams = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    streams = List.from(widget.dubInfo);
    if (widget.isDubMode && widget.data.idMal != null && !_loaded) _lazyLoad();
  }

  void _lazyLoad() async {
    var k = await DubService.fetchKuroiruLinks(widget.data.idMal.toString());
    if (mounted && k.isNotEmpty) setState(() { streams.addAll(k.where((n) => !streams.any((e) => e['name'] == n['name']))); _loaded = true; });
  }

  IconData _getBrandIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('crunchyroll')) return HugeIcons.strokeRoundedPlay; 
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
      width: 108, height: 280,
      child: Column(children: [
        Stack(children: [
          AnymexOnTap(
            onTap: () => navigate(() => AnimeDetailsPage(media: widget.data, tag: widget.data.title)),
            child: Hero(tag: widget.data.title, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: NetworkSizedImage(radius: 12, imageUrl: widget.data.poster, width: 108, height: 160))),
          ),
          if (widget.isDubMode) Positioned(top: 5, right: 5, child: CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(HugeIcons.strokeRoundedMic01, size: 12, color: Theme.of(context).colorScheme.primary))),
        ]),
        const SizedBox(height: 5),
        if (widget.isDubMode && streams.isNotEmpty)
          SizedBox(height: 20, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: streams.length, separatorBuilder: (_,__) => const SizedBox(width:4),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () async {
                 if (streams[i]['url'] != null) {
                   await launchUrl(Uri.parse(streams[i]['url']!), mode: LaunchMode.externalApplication);
                 }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBrandColor(streams[i]['name']!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getBrandColor(streams[i]['name']!).withOpacity(0.5)),
                ),
                child: Row(children: [
                  Icon(_getBrandIcon(streams[i]['name']!), size: 10, color: _getBrandColor(streams[i]['name']!)),
                  const SizedBox(width: 3),
                  Text(streams[i]['name']!.length > 8 ? "${streams[i]['name']!.substring(0, 6)}.." : streams[i]['name']!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getBrandColor(streams[i]['name']!)))
                ]),
              ),
            )
          ))
        else
          AnymexText(text: 'EP ${widget.data.nextAiringEpisode?.episode ?? "?"}', variant: TextVariant.regular, fontStyle: FontStyle.italic, color: Colors.grey, size: 12),
        const SizedBox(height: 2),
        AnymexText(text: widget.data.title, maxLines: 2, size: 13, textAlign: TextAlign.center),
      ]),
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
    if (timeLeft.value > 0) Timer.periodic(const Duration(seconds: 1), (t) => mounted && timeLeft.value > 0 ? timeLeft.value-- : t.cancel());
  }

  String formatTime(int s) {
    if (s <= 0) return 'Aired';
    int d = s ~/ 86400; s %= 86400;
    int h = s ~/ 3600; s %= 3600;
    int m = s ~/ 60;
    if (d > 0) return "$d d";
    if (h > 0) return "$h h";
    return "$m m";
  }

  @override
  Widget build(BuildContext context) {
    return AnymexOnTap(
      onTap: () {
        navigate(
            () => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), 
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
          border: Border(right: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary))
        ),
        child: Stack(children: [
          Positioned.fill(child: NetworkSizedImage(imageUrl: widget.data.cover ?? widget.data.poster, radius: 12, width: double.infinity)),
          Positioned.fill(child: Blur(blur: 4, blurColor: Colors.transparent, child: Container())),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.3),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8)
          ], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
          Row(children: [
            NetworkSizedImage(imageUrl: widget.data.poster, width: 110, height: double.infinity, radius: 12),
            Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              AnymexText(text: "EP ${widget.data.nextAiringEpisode?.episode}", size: 14, color: Theme.of(context).colorScheme.primary, variant: TextVariant.bold),
              AnymexText(text: widget.data.title, size: 16, maxLines: 2, variant: TextVariant.bold),
            ])))
          ]),
          Positioned(bottom: 10, right: 10, child: Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.primary),
            child: AnymexText(text: formatTime(timeLeft.value), size: 12, color: Theme.of(context).colorScheme.onPrimary, variant: TextVariant.bold),
          )))
        ]),
      ),
    );
  }
}
