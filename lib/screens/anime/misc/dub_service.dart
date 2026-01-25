import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  static const String liveChartUrl = 'https://www.livechart.me/streams?hide_unavailable=false';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  // Cache for icons found on LiveChart: "Netflix" -> "https://...logo.png"
  static final Map<String, String> _serviceIconCache = {};

  static Future<Map<String, List<Map<String, String>>>> fetchDubSources() async {
    final Map<String, List<Map<String, String>>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams
      final lcResponse = await http.get(Uri.parse(liveChartUrl), headers: _headers);
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        
        // Target the specific columns in the grid
        var streamLists = document.querySelectorAll('div.column.column-block[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          // A. Extract Service Info (Name & Icon)
          String serviceName = "Unknown";
          String serviceIcon = "";

          var heading = list.querySelector('.grouped-list-heading');
          if (heading != null) {
            var titleEl = heading.querySelector('.grouped-list-heading-title');
            if (titleEl != null) serviceName = titleEl.text.trim();

            var imgEl = heading.querySelector('.grouped-list-heading-icon img');
            if (imgEl != null) {
              // LiveChart often uses srcset, but src is usually safe for basic display
              serviceIcon = imgEl.attributes['src'] ?? "";
            }
          }

          // Update Cache
          if (serviceName != "Unknown" && serviceIcon.isNotEmpty) {
            _serviceIconCache[serviceName.toLowerCase()] = serviceIcon;
          }

          // B. Extract Anime Items
          var animeItems = list.querySelectorAll('li.grouped-list-item');
          
          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";
            
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

      // 2. Fetch AnimeSchedule RSS
      final rssResponse = await http.get(Uri.parse(rssUrl), headers: _headers);
      if (rssResponse.statusCode == 200) {
        final document = XmlDocument.parse(rssResponse.body);
        final items = document.findAllElements('item');

        for (var item in items) {
          // Using findAllElements().first to be safe with xml package versions
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
             String name = stream['name'] ?? 'Unknown';
             
             // Try to find a matching icon from our LiveChart scrape cache
             String iconUrl = _findIconInCache(name);

             streams.add({
               'name': name,
               'url': stream['url'] ?? '',
               'icon': iconUrl
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

  static String _findIconInCache(String name) {
    String lowerName = name.toLowerCase();
    // Direct match
    if (_serviceIconCache.containsKey(lowerName)) {
      return _serviceIconCache[lowerName]!;
    }
    // Partial match (e.g. "Netflix" in cache might match "Netflix Basic")
    for (var key in _serviceIconCache.keys) {
      if (lowerName.contains(key) || key.contains(lowerName)) {
        return _serviceIconCache[key]!;
      }
    }
    return ""; 
  }

  static String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
