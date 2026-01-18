import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_widgets/anymex_progress.dart';
import '../widgets/custom_widgets/custom_text.dart';
import '../widgets/custom_widgets/anymex_container.dart';
import '../widgets/custom_widgets/anymex_button.dart';
import '../widgets/common/glow.dart';
import '../constants/themes.dart';
import 'comment_models_new.dart';
import 'comments_controller_new.dart';
import 'comment_tile_new.dart';
import 'user_role_controller_new.dart';

class CommentSectionNew extends StatelessWidget {
  final int mediaId;
  final MediaType mediaType;
  final String? mediaTitle;
  final String? mediaPoster;

  const CommentSectionNew({
    super.key,
    required this.mediaId,
    required this.mediaType,
    this.mediaTitle,
    this.mediaPoster,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<CommentsControllerNew>(
      init: CommentsControllerNew(
        mediaId: mediaId,
        mediaType: mediaType,
      ),
      builder: (controller) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, controller, colorScheme),
            _buildCommentInput(context, controller, colorScheme),
            _buildCommentsList(context, controller, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CommentsControllerNew controller,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                HugeIcons.strokeRoundedComment01,
                size: 24,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comments',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (controller.stats != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${controller.stats!.totalComments}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSortOptions(context, controller, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSortOptions(
    BuildContext context,
    CommentsControllerNew controller,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Text(
          'Sort by:',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CommentSortType.values.map((type) {
                final isSelected = controller.sortType == type;
                return Obx(() => GestureDetector(
                  onTap: () => controller.changeSortType(type),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getSortTypeDisplayName(type),
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ));
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: controller.refreshComments,
          icon: Icon(
            Icons.refresh_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    CommentsControllerNew controller,
    ColorScheme colorScheme,
  ) {
    final userRoleController = Get.find<UserRoleController>();
    
    if (!userRoleController.isLoggedIn) {
      return _buildLoginPrompt(context, colorScheme);
    }

    if (userRoleController.currentUser!.isBanned) {
      return _buildBannedMessage(context, colorScheme);
    }

    if (userRoleController.currentUser!.isMuted) {
      return _buildMutedMessage(context, colorScheme);
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainer,
                backgroundImage: userRoleController.currentUser?.avatarUrl != null
                    ? NetworkImage(userRoleController.currentUser!.avatarUrl!)
                    : null,
                child: userRoleController.currentUser?.avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comment as ${userRoleController.currentUser!.username}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              hintText: 'What are your thoughts?',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: controller.replyController.text.trim().isEmpty
                    ? null
                    : () {
                        controller.replyController.clear();
                        controller.replyFocusNode.unfocus();
                      },
                child: Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: controller.replyController.text.trim().isEmpty ||
                        controller.isPostingComment
                    ? null
                    : () => controller.postComment(controller.replyController.text),
                icon: controller.isPostingComment
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.send_rounded, size: 16),
                label: Text(controller.isPostingComment ? 'Posting...' : 'Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.login_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Login to Comment',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to be logged in to join the discussion.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              // TODO: Navigate to login
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login functionality coming soon!')),
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedMessage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.block_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Account Banned',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account has been banned. You cannot post comments.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMutedMessage(BuildContext context, ColorScheme colorScheme) {
    final userRoleController = Get.find<UserRoleController>();
    final mutedUntil = userRoleController.currentUser!.mutedUntil!;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.volume_off_rounded,
            size: 48,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'Account Muted',
            style: TextStyle(
              color: colorScheme.onTertiaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is temporarily muted. You can comment again after ${_formatDateTime(mutedUntil)}.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    CommentsControllerNew controller,
    ColorScheme colorScheme,
  ) {
    if (controller.isLoading && controller.comments.isEmpty) {
      return _buildLoadingState(context, colorScheme);
    }

    if (controller.error.isNotEmpty) {
      return _buildErrorState(context, controller, colorScheme);
    }

    if (controller.comments.isEmpty) {
      return _buildEmptyState(context, colorScheme);
    }

    return Column(
      children: [
        // Comments list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: controller.comments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final comment = controller.comments[index];
            final isLast = index == controller.comments.length - 1;
            
            return CommentTileNew(
              comment: comment,
              depth: 0,
              isLastReply: isLast,
              onReply: () => controller.startReply(comment.id),
              onVote: () => _handleVote(context, controller, comment),
              onEdit: () => _handleEdit(context, controller, comment),
              onDelete: () => _handleDelete(context, controller, comment),
              onPin: () => controller.pinComment(comment.id),
              onLock: () => controller.lockComment(comment.id),
              onUserTap: () => _showUserProfile(context, comment.user),
            );
          },
        ),

        // Load more button
        if (controller.hasMore)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextButton(
              onPressed: controller.isLoadingMore
                  ? null
                  : controller.loadMoreComments,
              child: controller.isLoadingMore
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Loading...'),
                      ],
                    )
                  : Text('Load More Comments'),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          AnymexProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading comments...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    CommentsControllerNew controller,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load comments',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.refreshComments,
            icon: Icon(Icons.refresh_rounded, size: 16),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'No comments yet',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts about this ${mediaType.name}!',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleVote(BuildContext context, CommentsControllerNew controller, Comment comment) {
    // Show vote dialog or handle directly
    // For now, we'll just upvote
    controller.voteComment(comment.id, 1);
  }

  void _handleEdit(BuildContext context, CommentsControllerNew controller, Comment comment) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comment'),
        content: TextField(
          controller: controller.editController..text = comment.content,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelEdit();
            },
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.editComment(comment.id, controller.editController.text);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context, CommentsControllerNew controller, Comment comment) {
    controller.deleteComment(comment.id);
  }

  void _showUserProfile(BuildContext context, CommentUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserProfileBottomSheet(user: user),
    );
  }

  String _getSortTypeDisplayName(CommentSortType type) {
    switch (type) {
      case CommentSortType.best:
        return 'Best';
      case CommentSortType.new:
        return 'New';
      case CommentSortType.old:
        return 'Old';
      case CommentSortType.top:
        return 'Top';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'a few seconds';
    }
  }
}

class _UserProfileBottomSheet extends StatelessWidget {
  final CommentUser user;

  const _UserProfileBottomSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleController = Get.find<UserRoleController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.surfaceContainer,
                    backgroundImage: user.avatarUrl?.isNotEmpty == true
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl?.isEmpty != false
                        ? Icon(
                            Icons.person_rounded,
                            size: 30,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.username,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: user.isBanned 
                                    ? colorScheme.onSurface.withOpacity(0.5)
                                    : colorScheme.onSurface,
                                decoration: user.isBanned 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                            ),
                            if (user.role != UserRole.normalUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getRoleColor(user.role).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  user.role.displayName,
                                  style: TextStyle(
                                    color: _getRoleColor(user.role),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Member since ${_formatDate(user.createdAt)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Status
              if (user.isBanned || user.isMuted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.isBanned 
                        ? colorScheme.errorContainer
                        : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isBanned ? Icons.block_rounded : Icons.volume_off_rounded,
                        color: user.isBanned 
                            ? colorScheme.error
                            : colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.isBanned 
                              ? 'This user is banned'
                              : 'This user is temporarily muted',
                          style: TextStyle(
                            color: user.isBanned 
                                ? colorScheme.error
                                : colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // IDs
              if (user.anilistId != null || user.malId != null || user.simklId != null) ...[
                Text(
                  'Connected Accounts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (user.anilistId != null)
                  _buildAccountTile(
                    context,
                    'AniList',
                    user.anilistId!,
                    'https://anilist.co/user/${user.anilistId}',
                    'assets/images/anilist-icon.png',
                  ),
                if (user.malId != null)
                  _buildAccountTile(
                    context,
                    'MyAnimeList',
                    user.malId!,
                    'https://myanimelist.net/profile/${user.malId}',
                    'assets/images/mal-icon.png',
                  ),
                if (user.simklId != null)
                  _buildAccountTile(
                    context,
                    'SIMKL',
                    user.simklId!,
                    'https://simkl.com/${user.simklId}',
                    'assets/images/simkl-icon.png',
                  ),
                const SizedBox(height: 24),
              ],
              
              // Actions
              Text(
                'Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // View Profile
              ListTile(
                leading: Icon(Icons.person_rounded),
                title: Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile view coming soon!')),
                  );
                },
              ),
              
              // Block User (if not self)
              if (userRoleController.currentUser?.id != user.id)
                ListTile(
                  leading: Icon(Icons.block_rounded),
                  title: Text('Block User'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Block functionality coming soon!')),
                    );
                  },
                ),
              
              // Report User (if not self)
              if (userRoleController.currentUser?.id != user.id)
                ListTile(
                  leading: Icon(Icons.flag_rounded, color: colorScheme.error),
                  title: Text('Report User', style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report functionality coming soon!')),
                    );
                  },
                ),
              
              // Moderation actions (if moderator)
              if (userRoleController.isModerator && userRoleController.currentUser?.id != user.id) ...[
                const Divider(),
                Text(
                  'Moderation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (userRoleController.canMuteUser())
                  ListTile(
                    leading: Icon(Icons.volume_off_rounded),
                    title: Text('Mute User'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mute functionality coming soon!')),
                      );
                    },
                  ),
                
                if (userRoleController.canBanUser())
                  ListTile(
                    leading: Icon(Icons.block_rounded, color: colorScheme.error),
                    title: Text('Ban User', style: TextStyle(color: colorScheme.error)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ban functionality coming soon!')),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    String platform,
    String userId,
    String url,
    String assetPath,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            platform.substring(0, 2).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(platform),
      subtitle: Text('ID: $userId'),
      trailing: Icon(Icons.open_in_new_rounded, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('External link opening coming soon!')),
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.red;
      case UserRole.admin:
        return Colors.orange;
      case UserRole.moderator:
        return Colors.green;
      case UserRole.normalUser:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'Recently';
    }
  }
}