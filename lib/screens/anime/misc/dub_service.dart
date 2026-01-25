import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:anymex/utils/logger.dart';
import 'package:intl/intl.dart'; // Ensure intl is imported for date formatting

class DubSource {
  final String name;
  final String url;
  final String date;

  DubSource({required this.name, this.url = '', this.date = ''});
}

class DubService {
  static const String rssUrl = 'https://animeschedule.net/dubrss.xml';
  static const String liveChartUrl = 'https://www.livechart.me/streams';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  // Returns a Map where Key = Anime Title (normalized), Value = List of DubSource objects
  static Future<Map<String, List<DubSource>>> fetchDubSources() async {
    final Map<String, List<DubSource>> dubMap = {};

    try {
      // 1. Fetch LiveChart Streams (Scraping)
      final lcResponse = await http.get(Uri.parse(liveChartUrl));
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);
        
        var streamLists = document.querySelectorAll('div[data-controller="stream-list"]');
        
        for (var list in streamLists) {
          // Get Service Name (e.g., Crunchyroll)
          var serviceNameEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = serviceNameEl?.text.trim() ?? "Unknown";

          var animeItems = list.querySelectorAll('li.grouped-list-item');
          
          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";
            
            // Get the Watch Link
            var linkEl = item.querySelector('a.anime-item__action-button');
            String link = linkEl?.attributes['href'] ?? "";

            // Check if it lists "Dub" or "Sub & Dub"
            if (title.isNotEmpty && infoText.contains("Dub")) {
              if (!dubMap.containsKey(title)) {
                dubMap[title] = [];
              }
              // Avoid duplicates if possible
              if (!dubMap[title]!.any((s) => s.name == serviceName)) {
                dubMap[title]!.add(DubSource(name: serviceName, url: link));
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
          final pubDateStr = item.findAllElements('pubDate').first.innerText;
          
          // Format Date (Simple)
          String formattedDate = "";
          try {
             // Example: Sun, 25 Jan 2026 08:00:00 UTC
             DateTime parsed = HttpDate.parse(pubDateStr); 
             formattedDate = DateFormat('h:mm a').format(parsed.toLocal());
          } catch (_) {
             formattedDate = "New";
          }

          // Extract Show Name
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
          dubMap[extractedTitle]!.add(DubSource(
            name: "AnimeSchedule", 
            url: link,
            date: formattedDate
          ));
        }
      }

    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubMap;
  }

  // Fetch specific Kuroiru data
  static Future<List<DubSource>> fetchKuroiruLinks(String malId) async {
    if (malId == 'null' || malId.isEmpty) return [];
    
    try {
      final response = await http.get(Uri.parse('$kuroiruUrl/$malId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<DubSource> streams = [];
        if (data['data'] != null && data['data']['streams'] != null) {
           for (var stream in data['data']['streams']) {
             streams.add(DubSource(
               name: stream['name'] ?? 'Unknown',
               url: stream['url'] ?? '' // Assuming API provides URL, otherwise empty
             ));
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
