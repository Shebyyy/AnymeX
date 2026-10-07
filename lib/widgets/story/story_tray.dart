import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/story/story_controller.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/story/story_viewer_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/story/story_avatar_ring.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/controllers/settings/settings.dart';

class StoryTray extends StatelessWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context) {
    final anilistAuth = Get.find<AnilistAuth>();
    final storyController = Get.find<StoryController>();

    return Obx(() {
      if (!settingsController.enableStories.value ||
          !anilistAuth.isLoggedIn.value) {
        return const SizedBox.shrink();
      }

      if (storyController.isLoading.value && storyController.stories.isEmpty) {
        return _buildShimmerTray(context);
      }

      final myStory = storyController.myStory.value;
      final stories = storyController.stories;

      if (stories.isEmpty && myStory == null) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 106,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildMyStoryItem(context, myStory);
            }

            final storyIndex = index - 1;
            final story = stories[storyIndex];
            final isUnseen = storyController.isStoryUnseen(story);

            return Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: GestureDetector(
                onTap: () {
                  navigate(
                    () => StoryViewerPage(
                      stories: stories,
                      initialUserIndex: storyIndex,
                    ),
                  );
                },
                child: SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StoryAvatarRing(
                        avatarUrl: story.avatarUrl,
                        radius: 26,
                        hasUnseen: isUnseen,
                      ),
                      const SizedBox(height: 6),
                      AnymeXText(
                        story.username,
                        size: 12,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildMyStoryItem(BuildContext context, dynamic myStory) {
    final serviceHandler = Get.find<ServiceHandler>();
    final profile = serviceHandler.profileData.value;
    final hasStories = myStory != null && myStory.activities.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () {
          if (hasStories) {
            navigate(
              () => StoryViewerPage(
                stories: [myStory],
                initialUserIndex: 0,
              ),
            );
          } else {
            navigate(() => const ProfilePage());
          }
        },
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StoryAvatarRing(
                avatarUrl: profile.avatar,
                radius: 26,
                isCurrentUser: true,
                showAddBadge: !hasStories,
                hasUnseen: hasStories,
              ),
              const SizedBox(height: 6),
              const AnymeXText(
                'Your Story',
                size: 12,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerTray(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 106,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, _) {
          return Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: SizedBox(
              width: 68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.secondaryContainer.opaque(0.3),
                  ),
                  const SizedBox(height: 8),
                  AnymeXContainer(
                    width: 48,
                    height: 10,
                    radius: 5,
                    color: colors.secondaryContainer.opaque(0.3),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
