import 'dart:ui';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/story/story_controller.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/user_story.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/story/story_replies_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoryViewerPage extends StatefulWidget {
  final List<UserStory> stories;
  final int initialUserIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialUserIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentUserIndex;
  int _currentActivityIndex = 0;
  late AnimationController _progressController;
  bool _isPaused = false;
  final TextEditingController _quickReplyController = TextEditingController();

  UserStory get _currentStory => widget.stories[_currentUserIndex];
  AnilistActivity get _currentActivity =>
      _currentStory.activities[_currentActivityIndex];

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _pageController = PageController(initialPage: _currentUserIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener(_onProgressStatus);

    _startCurrentStory();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextActivity();
    }
  }

  void _startCurrentStory() {
    _progressController.stop();
    _progressController.reset();

    // Mark current activity as seen
    final story = _currentStory;
    if (_currentActivityIndex < story.activities.length) {
      final act = story.activities[_currentActivityIndex];
      Get.find<StoryController>().markStorySeen(story.userId, act.createdAt);
    }

    if (!_isPaused) {
      _progressController.forward();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  void _nextActivity() {
    if (_currentActivityIndex < _currentStory.activities.length - 1) {
      setState(() {
        _currentActivityIndex++;
      });
      _startCurrentStory();
    } else {
      // Go to next user story
      if (_currentUserIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _previousActivity() {
    if (_currentActivityIndex > 0) {
      setState(() {
        _currentActivityIndex--;
      });
      _startCurrentStory();
    } else {
      // Go to previous user story
      if (_currentUserIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _startCurrentStory();
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentActivityIndex = 0;
    });
    _startCurrentStory();
  }

  Future<void> _submitQuickReply() async {
    final text = _quickReplyController.text.trim();
    if (text.isEmpty) return;

    final anilistAuth = Get.find<AnilistAuth>();
    if (!anilistAuth.isLoggedIn.value) {
      Get.snackbar('Notice', 'Please log in to reply');
      return;
    }

    _pause();
    final storyController = Get.find<StoryController>();
    final success =
        await storyController.postReply(_currentActivity.id, text);

    if (mounted) {
      if (success) {
        _quickReplyController.clear();
        setState(() {
          _currentActivity.replyCount++;
        });
        Get.snackbar('Sent', 'Reply posted successfully');
      } else {
        Get.snackbar('Error', 'Failed to send reply');
      }
      _resume();
    }
  }

  void _openRepliesSheet() {
    _pause();
    StoryRepliesSheet.show(
      context,
      activity: _currentActivity,
      onReplyAdded: () {
        if (mounted) {
          setState(() {});
        }
      },
    ).then((_) {
      if (mounted) {
        _resume();
      }
    });
  }

  void _openMediaDetails() {
    final act = _currentActivity;
    if (act.mediaId == null) return;

    _pause();

    final isManga = act.type == 'MANGA_LIST';
    final media = Media(
      id: act.mediaId.toString(),
      title: act.mediaTitle ?? '',
      poster: act.mediaCoverUrl ?? '?',
      cover: act.mediaBannerUrl ?? act.mediaCoverUrl,
      serviceType: ServicesType.anilist,
    );

    if (isManga) {
      navigate(() => MangaDetailsPage(media: media, tag: act.mediaTitle ?? ''));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: act.mediaTitle ?? ''));
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _pageController.dispose();
    _quickReplyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // User Pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, userIdx) {
                return _buildStorySlide(context);
              },
            ),

            // Left / Right tap zones for navigation & Hold to pause
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousActivity,
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _nextActivity,
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                    ),
                  ),
                ],
              ),
            ),

            // Top Bar: Progress Bars + Header
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Progress Bars
                    _buildProgressBars(context),
                    const SizedBox(height: 12),

                    // User Header
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _currentStory.avatarUrl != null
                              ? AnymeXImage(
                                  imageUrl: _currentStory.avatarUrl!,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                )
                              : CircleAvatar(
                                  radius: 19,
                                  backgroundColor: colors.primaryContainer,
                                  child: Icon(Icons.person,
                                      size: 20, color: colors.primary),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnymeXText(
                              _currentStory.username,
                              variant: TextVariant.bold,
                              size: 14,
                              color: Colors.white,
                            ),
                            AnymeXText(
                              _currentActivity.timeAgo,
                              variant: TextVariant.regular,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: _buildBottomActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars(BuildContext context) {
    final colors = context.colors;
    final totalCount = _currentStory.activities.length;

    return Row(
      children: List.generate(totalCount, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                double progress = 0.0;
                if (index < _currentActivityIndex) {
                  progress = 1.0;
                } else if (index == _currentActivityIndex) {
                  progress = _progressController.value;
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnymeXContainer(
                    height: 3,
                    color: Colors.white.withOpacity(0.3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: AnymeXContainer(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                );

              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStorySlide(BuildContext context) {
    final act = _currentActivity;
    final colors = context.colors;
    final backdropUrl = act.mediaBannerUrl ?? act.mediaCoverUrl;

    return Stack(
      children: [
        // Backdrop Image with Blur
        if (backdropUrl != null && backdropUrl.isNotEmpty) ...[
          Positioned.fill(
            child: AnymeXImage(
              imageUrl: backdropUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: AnymeXContainer(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: AnymeXContainer(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.3),
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],


        // Center Content Card
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: act.type == 'TEXT' || act.type == 'MESSAGE'
                ? _buildTextContentCard(context, act)
                : _buildMediaContentCard(context, act),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContentCard(BuildContext context, AnilistActivity act) {
    final colors = context.colors;

    return AnymeXContainer(
      radius: 20,
      color: colors.surface.withOpacity(0.2),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poster
          if (act.mediaCoverUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnymeXImage(
                imageUrl: act.mediaCoverUrl!,
                width: 140,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),

          // Status Badge
          AnymeXContainer(
            radius: 30,
            color: colors.primary.withOpacity(0.25),
            border: Border.all(color: colors.primary, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: AnymeXText(
              act.displayText,
              variant: TextVariant.bold,
              size: 14,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Title
          if (act.mediaTitle != null)
            AnymeXText(
              act.mediaTitle!,
              variant: TextVariant.bold,
              size: 16,
              color: Colors.white,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),

          const SizedBox(height: 18),

          // Action Button
          AnymeXButton(
            onTap: _openMediaDetails,
            borderRadius: BorderRadius.circular(14),
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  act.type == 'MANGA_LIST'
                      ? Icons.menu_book_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                AnymeXText(
                  act.type == 'MANGA_LIST' ? 'Read Now' : 'Watch Now',
                  variant: TextVariant.bold,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContentCard(BuildContext context, AnilistActivity act) {
    final colors = context.colors;

    return AnymeXContainer(
      radius: 20,
      color: colors.surface.withOpacity(0.25),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 40,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          AnymeXText(
            act.displayText,
            variant: TextVariant.semiBold,
            size: 16,
            color: Colors.white,
            textAlign: TextAlign.center,
            maxLines: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final colors = context.colors;
    final act = _currentActivity;

    return AnymeXContainer(
      radius: 24,
      color: Colors.black.withOpacity(0.65),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Quick reply input
          Expanded(
            child: TextField(
              controller: _quickReplyController,
              onTap: _pause,
              onSubmitted: (_) => _submitQuickReply(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Reply to ${_currentStory.username}...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),

          // Send icon
          IconButton(
            icon: Icon(Icons.send_rounded, color: colors.primary, size: 20),
            onPressed: _submitQuickReply,
          ),

          // Like button
          GestureDetector(
            onTap: () async {
              final storyController = Get.find<StoryController>();
              await storyController.toggleLike(act);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    act.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: act.isLiked ? Colors.redAccent : Colors.white,
                    size: 24,
                  ),
                  if (act.likeCount > 0) ...[
                    const SizedBox(width: 4),
                    AnymeXText(
                      act.likeCount.toString(),
                      color: Colors.white,
                      variant: TextVariant.bold,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Replies sheet trigger
          GestureDetector(
            onTap: _openRepliesSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (act.replyCount > 0) ...[
                    const SizedBox(width: 4),
                    AnymeXText(
                      act.replyCount.toString(),
                      color: Colors.white,
                      variant: TextVariant.bold,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
