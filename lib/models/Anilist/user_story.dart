import 'package:anymex/models/Anilist/anilist_activity.dart';

class UserStory {
  final int userId;
  final String username;
  final String? avatarUrl;
  final String? bannerUrl;
  final List<AnilistActivity> activities;
  final bool isCurrentUser;

  UserStory({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bannerUrl,
    required this.activities,
    this.isCurrentUser = false,
  });

  int get lastActivityTime {
    if (activities.isEmpty) return 0;
    return activities.first.createdAt;
  }

  bool hasUnseen(int lastSeenTimestamp) {
    if (activities.isEmpty) return false;
    return lastActivityTime > lastSeenTimestamp;
  }

  int get storyCount => activities.length;

  AnilistActivity get latestActivity => activities.first;
}
