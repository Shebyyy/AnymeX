import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/story/story_controller.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoryRepliesSheet extends StatefulWidget {
  final AnilistActivity activity;
  final VoidCallback? onReplyAdded;

  const StoryRepliesSheet({
    super.key,
    required this.activity,
    this.onReplyAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required AnilistActivity activity,
    VoidCallback? onReplyAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryRepliesSheet(
        activity: activity,
        onReplyAdded: onReplyAdded,
      ),
    );
  }

  @override
  State<StoryRepliesSheet> createState() => _StoryRepliesSheetState();
}

class _StoryRepliesSheetState extends State<StoryRepliesSheet> {
  final TextEditingController _replyInput = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ActivityReply>? _replies;
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyInput.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    try {
      final storyController = Get.find<StoryController>();
      final fetched = await storyController.fetchReplies(widget.activity.id);
      if (mounted) {
        setState(() {
          _replies = fetched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReply() async {
    final text = _replyInput.text.trim();
    if (text.isEmpty || _isPosting) return;

    final anilistAuth = Get.find<AnilistAuth>();
    if (!anilistAuth.isLoggedIn.value) {
      Get.snackbar('Notice', 'Please log in to reply');
      return;
    }

    setState(() => _isPosting = true);
    final storyController = Get.find<StoryController>();
    final success = await storyController.postReply(widget.activity.id, text);

    if (mounted) {
      setState(() => _isPosting = false);
      if (success) {
        _replyInput.clear();
        widget.activity.replyCount++;
        widget.onReplyAdded?.call();
        await _loadReplies();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        Get.snackbar('Error', 'Failed to post reply. Please try again.');
      }
    }
  }

  Future<void> _toggleReplyLike(ActivityReply reply) async {
    final anilistAuth = Get.find<AnilistAuth>();
    if (!anilistAuth.isLoggedIn.value) {
      Get.snackbar('Notice', 'Please log in first');
      return;
    }

    setState(() {
      reply.isLiked = !reply.isLiked;
      reply.likeCount += reply.isLiked ? 1 : -1;
    });

    final success =
        await anilistAuth.toggleLike(reply.id, 'ACTIVITY_REPLY');
    if (!success && mounted) {
      setState(() {
        reply.isLiked = !reply.isLiked;
        reply.likeCount += reply.isLiked ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AnymeXContainer(
        height: sheetHeight,
        radius: 24,
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: colors.outline.withOpacity(0.2),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Drag handle
            AnymeXContainer(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              color: colors.onSurface.withOpacity(0.2),
              radius: 10,
            ),


            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnymeXText(
                  'Replies (${_replies?.length ?? widget.activity.replyCount})',
                  size: 16,
                  variant: TextVariant.bold,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            // Replies list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_replies == null || _replies!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: colors.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              AnymeXText(
                                'No replies yet',
                                size: 14,
                                color: colors.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(height: 4),
                              AnymeXText(
                                'Be the first to share your thoughts!',
                                size: 12,
                                color: colors.onSurface.withOpacity(0.4),
                              ),
                            ],
                          ),
                        )

                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: _replies!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reply = _replies![index];
                            return _buildReplyItem(context, reply);
                          },
                        ),
            ),

            const SizedBox(height: 8),

            // Composer bar
            AnymeXContainer(
              radius: 20,
              color: colors.secondaryContainer.opaque(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyInput,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitReply(),
                      decoration: InputDecoration(
                        hintText: 'Add a reply...',
                        hintStyle: TextStyle(
                          color: colors.onSurface.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: colors.primary,
                          ),
                          onPressed: _submitReply,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyItem(BuildContext context, ActivityReply reply) {
    final colors = context.colors;

    return AnymeXContainer(
      radius: 14,
      color: colors.secondaryContainer.opaque(0.25),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: reply.authorAvatarUrl != null
                ? AnymeXImage(
                    imageUrl: reply.authorAvatarUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(Icons.person, size: 20, color: colors.primary),
                  ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnymeXText(
                      reply.authorName ?? 'User',
                      size: 14,
                      variant: TextVariant.bold,
                    ),
                    const SizedBox(width: 8),
                    AnymeXText(
                      reply.timeAgo,
                      size: 12,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnymeXText(
                  reply.text.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                  size: 14,
                ),
              ],
            ),
          ),

          // Like button
          GestureDetector(
            onTap: () => _toggleReplyLike(reply),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    reply.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: reply.isLiked
                        ? Colors.redAccent
                        : colors.onSurface.withOpacity(0.5),
                  ),
                  if (reply.likeCount > 0) ...[
                    const SizedBox(height: 2),
                    AnymeXText(
                      reply.likeCount.toString(),
                      size: 12,
                      color: colors.onSurface.withOpacity(0.6),
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
