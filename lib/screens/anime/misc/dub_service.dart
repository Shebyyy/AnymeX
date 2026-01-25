import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  // Updated URL to include all streams to avoid region locking in scraper
  static const String liveChartUrl = 'https://www.livechart.me/streams?hide_unavailable=false';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  // Returns: Map<NormalizedTitle, List<{name, url, icon}>>
  static Future<Map<String, List<Map<String, String>>>> fetchDubSources() async {
    final Map<String, List<Map<String, String>>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams
      final lcResponse = await http.get(Uri.parse(liveChartUrl), headers: _headers);
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        
        // LiveChart structures services in "column-block" divs
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          // 1. Get Service Info (Name & Icon) from the header inside this block
          var header = list.querySelector('.grouped-list-heading');
          var titleEl = header?.querySelector('.grouped-list-heading-title');
          String serviceName = titleEl?.text.trim() ?? "Unknown";

          var imgEl = header?.querySelector('img');
          String serviceIcon = imgEl?.attributes['src'] ?? "";
          // LiveChart sometimes uses srcset, fallback to src. 
          // If relative URL, prepend domain (though usually they are absolute or from s.livechart.me)
          
          // 2. Get all Anime items listed under this service
          var animeItems = list.querySelectorAll('li.grouped-list-item');
          
          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";
            
            // Extract Link
            var linkEl = item.querySelector('a.anime-item__action-button');
            String url = linkEl?.attributes['href'] ?? "";

            // Check if it lists "Dub"
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
                  'icon': serviceIcon
                });
              }
            }
          }
        }
      }

      // 2. Fetch AnimeSchedule RSS (Fallback/New Drops)
      final rssResponse = await http.get(Uri.parse(rssUrl), headers: _headers);
      if (rssResponse.statusCode == 200) {
        final document = XmlDocument.parse(rssResponse.body);
        final items = document.findAllElements('item');

        for (var item in items) {
          // Use findAllElements...first to be safe with xml package versions
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
          
          // Add RSS entry if not present
          if (!dubMap[normalizedTitle]!.any((e) => e['name'] == 'AnimeSchedule')) {
             dubMap[normalizedTitle]!.insert(0, {
               'name': 'AnimeSchedule', 
               'url': link,
               'icon': '' // No icon for RSS, UI handles empty check
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
               'icon': '' // Kuroiru API doesn't return icons, UI will show generic link icon
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
