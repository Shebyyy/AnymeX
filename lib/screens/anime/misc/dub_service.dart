import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  static const String liveChartUrl = 'https://www.livechart.me/streams';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  // Returns a Map where Key = Anime Title (normalized), Value = List of {name, url}
  static Future<Map<String, List<Map<String, String>>>> fetchDubSources() async {
    final Map<String, List<Map<String, String>>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams (Scraping)
      final lcResponse = await http.get(Uri.parse(liveChartUrl));
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          var serviceNameEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = serviceNameEl?.text.trim() ?? "Unknown";
          
          var animeItems = list.querySelectorAll('li.grouped-list-item');
          
          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";
            
            // Try to get a link if available
            var linkEl = item.querySelector('a.anime-item__action-button');
            String url = linkEl?.attributes['href'] ?? "";

            // Check if it lists "Dub"
            if (title.isNotEmpty && infoText.contains("Dub")) {
              String normalizedTitle = _normalizeTitle(title);
              if (!dubMap.containsKey(normalizedTitle)) {
                dubMap[normalizedTitle] = [];
              }
              // Avoid dupes
              if (!dubMap[normalizedTitle]!.any((e) => e['name'] == serviceName)) {
                dubMap[normalizedTitle]!.add({'name': serviceName, 'url': url});
              }
            }
          }
        }
      }

      // 2. Fetch AnimeSchedule RSS
      final rssResponse = await http.get(Uri.parse(rssUrl));
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
             dubMap[normalizedTitle]!.add({'name': 'AnimeSchedule', 'url': link});
          }
        }
      }

    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubMap;
  }

  // Fetch specific Kuroiru data for an AniList entry (using MAL ID)
  static Future<List<Map<String, String>>> fetchKuroiruLinks(String malId) async {
    if (malId == 'null' || malId.isEmpty) return [];
    
    try {
      final response = await http.get(Uri.parse('$kuroiruUrl/$malId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> streams = [];
        if (data['data'] != null && data['data']['streams'] != null) {
           for (var stream in data['data']['streams']) {
             streams.add({
               'name': stream['name'] ?? 'Unknown',
               'url': stream['url'] ?? ''
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

  static String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
