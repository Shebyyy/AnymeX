import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  static const String liveChartUrl = 'https://www.livechart.me/streams';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  // Maps Normalized Title -> List of {name, url, icon}
  static Future<Map<String, List<Map<String, String>>>> fetchDubSources() async {
    final Map<String, List<Map<String, String>>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams
      final lcResponse = await http.get(Uri.parse(liveChartUrl), headers: _headers);
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');

        for (var list in streamLists) {
          // Extract Service Name
          var serviceNameEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = serviceNameEl?.text.trim() ?? "Unknown";
          
          // Extract Service Icon
          var iconEl = list.querySelector('.grouped-list-heading-icon img');
          String serviceIcon = iconEl?.attributes['src'] ?? "";

          var animeItems = list.querySelectorAll('li.grouped-list-item');

          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";
            
            // Extract Link
            var linkEl = item.querySelector('a.anime-item__action-button');
            String url = linkEl?.attributes['href'] ?? "";

            if (title.isNotEmpty && infoText.contains("Dub")) {
              String normalizedTitle = _normalizeTitle(title);
              if (!dubMap.containsKey(normalizedTitle)) {
                dubMap[normalizedTitle] = [];
              }
              // Add if not duplicate
              if (!dubMap[normalizedTitle]!.any((e) => e['name'] == serviceName)) {
                dubMap[normalizedTitle]!.add({
                  'name': serviceName, 
                  'url': url,
                  'icon': serviceIcon // Store the icon URL
                });
              }
            }
          }
        }
      }

      // 2. Fetch AnimeSchedule RSS
      final rssResponse = await http.get(Uri.parse(rssUrl), headers: _headers);
      if (rssResponse.statusCode == 200) {
        final document = XmlDocument.parse(rssResponse.body);
        final items = document.findAllElements('item');

        for (var item in items) {
          final title = item.findAllElements('title').first.innerText;
          final link = item.findAllElements('link').first.innerText;

          String extractedTitle = title;
          if (title.contains("Episode") && title.contains(" of ")) {
            int startIndex = title.indexOf(" of ") + 4;
            int endIndex = title.indexOf(" is out");
            if (startIndex != -1 && endIndex != -1) {
              extractedTitle = title.substring(startIndex, endIndex);
            }
          }

          String normalizedTitle = _normalizeTitle(extractedTitle);
          if (!dubMap.containsKey(normalizedTitle)) {
            dubMap[normalizedTitle] = [];
          }
          if (!dubMap[normalizedTitle]!.any((e) => e['name'] == 'AnimeSchedule')) {
            dubMap[normalizedTitle]!.insert(0, {
              'name': 'AnimeSchedule', 
              'url': link,
              'icon': '' // No icon for RSS
            });
          }
        }
      }
    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubMap;
  }

  static Future<List<Map<String, String>>> fetchKuroiruLinks(String malId) async {
    if (malId == 'null' || malId.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse('$kuroiruUrl/$malId'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> streams = [];
        if (data['data'] != null && data['data']['streams'] != null) {
          for (var stream in data['data']['streams']) {
            streams.add({
              'name': stream['name'] ?? 'Unknown',
              'url': stream['url'] ?? '',
              'icon': _getIconForKuroiru(stream['name'] ?? '')
            });
          }
        }
        return streams;
      }
    } catch (e) {
      Logger.i("Error fetching Kuroiru: $e");
    }
    return [];
  }

  // Helper to give generic icons to Kuroiru text-only results
  static String _getIconForKuroiru(String name) {
    name = name.toLowerCase();
    if (name.contains('netflix')) return 'https://u.livechart.me/streaming_service/4/logo/59caed39b5011cb89d54d378a3ff6076.png/small.png';
    if (name.contains('crunchyroll')) return 'https://u.livechart.me/streaming_service/248/logo/021ce3e43f14abf627b8ffa0d95f756c.png/small.png';
    if (name.contains('disney+')) return 'https://u.livechart.me/streaming_service/157/logo/b4628000b52777afe843f67e20a77756.webp/small.png';
    if (name.contains('prime')) return 'https://u.livechart.me/streaming_service/37/logo/5ff3eaee4c6dc7a12591ffdb2b9f837a.webp/small.png';
    if (name.contains('hidive')) return 'https://u.livechart.me/streaming_service/24/logo/3757270387532386377759620757274.png/small.png';
    if (name.contains('bilibili')) return 'https://u.livechart.me/streaming_service/31/logo/0aeb8e147fa637cad01f0dca12c511f0.png/small.png';
    if (name.contains('9now')) return 'https://u.livechart.me/streaming_service/453/logo/9c3ecbc4301c6a18e1615dee0cecf794.webp/small.png';
    if (name.contains('akiba pass tv')) return 'https://u.livechart.me/streaming_service/367/logo/238615197870e1a9f216bf37100d62f0.png/medium.png';
    if (name.contains('aniplus')) return 'https://u.livechart.me/streaming_service/105/logo/88f821236bdbac617a17f00e7a27a5a8.png/small.png';
    if (name.contains('aniplus asia')) return 'https://u.livechart.me/streaming_service/65/logo/8161975462124396c1dabf45c8ede601.webp/medium.png';
    if (name.contains('animation digital network')) return 'https://u.livechart.me/streaming_service/19/logo/6464da0c6398e1fc4ce2d50aad6c8cbb.png/medium.png';
    if (name.contains('disney+ hotstar')) return 'https://u.livechart.me/streaming_service/157/logo/b4628000b52777afe843f67e20a77756.webp/medium.png';
    return ''; // Unknown
  }

  static String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
