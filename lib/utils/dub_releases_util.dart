import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:anymex/screens/anime/misc/dub_release.dart';

class DubReleasesUtil {
  static Future<List<DubRelease>> getDubReleases(
      DateTime date, List<int> malIds) async {
    final Set<DubRelease> allReleases = {};

    // Fetch from all three sources
    await Future.wait([
      _fetchFromKuroiru(malIds, allReleases),
      _fetchFromAnimeSchedule(date, allReleases),
      _fetchFromLiveChart(date, allReleases),
    ]);

    // Filter releases for the specific date
    final filteredReleases = allReleases.where((release) {
      return release.releaseTime.year == date.year &&
          release.releaseTime.month == date.month &&
          release.releaseTime.day == date.day;
    }).toList();

    // Sort by release time
    filteredReleases.sort((a, b) => a.releaseTime.compareTo(b.releaseTime));

    return filteredReleases;
  }

  static Future<void> _fetchFromKuroiru(
      List<int> malIds, Set<DubRelease> releases) async {
    try {
      for (final malId in malIds) {
        final response =
            await http.get(Uri.parse('https://kuroiru.co/api/anime/$malId'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['licensed'] != null && data['licensed'] is List) {
            final licensed = data['licensed'] as List;
            
            for (final site in licensed) {
              if (site['dub'] == true && site['last_episode'] != null) {
                // Try to parse release time if available
                DateTime? releaseTime;
                if (site['last_updated'] != null) {
                  try {
                    releaseTime = DateTime.parse(site['last_updated']);
                  } catch (e) {
                    releaseTime = DateTime.now();
                  }
                } else {
                  releaseTime = DateTime.now();
                }

                releases.add(DubRelease(
                  animeTitle: data['title'] ?? 'Unknown',
                  episode: 'Episode ${site['last_episode']}',
                  releaseTime: releaseTime,
                  licensedSites: [site['site'] ?? 'Unknown'],
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      // Silent fail for this source
    }
  }

  static Future<void> _fetchFromAnimeSchedule(
      DateTime date, Set<DubRelease> releases) async {
    try {
      final response = await http
          .get(Uri.parse('https://animeschedule.net/dubrss.xml'));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        for (final item in items) {
          final title = item.findElements('title').first.innerText;
          final pubDate = item.findElements('pubDate').first.innerText;
          final description = item.findElements('description').first.innerText;

          // Parse release date
          final releaseTime = _parseRssDate(pubDate);

          // Extract episode number from title
          final episodeMatch = RegExp(r'Episode (\d+)').firstMatch(title);
          final episode =
              episodeMatch != null ? 'Episode ${episodeMatch.group(1)}' : '';

          // Extract anime title
          final animeTitleMatch =
              RegExp(r'Episode \d+ of (.+) is out!').firstMatch(title);
          final animeTitle =
              animeTitleMatch?.group(1) ?? title.split(' ').first;

          releases.add(DubRelease(
            animeTitle: animeTitle,
            episode: episode,
            releaseTime: releaseTime,
            licensedSites: ['AnimeSchedule'],
          ));
        }
      }
    } catch (e) {
      // Silent fail for this source
    }
  }

  static Future<void> _fetchFromLiveChart(
      DateTime date, Set<DubRelease> releases) async {
    try {
      // Format season (e.g., "winter-2026")
      final season = _getSeason(date);
      final year = date.year;
      final seasonSlug = '$season-$year';

      final response = await http.get(
          Uri.parse('https://www.livechart.me/streams?season=$seasonSlug'));

      if (response.statusCode == 200) {
        final body = response.body;

        // Parse HTML to extract dub information
        // Look for entries with "Dub" or "Sub & Dub" in the info text
        final dubPattern = RegExp(
          r'data-title="([^"]+)".*?※\s*(?:Sub\s*&\s*)?Dub.*?Episode\s*(\d+)',
          multiLine: true,
          dotAll: true,
        );

        final matches = dubPattern.allMatches(body);

        for (final match in matches) {
          final animeTitle = match.group(1) ?? '';
          final episode = 'Episode ${match.group(2)}';

          // Try to extract streaming site
          final sitePattern = RegExp(
            r'${RegExp.escape(animeTitle)}.*?href="([^"]+)".*?WATCH',
            multiLine: true,
            dotAll: true,
          );
          final siteMatch = sitePattern.firstMatch(body);
          final site = siteMatch != null
              ? Uri.parse(siteMatch.group(1)!).host
              : 'Unknown';

          releases.add(DubRelease(
            animeTitle: animeTitle,
            episode: episode,
            releaseTime: date,
            licensedSites: [site],
          ));
        }
      }
    } catch (e) {
      // Silent fail for this source
    }
  }

  static DateTime _parseRssDate(String dateString) {
    try {
      // RFC 822 format: "Sun, 25 Jan 2026 08:00:00 UTC"
      final parts = dateString.split(' ');
      final day = int.parse(parts[1]);
      final month = _monthToNumber(parts[2]);
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime.utc(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  static int _monthToNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? 1;
  }

  static String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 1 && month <= 3) return 'winter';
    if (month >= 4 && month <= 6) return 'spring';
    if (month >= 7 && month <= 9) return 'summer';
    return 'fall';
  }
}
