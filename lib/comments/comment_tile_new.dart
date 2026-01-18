import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/custom_widgets/custom_text.dart';
import '../widgets/custom_widgets/anymex_container.dart';
import '../widgets/custom_widgets/anymex_button.dart';
import 'comment_models_new.dart';
import 'comments_controller_new.dart';
import 'user_role_controller_new.dart';

class CommentTileNew extends StatelessWidget {
  final Comment comment;
  final int depth;
  final bool isLastReply;
  final VoidCallback? onReply;
  final VoidCallback? onVote;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onLock;
  final VoidCallback? onUserTap;
  final bool showReplies;

  const CommentTileNew({
    super.key,
    required this.comment,
    this.depth = 0,
    this.isLastReply = false,
    this.onReply,
    this.onVote,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onLock,
    this.onUserTap,
    this.showReplies = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleController = Get.find<UserRoleController>();
    
    final isOwnComment = userRoleController.currentUser?.id == comment.user.id;
    final canModerate = userRoleController.isModerator;
    final canEdit = userRoleController.canEditComment(comment);
    final canDelete = userRoleController.canDeleteComment(comment);

    return Column(
      children: [
        _buildComment(context, colorScheme, isOwnComment, canModerate, canEdit, canDelete),
        if (showReplies && comment.replies.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildReplies(context, colorScheme),
        ],
      ],
    );
  }

  Widget _buildComment(
    BuildContext context,
    ColorScheme colorScheme,
    bool isOwnComment,
    bool canModerate,
    bool canEdit,
    bool canDelete,
  ) {
    return Container(
      margin: EdgeInsets.only(
        left: depth == 0 ? 0.0 : depth * 16.0,
        right: 8.0,
        bottom: isLastReply ? 0.0 : 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned indicator
          if (comment.isPinned) _buildPinnedIndicator(colorScheme),
          
          // Comment header
          _buildCommentHeader(context, colorScheme),
          
          const SizedBox(height: 8),
          
          // Comment content
          _buildCommentContent(context, colorScheme),
          
          const SizedBox(height: 8),
          
          // Comment actions
          _buildCommentActions(
            context,
            colorScheme,
            isOwnComment,
            canModerate,
            canEdit,
            canDelete,
          ),
          
          // Reply input (if replying to this comment)
          _buildReplyInput(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPinnedIndicator(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Pinned',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User avatar
        GestureDetector(
          onTap: onUserTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainer,
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: comment.user.avatarUrl?.isNotEmpty == true
                  ? Image.network(
                      comment.user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Username and role
        Expanded(
          child: GestureDetector(
            onTap: onUserTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.username,
                      style: TextStyle(
                        color: comment.user.isBanned 
                            ? colorScheme.onSurface.withOpacity(0.5)
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: comment.user.isBanned 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    if (comment.user.role != UserRole.normalUser) ...[
                      const SizedBox(width: 6),
                      _buildRoleBadge(colorScheme),
                    ],
                    if (comment.user.isBanned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Banned',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt, locale: 'en'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(
                        '• edited',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    if (comment.isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // More options
        if (canEdit || canDelete || canModerate)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (canEdit)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              if (canDelete)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              if (canModerate && !comment.isPinned)
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Pin'),
                    ],
                  ),
                ),
              if (canModerate && comment.isPinned)
                PopupMenuItem(
                  value: 'unpin',
                  child: Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Unpin'),
                    ],
                  ),
                ),
              if (canModerate && !comment.isLocked)
                PopupMenuItem(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Lock'),
                    ],
                  ),
                ),
              if (canModerate && comment.isLocked)
                PopupMenuItem(
                  value: 'unlock',
                  child: Row(
                    children: [
                      Icon(Icons.lock_open_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Unlock'),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRoleBadge(ColorScheme colorScheme) {
    Color badgeColor;
    String badgeText;
    
    switch (comment.user.role) {
      case UserRole.superAdmin:
        badgeColor = Colors.red;
        badgeText = 'Super Admin';
        break;
      case UserRole.admin:
        badgeColor = Colors.orange;
        badgeText = 'Admin';
        break;
      case UserRole.moderator:
        badgeColor = Colors.green;
        badgeText = 'Mod';
        break;
      case UserRole.normalUser:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCommentContent(BuildContext context, ColorScheme colorScheme) {
    if (comment.isDeleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '[deleted]',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags
        if (comment.tags.isNotEmpty) _buildCommentTags(colorScheme),
        
        // Content
        Text(
          comment.content,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentTags(ColorScheme colorScheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: comment.tags.map((tag) {
        Color tagColor;
        switch (tag.tagType) {
          case CommentTagType.spoiler:
            tagColor = Colors.purple;
            break;
          case CommentTagType.nsfw:
            tagColor = Colors.red;
            break;
          case CommentTagType.warning:
            tagColor = Colors.orange;
            break;
          case CommentTagType.offensive:
            tagColor = Colors.red.shade700;
            break;
          case CommentTagType.spam:
            tagColor = Colors.grey;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: tagColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag.tagType.displayName,
            style: TextStyle(
              color: tagColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentActions(
    BuildContext context,
    ColorScheme colorScheme,
    bool isOwnComment,
    bool canModerate,
    bool canEdit,
    bool canDelete,
  ) {
    return Row(
      children: [
        // Upvote
        _buildVoteButton(
          colorScheme,
          Icons.arrow_upward_rounded,
          comment.upvotes,
          comment.userVote == 1,
          () => onVote?.call(),
        ),
        
        const SizedBox(width: 4),
        
        // Downvote
        _buildVoteButton(
          colorScheme,
          Icons.arrow_downward_rounded,
          comment.downvotes,
          comment.userVote == -1,
          () => onVote?.call(),
        ),
        
        const SizedBox(width: 16),
        
        // Reply
        if (comment.canReply)
          _buildActionButton(
            colorScheme,
            Icons.reply_rounded,
            'Reply',
            () => onReply?.call(),
          ),
        
        // Reply count
        if (comment.replyCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '${comment.replyCount}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        
        const Spacer(),
        
        // Share
        _buildActionButton(
          colorScheme,
          Icons.share_rounded,
          null,
          () => _shareComment(context),
        ),
      ],
    );
  }

  Widget _buildVoteButton(
    ColorScheme colorScheme,
    IconData icon,
    int count,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive 
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
              style: TextStyle(
                color: isActive 
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ColorScheme colorScheme,
    IconData icon,
    String? text,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            if (text != null) ...[
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(BuildContext context, ColorScheme colorScheme) {
    final controller = Get.find<CommentsControllerNew>();
    
    return Obx(() {
      if (controller.replyingToCommentId != comment.id) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Replying to ${comment.user.username}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: controller.cancelReply,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.replyController,
              focusNode: controller.replyFocusNode,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.cancelReply,
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: controller.isPostingComment
                      ? null
                      : () => controller.postComment(
                          controller.replyController.text,
                          parentId: comment.id,
                        ),
                  child: controller.isPostingComment
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReplies(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: comment.replies.asMap().entries.map((entry) {
        final index = entry.key;
        final reply = entry.value;
        final isLast = index == comment.replies.length - 1;
        
        return CommentTileNew(
          comment: reply,
          depth: depth + 1,
          isLastReply: isLast,
          onReply: () => _handleReply(reply),
          onVote: () => _handleVote(reply),
          onEdit: () => _handleEdit(reply),
          onDelete: () => _handleDelete(reply),
          onUserTap: () => _handleUserTap(reply.user),
          showReplies: false, // Don't show nested replies for now
        );
      }).toList(),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
      case 'pin':
        onPin?.call();
        break;
      case 'unpin':
        onPin?.call();
        break;
      case 'lock':
        onLock?.call();
        break;
      case 'unlock':
        onLock?.call();
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareComment(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _handleReply(Comment reply) {
    onReply?.call();
  }

  void _handleVote(Comment reply) {
    onVote?.call();
  }

  void _handleEdit(Comment reply) {
    onEdit?.call();
  }

  void _handleDelete(Comment reply) {
    onDelete?.call();
  }

  void _handleUserTap(CommentUser user) {
    onUserTap?.call();
  }
}