class DubRelease {
  final String animeTitle;
  final String episode;
  final DateTime releaseTime;
  final List<String> licensedSites;

  DubRelease({
    required this.animeTitle,
    required this.episode,
    required this.releaseTime,
    required this.licensedSites,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DubRelease &&
          runtimeType == other.runtimeType &&
          animeTitle == other.animeTitle &&
          episode == other.episode;

  @override
  int hashCode => animeTitle.hashCode ^ episode.hashCode;
}
