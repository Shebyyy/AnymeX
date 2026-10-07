import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/user_story.dart';
import 'package:get/get.dart';

class StoryController extends GetxController {
  final RxList<UserStory> stories = <UserStory>[].obs;
  final Rx<UserStory?> myStory = Rx<UserStory?>(null);
  final RxBool isLoading = false.obs;
  final RxMap<int, int> lastSeenTimestamps = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLastSeen();

    // Auto-fetch when logged in
    final anilistAuth = Get.find<AnilistAuth>();
    ever(anilistAuth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchStories();
      } else {
        stories.clear();
        myStory.value = null;
      }
    });

    if (anilistAuth.isLoggedIn.value) {
      fetchStories();
    }
  }

  void _loadLastSeen() {
    try {
      final storedMap = StoryKeys.lastSeenMap.get<Map<String, dynamic>>({});
      final Map<int, int> parsed = {};
      for (final entry in storedMap.entries) {
        final uid = int.tryParse(entry.key);
        final ts = entry.value is int
            ? entry.value as int
            : int.tryParse(entry.value.toString());
        if (uid != null && ts != null) {
          parsed[uid] = ts;
        }
      }
      lastSeenTimestamps.assignAll(parsed);
    } catch (_) {}
  }


  void _saveLastSeen() {
    try {
      final saveMap = <String, dynamic>{};
      for (final e in lastSeenTimestamps.entries) {
        saveMap[e.key.toString()] = e.value;
      }
      StoryKeys.lastSeenMap.set(saveMap);
    } catch (_) {}
  }

  bool isStoryUnseen(UserStory story) {
    final lastSeen = lastSeenTimestamps[story.userId] ?? 0;
    return story.hasUnseen(lastSeen);
  }

  Future<void> fetchStories({bool refresh = false}) async {
    final anilistAuth = Get.find<AnilistAuth>();
    if (!anilistAuth.isLoggedIn.value) return;

    if (stories.isEmpty || refresh) {
      isLoading.value = true;
    }

    try {
      // 1. Fetch current user's own activities for "Your Story"
      final serviceHandler = Get.find<ServiceHandler>();
      final myIdStr = serviceHandler.profileData.value.id;
      final myId = myIdStr != null ? int.tryParse(myIdStr) : null;

      if (myId != null) {
        final (myActivities, _) =
            await anilistAuth.fetchUserActivities(myId, page: 1);
        if (myActivities.isNotEmpty) {
          final profile = serviceHandler.profileData.value;
          myStory.value = UserStory(
            userId: myId,
            username: profile.name ?? 'You',
            avatarUrl: profile.avatar,
            bannerUrl: profile.cover,
            activities: myActivities.take(5).toList(),
            isCurrentUser: true,
          );
        } else {
          myStory.value = null;
        }
      }

      // 2. Fetch following activities (up to 50 items)
      final (followingActivities, _) =
          await anilistAuth.fetchFollowingActivities(page: 1, perPage: 50);

      // Group activities by user
      final Map<int, List<AnilistActivity>> grouped = {};
      final Map<int, AnilistActivity> userFirstSeen = {};

      for (final act in followingActivities) {
        final uid = act.authorId;
        if (uid == null || uid == myId) continue;

        grouped.putIfAbsent(uid, () => []);
        if (grouped[uid]!.length < 5) {
          grouped[uid]!.add(act);
        }
        userFirstSeen.putIfAbsent(uid, () => act);
      }

      final List<UserStory> result = [];
      for (final entry in grouped.entries) {
        final uid = entry.key;
        final acts = entry.value;
        if (acts.isEmpty) continue;

        final firstAct = userFirstSeen[uid]!;
        result.add(UserStory(
          userId: uid,
          username: firstAct.authorName ?? 'User',
          avatarUrl: firstAct.authorAvatarUrl,
          bannerUrl: null,
          activities: acts,
          isCurrentUser: false,
        ));
      }

      // Sort: Unseen stories first (ordered by lastActivityTime DESC), then Seen stories
      _sortStoriesList(result);
      stories.assignAll(result);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _sortStoriesList(List<UserStory> list) {
    list.sort((a, b) {
      final aUnseen = isStoryUnseen(a);
      final bUnseen = isStoryUnseen(b);

      if (aUnseen && !bUnseen) return -1;
      if (!aUnseen && bUnseen) return 1;

      return b.lastActivityTime.compareTo(a.lastActivityTime);
    });
  }

  void markStorySeen(int userId, int timestamp) {
    final currentSeen = lastSeenTimestamps[userId] ?? 0;
    if (timestamp > currentSeen) {
      lastSeenTimestamps[userId] = timestamp;
      _saveLastSeen();

      // Re-sort stories
      final currentList = stories.toList();
      _sortStoriesList(currentList);
      stories.assignAll(currentList);
    }
  }

  Future<bool> toggleLike(AnilistActivity activity) async {
    final anilistAuth = Get.find<AnilistAuth>();
    if (!anilistAuth.isLoggedIn.value) return false;

    // Optimistic update
    final wasLiked = activity.isLiked;
    final prevCount = activity.likeCount;
    activity.isLiked = !wasLiked;
    activity.likeCount =
        wasLiked ? (prevCount - 1).clamp(0, 999999) : prevCount + 1;
    stories.refresh();
    if (myStory.value != null) myStory.refresh();

    final success = await anilistAuth.toggleLike(activity.id, activity.type);
    if (!success) {
      // Revert
      activity.isLiked = wasLiked;
      activity.likeCount = prevCount;
      stories.refresh();
      if (myStory.value != null) myStory.refresh();
      return false;
    }
    return true;
  }

  Future<bool> postReply(int activityId, String text) async {
    final anilistAuth = Get.find<AnilistAuth>();
    return await anilistAuth.postActivityReply(activityId, text);
  }

  Future<List<ActivityReply>> fetchReplies(int activityId) async {
    final anilistAuth = Get.find<AnilistAuth>();
    return await anilistAuth.fetchActivityReplies(activityId);
  }

  UserStory? getStoryForUser(int userId) {
    if (myStory.value?.userId == userId) return myStory.value;
    return stories.firstWhereOrNull((s) => s.userId == userId);
  }

  Future<UserStory?> fetchStoryForUser(
    int userId, {
    String? username,
    String? avatarUrl,
  }) async {
    final existing = getStoryForUser(userId);
    if (existing != null) return existing;

    final anilistAuth = Get.find<AnilistAuth>();
    final (activities, _) =
        await anilistAuth.fetchUserActivities(userId, page: 1);
    if (activities.isEmpty) return null;

    final newStory = UserStory(
      userId: userId,
      username: username ?? activities.first.authorName ?? 'User',
      avatarUrl: avatarUrl ?? activities.first.authorAvatarUrl,
      activities: activities.take(5).toList(),
    );
    return newStory;
  }
}
