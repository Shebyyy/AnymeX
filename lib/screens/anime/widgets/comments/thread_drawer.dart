import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThreadDrawer extends StatefulWidget {
  final Comment rootComment;
  final CommentSectionController controller;
  final List<Comment> parentChain;

  const ThreadDrawer({
    super.key,
    required this.rootComment,
    required this.controller,
    required this.parentChain,
  });

  @override
  State<ThreadDrawer> createState() => _ThreadDrawerState();
}

class _ThreadDrawerState extends State<ThreadDrawer> {
  final Map<String, TextEditingController> _replyControllers = {};
  late TextEditingController _drawerReplyController;

  @override
  void initState() {
    super.initState();
    _drawerReplyController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    _replyControllers.clear();
    _drawerReplyController.dispose();
    super.dispose();
  }

  TextEditingController _getReplyController(String commentId) {
    return _replyControllers.putIfAbsent(
        commentId, () => TextEditingController());
  }

  int _countReplies(Comment comment) {
    int count = 0;
    if (comment.replies != null) {
      count += comment.replies!.length;
      for (final reply in comment.replies!) {
        count += _countReplies(reply);
      }
    }
    return count;
  }

  List<Comment> _flattenThread(Comment root) {
    final List<Comment> flat = [];
    void traverse(Comment c) {
      flat.add(c);
      if (c.replies != null) {
        for (final reply in c.replies!) {
          traverse(reply);
        }
      }
    }
    traverse(root);
    return flat;
  }

  Comment? _findParent(Comment child, List<Comment> flat) {
    for (final c in flat) {
      if (c.replies?.any((r) => r.id == child.id) ?? false) {
        return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flatComments = _flattenThread(widget.rootComment);
    final totalReplies = _countReplies(widget.rootComment);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.opaque(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.forum_rounded,
                        size: 22, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thread',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$totalReplies ${totalReplies == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          size: 24, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.parentChain.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow.opaque(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.opaque(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thread path',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            for (int i = 0; i < widget.parentChain.length; i++) ...[
                              Text(
                                widget.parentChain[i].username,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (i < widget.parentChain.length - 1)
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: colorScheme.onSurfaceVariant),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Divider(
                  color: colorScheme.outlineVariant.opaque(0.3),
                  height: 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: flatComments.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.opaque(0.12),
                ),
              ),
              itemBuilder: (context, index) {
                final comment = flatComments[index];
                final parent = _findParent(comment, flatComments);
                return _buildDrawerCommentItem(
                    context, comment, parent, widget.controller);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.opaque(0.3),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.opaque(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest.opaque(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.opaque(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _drawerReplyController,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Reply to thread...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.opaque(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => FilledButton.tonal(
                        onPressed: widget.controller.isSubmitting.value ||
                                _drawerReplyController.text.trim().isEmpty
                            ? null
                            : () {
                                widget.controller.addReply(
                                    widget.rootComment, _drawerReplyController.text.trim());
                                _drawerReplyController.clear();
                                Navigator.pop(context);
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: widget.controller.isSubmitting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: ExpressiveLoadingIndicator(),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCommentItem(BuildContext context, Comment comment,
      Comment? parentComment, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');
    final isOwnComment = comment.userId == controller.profile.id?.toString();
    final canModerate = controller.canModerate();

    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parentComment != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.opaque(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.primary.opaque(0.5),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '@${parentComment.username}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parentComment.commentText.length > 80
                            ? '${parentComment.commentText.substring(0, 80)}...'
                            : parentComment.commentText,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final currentUserId =
                        Get.find<ServiceHandler>().profileData.value.id;
                    if (comment.userId == currentUserId) {
                      navigate(() => const ProfilePage());
                    } else {
                      navigate(() => UserProfilePage(
                          userId: int.tryParse(comment.userId) ?? 0));
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainer,
                      border: Border.all(
                        color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: comment.avatarUrl?.isNotEmpty == true
                          ? AnymeXImage(
                              imageUrl: comment.avatarUrl!,
                              fit: BoxFit.cover,
                              radius: 0,
                            )
                          : Icon(Icons.person_rounded,
                              size: 18, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: comment.username,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (comment.userRole != null &&
                                      comment.userRole != 'user')
                                    WidgetSpan(
                                      child: _buildRoleBadge(
                                          context, comment.userRole!),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (comment.tag.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildDrawerTag(context, comment.tag),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            timeago.format(DateTime.parse(comment.createdAt)),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (comment.edited == true) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(edited)',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.opaque(0.6),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (comment.pinned == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.push_pin_rounded,
                                size: 13, color: colorScheme.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DrawerSpoilerText(
                        text: comment.commentText,
                        isSpoiler: isSpoiler,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildDrawerVoteButton(
                            colorScheme: colorScheme,
                            icon: Icons.keyboard_arrow_up_rounded,
                            count: comment.likes,
                            isActive: comment.userVote == 1,
                            onTap: () => controller.handleVote(comment, 1),
                            isUpvote: true,
                          ),
                          const SizedBox(width: 12),
                          _buildDrawerVoteButton(
                            colorScheme: colorScheme,
                            icon: Icons.keyboard_arrow_down_rounded,
                            count: comment.dislikes,
                            isActive: comment.userVote == -1,
                            onTap: () => controller.handleVote(comment, -1),
                            isUpvote: false,
                          ),
                          if (comment.locked != true) ...[
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => controller.toggleReply(comment.id),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer
                                      .opaque(0.3, iReallyMeanIt: true),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.reply_rounded,
                                    size: 18, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _buildDrawerCommentMenu(context, comment, controller,
                              isOwnComment, canModerate),
                        ],
                      ),
                      if (controller.isReplyingTo(comment.id) &&
                          comment.locked != true) ...[
                        const SizedBox(height: 8),
                        _buildDrawerReplyInput(context, comment, controller),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildDrawerReplyInput(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final replyController = _getReplyController(comment.id);

    return StatefulBuilder(
      builder: (context, setReplyState) {
        final hasText = replyController.text.trim().isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest.opaque(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.reply_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to ${comment.username}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      controller.toggleReply(comment.id);
                      replyController.clear();
                    },
                    child: Icon(Icons.close_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: replyController,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (_) => setReplyState(() {}),
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.opaque(0.5),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.opaque(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.opaque(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary.opaque(0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(() => FilledButton.tonal(
                        onPressed: controller.isSubmitting.value || !hasText
                            ? null
                            : () {
                                controller.addReply(
                                    comment, replyController.text.trim());
                                replyController.clear();
                                setReplyState(() {});
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: ExpressiveLoadingIndicator(),
                              )
                            : const Text(
                                'Reply',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerVoteButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required bool isUpvote,
  }) {
    final activeColor = isUpvote ? colorScheme.primary : colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.opaque(0.1, iReallyMeanIt: true)
                : colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? activeColor.opaque(0.3, iReallyMeanIt: true)
                  : colorScheme.outlineVariant.opaque(0.2, iReallyMeanIt: true),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? activeColor : colorScheme.onSurfaceVariant,
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count > 999
                      ? '${(count / 1000).toStringAsFixed(1)}k'
                      : '$count',
                  style: TextStyle(
                    color: isActive ? activeColor : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerCommentMenu(BuildContext context, Comment comment,
      CommentSectionController controller, bool isOwnComment, bool canModerate) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'copy':
            Clipboard.setData(ClipboardData(text: comment.commentText));
            snackBar('Comment copied to clipboard');
            break;
          case 'edit':
            Navigator.pop(context);
            _showEditDialog(context, comment, controller);
            break;
          case 'delete':
            Navigator.pop(context);
            controller.deleteComment(comment);
            break;
          case 'report':
            Navigator.pop(context);
            _showReportDialog(context, comment, controller);
            break;
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('Copy', style: TextStyle(color: colorScheme.onSurface, fontSize: 14)),
            ],
          ),
        ),
        if (isOwnComment) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'edit',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text('Edit', style: TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: colorScheme.error, fontSize: 14)),
              ],
            ),
          ),
        ],
        if (!isOwnComment) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'report',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text('Report', style: TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final emoji = switch (role) {
      'super_admin' => '👑',
      'admin' => '🛡️',
      'moderator' => '⚙️',
      'owner' => '💎',
      _ => null,
    };

    if (emoji == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(emoji, style: const TextStyle(fontSize: 14, height: 1)),
    );
  }

  Widget _buildDrawerTag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;

    Color tagColor = colorScheme.primary;
    if (tag.toLowerCase().contains('spoiler')) {
      tagColor = Colors.red;
    } else if (tag.toLowerCase().contains('theory')) {
      tagColor = Colors.orange;
    } else if (tag.toLowerCase().contains('review')) {
      tagColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tagColor.withOpacity(0.2), width: 1),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: tagColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController editController =
        TextEditingController(text: comment.commentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.editComment(comment, editController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Please select a reason for reporting this comment:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: reasonController.text.isEmpty
                  ? null
                  : reasonController.text,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(
                    value: 'offensive', child: Text('Offensive')),
                DropdownMenuItem(
                    value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(
                    value: 'spoiler', child: Text('Spoiler')),
                DropdownMenuItem(value: 'nsfw', child: Text('NSFW')),
                DropdownMenuItem(
                    value: 'off_topic', child: Text('Off-Topic')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                reasonController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.reportComment(comment, reasonController.text.trim(),
                    notes: notesController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

class _DrawerSpoilerText extends StatefulWidget {
  final String text;
  final bool isSpoiler;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _DrawerSpoilerText({
    required this.text,
    required this.isSpoiler,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_DrawerSpoilerText> createState() => _DrawerSpoilerTextState();
}

class _DrawerSpoilerTextState extends State<_DrawerSpoilerText> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler) {
      return SelectableText(
        widget.text,
        style: TextStyle(
          color: widget.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          height: 1.5,
          fontSize: 15,
        ),
      );
    }

    if (_isRevealed) {
      return SelectableText(
        widget.text,
        style: TextStyle(
          color: widget.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          height: 1.5,
          fontSize: 15,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isRevealed = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              widget.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.colorScheme.outlineVariant.opaque(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16, color: widget.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Spoiler — tap to reveal',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
