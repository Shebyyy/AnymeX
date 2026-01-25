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

  // Returns: Map<NormalizedTitle, List<{name, url, icon}>>
  static Future<Map<String, List<Map<String, String>>>> fetchDubSources() async {
    final Map<String, List<Map<String, String>>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams
      final lcResponse = await http.get(Uri.parse(liveChartUrl), headers: _headers);
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        
        // Find all service blocks
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          // Extract Service Name
          var titleEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = titleEl?.text.trim() ?? "Unknown";

          // Extract Service Icon
          var imgEl = list.querySelector('.grouped-list-heading-icon img');
          String? serviceIcon = imgEl?.attributes['src'];
          // Handle relative URLs if necessary (LiveChart usually provides absolute)
          if (serviceIcon != null && serviceIcon.startsWith('/')) {
            serviceIcon = 'https://u.livechart.me$serviceIcon'; 
          }

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
                  'icon': serviceIcon ?? ''
                });
              }
            }
          }
        }
      }

      // 2. Fetch AnimeSchedule RSS (Fallback)
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
               'icon': '' // RSS doesn't give icons
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
               'icon': '' 
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
