import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryModel {
  OfflineMedia? media;
  String? title;
  String cover;
  String poster;
  String? sourceName;
  String? formattedEpisodeTitle;
  num? progress;
  num? totalProgress;
  String? progressTitle;
  bool? isManga;
  double? calculatedProgress;
  VoidCallback? onTap;
  String? progressText;
  String? date;

  HistoryModel(
      {this.media,
      this.title,
      required this.cover,
      required this.poster,
      this.formattedEpisodeTitle,
      this.sourceName,
      this.progress,
      this.totalProgress,
      this.progressTitle,
      this.isManga,
      this.calculatedProgress,
      this.onTap,
      this.progressText,
      this.date});

  factory HistoryModel.fromOfflineMedia(OfflineMedia media, bool isManga) {
    final onTap = isManga
        ? () {
            if (media.currentChapter == null) {
              snackBar(
                  "Error: Missing required media. It seems you closed the app directly after reading the chapter!",
                  maxLines: 3);
            } else {
              if (media.currentChapter?.sourceName == null) {
                snackBar("Cant Play since user closed the app abruptly");
              }
              final source = Get.find<SourceController>()
                  .getMangaExtensionByName(media.currentChapter!.sourceName!);
              if (source == null) {
                snackBar(
                    "Install ${media.currentChapter?.sourceName} First, Then Click");
              } else {
                navigate(() => ReadingPage(
                      anilistData: convertOfflineToMedia(media),
                      chapterList: media.chapters!,
                      currentChapter: media.currentChapter!,
                    ));
              }
            }
          }
        : () {
            if (media.currentEpisode == null ||
                media.currentEpisode?.currentTrack == null ||
                media.episodes == null ||
                media.currentEpisode?.videoTracks == null) {
              snackBar(
                "Error: Missing required media. It seems you closed the app directly after watching the episode!",
                duration: 2000,
                maxLines: 3,
              );
            } else {
              if (media.currentEpisode?.source == null) {
                snackBar("Cant Play since user closed the app abruptly");
              }
              final source = Get.find<SourceController>()
                  .getExtensionByName(media.currentEpisode!.source!);
              if (source == null) {
                snackBar(
                    "Install ${media.currentEpisode?.source} First, Then Click");
              } else {
                navigate(() => WatchPage(
                      episodeSrc: media.currentEpisode!.currentTrack!,
                      episodeList: media.episodes!,
                      anilistData: convertOfflineToMedia(media),
                      currentEpisode: media.currentEpisode!,
                      episodeTracks: media.currentEpisode!.videoTracks!,
                    ));
              }
            }
          };
    return HistoryModel(
        media: media,
        title: media.name,
        cover: media.currentEpisode?.thumbnail ?? media.cover ?? media.poster!,
        poster: media.poster!,
        formattedEpisodeTitle: formatEpChapTitle(
            isManga
                ? media.currentChapter?.number
                : media.currentEpisode?.number,
            isManga),
        sourceName: isManga
            ? media.currentChapter?.sourceName
            : media.currentEpisode?.source,
        progress: isManga
            ? media.currentChapter?.pageNumber
            : media.currentEpisode?.timeStampInMilliseconds,
        totalProgress: isManga
            ? media.currentChapter?.totalPages
            : media.currentEpisode?.durationInMilliseconds,
        progressTitle:
            isManga ? media.currentChapter?.title : media.currentEpisode?.title,
        isManga: isManga,
        calculatedProgress: isManga
            ? calculateProgress(media.currentChapter?.pageNumber,
                media.currentChapter?.totalPages)
            : calculateProgress(
                media.currentEpisode?.timeStampInMilliseconds,
                media.currentEpisode?.durationInMilliseconds,
              ),
        onTap: onTap,
        date: formattedDate(isManga
            ? media.currentChapter?.lastReadTime ?? 0
            : media.currentEpisode?.lastWatchedTime ?? 0),
        progressText: formatProgressText(media, isManga));
  }
  @override
  String toString() {
    return '''
HistoryModel(
  title: $title,
  cover: $cover,
  poster: $poster,
  sourceName: $sourceName,
  formattedEpisodeTitle: $formattedEpisodeTitle,
  progress: $progress,
  totalProgress: $totalProgress,
  progressTitle: $progressTitle,
  isManga: $isManga,
  calculatedProgress: $calculatedProgress,
  progressText: $progressText,
  date: $date
)
  ''';
  }
}

double calculateProgress(int? min, int? max) {
  if (min == null || max == null) {
    return 0.0;
  }

  return (min / max).clamp(0.0, 1.0);
}

String formatEpChapTitle(dynamic title, bool isManga) {
  final newTitle = title?.toString() ?? '??';
  return isManga ? 'Chapter $newTitle' : 'Episode $newTitle';
}

String formattedDate(int milliseconds) {
  return formatTimeAgo(milliseconds);
}

String formatProgressText(OfflineMedia data, bool isManga) {
  if (isManga) {
    return 'PAGE ${data.currentChapter?.pageNumber ?? '0'} / ${data.currentChapter?.totalPages ?? '??'}';
  } else {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:--';
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 0;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;
    final timeLeft = Duration(milliseconds: duration - timestamp);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(timeLeft.inSeconds.remainder(60));

    return '$minutes:$seconds left';
  }
}
