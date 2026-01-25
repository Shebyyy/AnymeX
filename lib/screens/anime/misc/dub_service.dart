import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  static const String liveChartUrl = 'https://www.livechart.me/streams';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  // Returns a Map where Key = Anime Title (normalized), Value = List of Streaming Services
  static Future<Map<String, List<String>>> fetchDubSources() async {
    final Map<String, List<String>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams (Scraping)
      final lcResponse = await http.get(Uri.parse(liveChartUrl));
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        
        // Find all service blocks
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          // Get Service Name (e.g., Crunchyroll)
          var serviceNameEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = serviceNameEl?.text.trim() ?? "Unknown";

          // Get Anime Items in this list
          var animeItems = list.querySelectorAll('li.grouped-list-item');
          
          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";

            // Check if it lists "Dub"
            if (title.isNotEmpty && infoText.contains("Dub")) {
              if (!dubMap.containsKey(title)) {
                dubMap[title] = [];
              }
              if (!dubMap[title]!.contains(serviceName)) {
                dubMap[title]!.add(serviceName);
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
          // FIXED: using findAllElements(...).first instead of findElement
          final title = item.findAllElements('title').first.innerText;
          
          // Extract Show Name from Title string "Episode 3 of Show Name is out!"
          String extractedTitle = title;
          if (title.contains("Episode") && title.contains(" of ")) {
             int startIndex = title.indexOf(" of ") + 4;
             int endIndex = title.indexOf(" is out");
             if (startIndex != -1 && endIndex != -1) {
               extractedTitle = title.substring(startIndex, endIndex);
             }
          }

          if (!dubMap.containsKey(extractedTitle)) {
            dubMap[extractedTitle] = [];
          }
          dubMap[extractedTitle]!.add("AnimeSchedule (New Drop)");
        }
      }

    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubMap;
  }

  // Fetch specific Kuroiru data for an AniList entry (using MAL ID)
  static Future<List<String>> fetchKuroiruLinks(String malId) async {
    if (malId == 'null' || malId.isEmpty) return [];
    
    try {
      final response = await http.get(Uri.parse('$kuroiruUrl/$malId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> streams = [];
        if (data['data'] != null && data['data']['streams'] != null) {
           for (var stream in data['data']['streams']) {
             streams.add(stream['name'] ?? 'Unknown');
           }
        }
        return streams;
      }
    } catch (e) {
      Logger.i("Error fetching Kuroiru: $e");
    }
    return [];
  }
}
