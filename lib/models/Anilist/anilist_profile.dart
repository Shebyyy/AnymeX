class Profile {
  String? id;
  String? name;
  String? userName;
  String? avatar;
  String? cover;
  String? about;
  String? aboutMarkdown;
  ProfileStatistics? stats;
  int? followers;
  int? following;
  DateTime? tokenExpiry;
  ProfileFavourites? favourites;
  List<ActivityHistory>? activityHistory;
  int? donatorTier;
  String? donatorBadge;
  bool? isFollowing;
  bool? isFollower;
  int? createdAt;
  bool splitCompletedAnime;
  bool splitCompletedManga;
  List<String> animeSectionOrder;
  List<String> mangaSectionOrder;

  Profile({
    this.id,
    this.name,
    this.userName,
    this.avatar,
    this.cover,
    this.about,
    this.aboutMarkdown,
    this.stats,
    this.followers,
    this.following,
    this.tokenExpiry,
    this.favourites,
    this.activityHistory,
    this.donatorTier,
    this.donatorBadge,
    this.isFollowing,
    this.isFollower,
    this.createdAt,
    this.splitCompletedAnime = false,
    this.splitCompletedManga = false,
    this.animeSectionOrder = const [],
    this.mangaSectionOrder = const [],
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString(),
      name: json['name'],
      avatar: json['avatar']?['large'],
      cover: json['bannerImage'],
      about: json['about'],
      aboutMarkdown: json['aboutMarkdown'] ?? json['aboutRaw'],
      stats: json['statistics'] != null
          ? ProfileStatistics.fromJson(json['statistics'])
          : null,
      followers: json['followers']?['pageInfo']?['total'] as int?,
      following: json['following']?['pageInfo']?['total'] as int?,
      favourites: json['favourites'] != null
          ? ProfileFavourites.fromJson(json['favourites'])
          : null,
      activityHistory: (json['stats']?['activityHistory'] as List<dynamic>?)
          ?.map((e) => ActivityHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      donatorTier: json['donatorTier'] as int?,
      donatorBadge: json['donatorBadge'] as String?,
      isFollowing: json['isFollowing'] as bool?,
      isFollower: json['isFollower'] as bool?,
      createdAt: json['createdAt'] as int?,
      splitCompletedAnime: json['mediaListOptions']?['animeList']
              ?['splitCompletedSectionByFormat'] as bool? ??
          false,
      splitCompletedManga: json['mediaListOptions']?['mangaList']
              ?['splitCompletedSectionByFormat'] as bool? ??
          false,
      animeSectionOrder: (json['mediaListOptions']?['animeList']
                  ?['sectionOrder'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      mangaSectionOrder: (json['mediaListOptions']?['mangaList']
                  ?['sectionOrder'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
    );
  }

  factory Profile.fromKitsu(Map<String, dynamic> json) {
    final jikanData = json['data'] as Map<String, dynamic>? ?? {};
    final animeStats = jikanData['statistics']?['anime'] as Map<String, dynamic>?;
    final mangaStats = jikanData['statistics']?['manga'] as Map<String, dynamic>?;

    DateTime? createdAt;
    final joinedAt = json['joined_at'] as String?;
    if (joinedAt != null) {
      try { createdAt = DateTime.parse(joinedAt); } catch (_) {}
    }

    ProfileFavourites? favourites;
    final favAnime = jikanData['favorites']?['anime'] as List<dynamic>?;
    final favManga = jikanData['favorites']?['manga'] as List<dynamic>?;
    final favCharacters = jikanData['favorites']?['characters'] as List<dynamic>?;
    final favPeople = jikanData['favorites']?['people'] as List<dynamic>?;

    if (favAnime != null || favManga != null || favCharacters != null || favPeople != null) {
      favourites = ProfileFavourites(
        anime: (favAnime ?? []).map((e) {
          final item = e as Map<String, dynamic>;
          return FavouriteMedia(
            id: (item['mal_id'] ?? item['url'])?.toString(),
            title: item['name'] as String?,
            cover: item['images']?['jpg']?['image_url'] as String? ??
                item['images']?['webp']?['image_url'] as String?,
            averageScore: (item['score'] as num?)?.toDouble(),
          );
        }).toList(),
        manga: (favManga ?? []).map((e) {
          final item = e as Map<String, dynamic>;
          return FavouriteMedia(
            id: (item['mal_id'] ?? item['url'])?.toString(),
            title: item['name'] as String?,
            cover: item['images']?['jpg']?['image_url'] as String? ??
                item['images']?['webp']?['image_url'] as String?,
            averageScore: (item['score'] as num?)?.toDouble(),
          );
        }).toList(),
        characters: (favCharacters ?? []).map((e) {
          final item = e as Map<String, dynamic>;
          return FavouriteCharacter(
            id: (item['mal_id'] ?? item['url'])?.toString(),
            name: item['name'] as String?,
            image: item['images']?['jpg']?['image_url'] as String? ??
                item['images']?['webp']?['image_url'] as String?,
          );
        }).toList(),
      );
    }

    final isSupporter = json['is_supporter'] as bool? ?? false;

    AnimeStats? animeStatObj;
    if (animeStats != null) {
      animeStatObj = AnimeStats(
        animeCount: animeStats['total_entries']?.toString(),
        episodesWatched: animeStats['episodes_watched']?.toString(),
        meanScore: animeStats['mean_score']?.toString(),
        minutesWatched: ((animeStats['days_watched'] as num?)?.toDouble() ?? 0) != 0
            ? ((animeStats['days_watched'] as num).toDouble() * 24 * 60).round().toString()
            : null,
      );
    }

    MangaStats? mangaStatObj;
    if (mangaStats != null) {
      mangaStatObj = MangaStats(
        mangaCount: mangaStats['total_entries']?.toString(),
        chaptersRead: mangaStats['chapters_read']?.toString(),
        volumesRead: mangaStats['volumes_read']?.toString(),
        meanScore: mangaStats['mean_score']?.toString(),
      );
    }

    return Profile(
      id: (json['id'] ?? jikanData['mal_id'])?.toString(),
      name: json['name'] ?? jikanData['username'],
      userName: json['name'] ?? jikanData['username'],
      avatar: json['picture'] ??
          jikanData['images']?['jpg']?['image_url'] ??
          jikanData['images']?['webp']?['image_url'],
      about: jikanData['about'],
      stats: ProfileStatistics(
        animeStats: animeStatObj,
        mangaStats: mangaStatObj,
      ),
      followers: jikanData['friends'] != null
          ? (jikanData['friends'] as List<dynamic>).length
          : null,
      following: null,
      favourites: favourites,
      createdAt: createdAt != null ? createdAt.millisecondsSinceEpoch ~/ 1000 : null,
      donatorBadge: isSupporter ? 'MAL Supporter' : 'MAL Member',
    );
  }
}

class ProfileFavourites {
  List<FavouriteMedia> anime;
  List<FavouriteMedia> manga;
  List<FavouriteCharacter> characters;
  List<FavouriteStaff> staff;
  List<FavouriteStudio> studios;

  ProfileFavourites({
    this.anime = const [],
    this.manga = const [],
    this.characters = const [],
    this.staff = const [],
    this.studios = const [],
  });

  factory ProfileFavourites.fromJson(Map<String, dynamic> json) {
    List<T> parseNodes<T>(
        dynamic data, T Function(Map<String, dynamic>) fromJson) {
      if (data == null) return [];
      final nodes = data['nodes'] as List<dynamic>?;
      if (nodes == null) return [];
      return nodes.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return ProfileFavourites(
      anime: parseNodes(json['anime'], FavouriteMedia.fromJson),
      manga: parseNodes(json['manga'], FavouriteMedia.fromJson),
      characters: parseNodes(json['characters'], FavouriteCharacter.fromJson),
      staff: parseNodes(json['staff'], FavouriteStaff.fromJson),
      studios: parseNodes(json['studios'], FavouriteStudio.fromJson),
    );
  }
}

class FavouriteMedia {
  String? id;
  String? title;
  String? cover;
  double? averageScore;
  int? episodes;

  FavouriteMedia(
      {this.id, this.title, this.cover, this.averageScore, this.episodes});

  factory FavouriteMedia.fromJson(Map<String, dynamic> json) {
    return FavouriteMedia(
      id: json['id']?.toString(),
      title: json['title']?['english'] ??
          json['title']?['romaji'] ??
          json['title']?['userPreferred'],
      cover: json['coverImage']?['large'],
      averageScore: json['averageScore'] != null
          ? (json['averageScore'] / 10).toDouble()
          : null,
      episodes: json['episodes'] ?? json['chapters'],
    );
  }
}

class FavouriteCharacter {
  String? id;
  String? name;
  String? image;

  FavouriteCharacter({this.id, this.name, this.image});

  factory FavouriteCharacter.fromJson(Map<String, dynamic> json) {
    return FavouriteCharacter(
      id: json['id']?.toString(),
      name: json['name']?['full'] ?? json['name']?['userPreferred'],
      image: json['image']?['large'],
    );
  }
}

class FavouriteStaff {
  String? id;
  String? name;
  String? image;

  FavouriteStaff({this.id, this.name, this.image});

  factory FavouriteStaff.fromJson(Map<String, dynamic> json) {
    return FavouriteStaff(
      id: json['id']?.toString(),
      name: json['name']?['full'] ?? json['name']?['userPreferred'],
      image: json['image']?['large'],
    );
  }
}

class FavouriteStudio {
  String? id;
  String? name;

  FavouriteStudio({this.id, this.name});

  factory FavouriteStudio.fromJson(Map<String, dynamic> json) {
    return FavouriteStudio(
      id: json['id']?.toString(),
      name: json['name'],
    );
  }
}

class ProfileStatistics {
  AnimeStats? animeStats;
  MangaStats? mangaStats;

  ProfileStatistics({this.animeStats, this.mangaStats});

  factory ProfileStatistics.fromJson(Map<String, dynamic> json) {
    return ProfileStatistics(
      animeStats:
          json['anime'] != null ? AnimeStats.fromJson(json['anime']) : null,
      mangaStats:
          json['manga'] != null ? MangaStats.fromJson(json['manga']) : null,
    );
  }

  factory ProfileStatistics.fromKitsu(Map<String, dynamic>? json) {
    return ProfileStatistics(
      animeStats:
          json?['anime'] != null ? AnimeStats.fromKitsu(json!['anime']) : null,
      mangaStats:
          json?['manga'] != null ? MangaStats.fromKitsu(json!['manga']) : null,
    );
  }
}

class AnimeStats {
  String? animeCount;
  String? episodesWatched;
  String? meanScore;
  String? minutesWatched;
  double? standardDeviation;
  List<ScoreStat> scores;
  List<TypeStat> formats;
  List<TypeStat> statuses;
  List<TypeStat> countries;
  List<LengthStat> lengths;
  List<YearStat> releaseYears;
  List<YearStat> startYears;
  List<GenreStat> genres;
  List<TagStat> tags;
  List<PersonStat> voiceActors;
  List<StudioStat> studios;
  List<PersonStat> staff;

  AnimeStats({
    this.animeCount,
    this.episodesWatched,
    this.meanScore,
    this.minutesWatched,
    this.standardDeviation,
    this.scores = const [],
    this.formats = const [],
    this.statuses = const [],
    this.countries = const [],
    this.lengths = const [],
    this.releaseYears = const [],
    this.startYears = const [],
    this.genres = const [],
    this.tags = const [],
    this.voiceActors = const [],
    this.studios = const [],
    this.staff = const [],
  });

  factory AnimeStats.fromJson(Map<String, dynamic> json) {
    return AnimeStats(
      animeCount: json['count']?.toString(),
      episodesWatched: json['episodesWatched']?.toString(),
      meanScore: json['meanScore']?.toString(),
      minutesWatched: json['minutesWatched']?.toString(),
      standardDeviation: (json['standardDeviation'] as num?)?.toDouble(),
      scores: _parseList(json['scores'], (e) => ScoreStat.fromJson(e)),
      formats:
          _parseList(json['formats'], (e) => TypeStat.fromJson(e, 'format')),
      statuses:
          _parseList(json['statuses'], (e) => TypeStat.fromJson(e, 'status')),
      countries:
          _parseList(json['countries'], (e) => TypeStat.fromJson(e, 'country')),
      lengths: _parseList(json['lengths'], (e) => LengthStat.fromJson(e)),
      releaseYears: _parseList(
          json['releaseYears'], (e) => YearStat.fromJson(e, 'releaseYear')),
      startYears: _parseList(
          json['startYears'], (e) => YearStat.fromJson(e, 'startYear')),
      genres: _parseList(json['genres'], (e) => GenreStat.fromJson(e)),
      tags: _parseList(json['tags'], (e) => TagStat.fromJson(e)),
      voiceActors: _parseList(
          json['voiceActors'], (e) => PersonStat.fromJson(e, 'voiceActor')),
      studios: _parseList(json['studios'], (e) => StudioStat.fromJson(e)),
      staff: _parseList(json['staff'], (e) => PersonStat.fromJson(e, 'staff')),
    );
  }

  factory AnimeStats.fromKitsu(Map<String, dynamic> json) {
    return AnimeStats(
        animeCount: json['total_entries']?.toString(),
        episodesWatched: json['episodes_watched']?.toString(),
        meanScore: json['mean_score']?.toString(),
        minutesWatched: '??');
  }
}

class MangaStats {
  String? mangaCount;
  String? chaptersRead;
  String? volumesRead;
  String? meanScore;
  double? standardDeviation;
  List<ScoreStat> scores;
  List<TypeStat> formats;
  List<TypeStat> statuses;
  List<TypeStat> countries;
  List<LengthStat> lengths;
  List<YearStat> releaseYears;
  List<YearStat> startYears;
  List<GenreStat> genres;
  List<TagStat> tags;
  List<PersonStat> staff;

  MangaStats({
    this.mangaCount,
    this.chaptersRead,
    this.volumesRead,
    this.meanScore,
    this.standardDeviation,
    this.scores = const [],
    this.formats = const [],
    this.statuses = const [],
    this.countries = const [],
    this.lengths = const [],
    this.releaseYears = const [],
    this.startYears = const [],
    this.genres = const [],
    this.tags = const [],
    this.staff = const [],
  });

  factory MangaStats.fromJson(Map<String, dynamic> json) {
    return MangaStats(
      mangaCount: json['count']?.toString(),
      chaptersRead: json['chaptersRead']?.toString(),
      volumesRead: json['volumesRead']?.toString(),
      meanScore: json['meanScore']?.toString(),
      standardDeviation: (json['standardDeviation'] as num?)?.toDouble(),
      scores: _parseList(json['scores'], (e) => ScoreStat.fromJson(e)),
      formats:
          _parseList(json['formats'], (e) => TypeStat.fromJson(e, 'format')),
      statuses:
          _parseList(json['statuses'], (e) => TypeStat.fromJson(e, 'status')),
      countries:
          _parseList(json['countries'], (e) => TypeStat.fromJson(e, 'country')),
      lengths: _parseList(json['lengths'], (e) => LengthStat.fromJson(e)),
      releaseYears: _parseList(
          json['releaseYears'], (e) => YearStat.fromJson(e, 'releaseYear')),
      startYears: _parseList(
          json['startYears'], (e) => YearStat.fromJson(e, 'startYear')),
      genres: _parseList(json['genres'], (e) => GenreStat.fromJson(e)),
      tags: _parseList(json['tags'], (e) => TagStat.fromJson(e)),
      staff: _parseList(json['staff'], (e) => PersonStat.fromJson(e, 'staff')),
    );
  }

  factory MangaStats.fromKitsu(Map<String, dynamic> json) {
    return MangaStats(
      mangaCount: json['total_entries']?.toString(),
      chaptersRead: json['chapters_read']?.toString(),
      volumesRead: json['volumes_read']?.toString(),
      meanScore: json['mean_score']?.toString(),
    );
  }
}


List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data == null) return [];
  return (data as List<dynamic>)
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
}

class ScoreStat {
  final int score;
  final int count;
  final double meanScore;
  final int amount;

  ScoreStat({
    required this.score,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory ScoreStat.fromJson(Map<String, dynamic> json) => ScoreStat(
        score: json['score'] as int? ?? 0,
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class TypeStat {
  final String type;
  final int count;
  final double meanScore;
  final int amount;

  TypeStat({
    required this.type,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory TypeStat.fromJson(Map<String, dynamic> json, String key) => TypeStat(
        type: (json[key] as String?) ?? 'Unknown',
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class LengthStat {
  final String length;
  final int count;
  final double meanScore;
  final int amount;

  LengthStat({
    required this.length,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory LengthStat.fromJson(Map<String, dynamic> json) => LengthStat(
        length: (json['length'] as String?) ?? '?',
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class YearStat {
  final int year;
  final int count;
  final double meanScore;
  final int amount;

  YearStat({
    required this.year,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory YearStat.fromJson(Map<String, dynamic> json, String key) => YearStat(
        year: json[key] as int? ?? 0,
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class GenreStat {
  final String genre;
  final int count;
  final double meanScore;
  final int amount;

  GenreStat({
    required this.genre,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory GenreStat.fromJson(Map<String, dynamic> json) => GenreStat(
        genre: (json['genre'] as String?) ?? 'Unknown',
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class TagStat {
  final String tag;
  final int count;
  final double meanScore;
  final int amount;

  TagStat({
    required this.tag,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory TagStat.fromJson(Map<String, dynamic> json) => TagStat(
        tag: (json['tag']?['name'] as String?) ?? 'Unknown',
        count: json['count'] as int? ?? 0,
        meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
        amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
      );
}

class PersonStat {
  final String? id;
  final String name;
  final String? image;
  final int count;
  final double meanScore;
  final int amount;

  PersonStat({
    this.id,
    required this.name,
    this.image,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory PersonStat.fromJson(Map<String, dynamic> json, String key) {
    final person = json[key] as Map<String, dynamic>?;
    return PersonStat(
      id: person?['id']?.toString(),
      name: person?['name']?['full'] as String? ?? 'Unknown',
      image: person?['image']?['medium'] as String?,
      count: json['count'] as int? ?? 0,
      meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
      amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
    );
  }
}

class StudioStat {
  final String? id;
  final String name;
  final int count;
  final double meanScore;
  final int amount;

  StudioStat({
    this.id,
    required this.name,
    required this.count,
    required this.meanScore,
    required this.amount,
  });

  factory StudioStat.fromJson(Map<String, dynamic> json) {
    final studio = json['studio'] as Map<String, dynamic>?;
    return StudioStat(
      id: studio?['id']?.toString(),
      name: studio?['name'] as String? ?? 'Unknown',
      count: json['count'] as int? ?? 0,
      meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
      amount: (json['minutesWatched'] ?? json['chaptersRead']) as int? ?? 0,
    );
  }
}

class ActivityHistory {
  final int date;
  final int amount;
  final int level;

  ActivityHistory({
    required this.date,
    required this.amount,
    required this.level,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      date: json['date'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      level: json['level'] as int? ?? 0,
    );
  }
}
