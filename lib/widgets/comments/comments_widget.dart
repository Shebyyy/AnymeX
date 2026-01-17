import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:anymex/controllers/comments_controller.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/custom_widgets/anymex_container.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';

class CommentsWidget extends StatefulWidget {
  final String mediaId;
  final String mediaType;
  final String? mediaTitle;

  const CommentsWidget({
    Key? key,
    required this.mediaId,
    this.mediaType = 'anime',
    this.mediaTitle,
  }) : super(key: key);

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final CommentsController _commentsController = Get.put(CommentsController());
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() async {
    await _commentsController.loadComments(
      widget.mediaId,
      mediaType: widget.mediaType,
      refresh: true,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _commentsController.loadMoreComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymexContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.comment_outlined, 
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              AnymexText(
                text: 'Comments',
                size: 20,
                variant: TextVariant.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const Spacer(),
              if (widget.mediaTitle != null)
                Flexible(
                  child: AnymexText(
                    text: widget.mediaTitle!,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Comment input
          _buildCommentInput(),
          const SizedBox(height: 20),

          // Comments list
          _buildCommentsList(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return AnymexContainer(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
      radius: 16,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnymexButton2(
                label: 'Cancel',
                onTap: () => _commentController.clear(),
              ),
              const SizedBox(width: 12),
              AnymexButton(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Theme.of(context).colorScheme.primary,
                radius: 20,
                onTap: _submitComment,
                child: AnymexText(
                  text: 'Post',
                  color: Colors.white,
                  size: 14,
                  variant: TextVariant.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Obx(() {
      if (_commentsController.isLoading.value && _commentsController.comments.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      // Check if there's an authentication error
      if (_commentsController.errorMessage.value.contains('Invalid JWT') ||
          _commentsController.errorMessage.value.contains('401')) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle_outlined, 
                size: 64, 
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              AnymexText(
                text: 'Comments System Update',
                size: 18,
                variant: TextVariant.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              AnymexText(
                text: 'The comments system is currently being updated.\nPlease try again in a few minutes.',
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnymexButton(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                color: Theme.of(context).colorScheme.primary,
                radius: 22,
                onTap: _loadComments,
                child: AnymexText(
                  text: 'Retry',
                  color: Colors.white,
                  size: 14,
                  variant: TextVariant.bold,
                ),
              ),
            ],
          ),
        );
      }

      if (_commentsController.comments.isEmpty && !_commentsController.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.comment_bank_outlined, 
                size: 64, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 20),
              AnymexText(
                text: 'No comments yet',
                size: 16,
                variant: TextVariant.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 8),
              AnymexText(
                text: 'Be the first to share your thoughts!',
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _commentsController.refreshComments,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _commentsController.comments.length + (_commentsController.hasMoreComments.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _commentsController.comments.length) {
              return _buildLoadingIndicator();
            }

            final comment = _commentsController.comments[index];
            return CommentCard(
              comment: comment,
              onVote: (voteType) => _commentsController.voteOnComment(
                int.parse(comment.id),
                voteType,
              ),
              onReply: () => _showReplyDialog(comment),
              onEdit: _commentsController.canEditComment(comment) 
                  ? () => _showEditDialog(comment) 
                  : null,
              onDelete: _commentsController.canDeleteComment(comment)
                  ? () => _showDeleteDialog(comment)
                  : null,
              onReport: () => _showReportDialog(comment),
              userVote: _commentsController.getUserVote(int.parse(comment.id)),
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await _commentsController.addComment(content);
    if (success) {
      _commentController.clear();
    }
  }

  void _showReplyDialog(Comment parentComment) {
    final replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: 'Reply to Comment',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymexText(
              text: 'Replying to ${parentComment.username}',
              size: 14,
              variant: TextVariant.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            AnymexText(
              text: parentComment.commentText,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Write your reply...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        onConfirm: () async {
          final success = await _commentsController.addComment(
            replyController.text.trim(),
          );
          if (success) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditDialog(Comment comment) {
    final editController = TextEditingController(text: comment.commentText);
    
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: 'Edit Comment',
        contentWidget: TextField(
          controller: editController,
          maxLines: 3,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        onConfirm: () async {
          final success = await _commentsController.updateComment(
            int.parse(comment.id),
            editController.text.trim(),
          );
          if (success) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: 'Delete Comment',
        message: 'Are you sure you want to delete this comment? This action cannot be undone.',
        onConfirm: () async {
          final success = await _commentsController.deleteComment(int.parse(comment.id));
          if (success) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showReportDialog(Comment comment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: 'Report Comment',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymexText(
              text: 'Reporting comment by ${comment.username}',
              size: 14,
              variant: TextVariant.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            AnymexText(
              text: comment.commentText,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Reason for reporting...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        onConfirm: () async {
          final success = await _commentsController.reportComment(
            int.parse(comment.id),
            reasonController.text.trim(),
          );
          if (success) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;
  final Function(int) onVote;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final int userVote;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.onVote,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.userVote = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnymexContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      color: comment.deleted 
          ? Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3)
          : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.1),
      radius: 16,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                backgroundImage: comment.avatarUrl != null
                    ? CachedNetworkImageProvider(comment.avatarUrl!)
                    : null,
                child: comment.avatarUrl == null
                    ? Icon(
                        Icons.person, 
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnymexText(
                          text: comment.username,
                          size: 14,
                          variant: TextVariant.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        if (comment.isMod || comment.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: comment.isSuperAdmin 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AnymexText(
                              text: comment.isSuperAdmin ? 'Admin' : 'Mod',
                              size: 10,
                              color: Colors.white,
                              variant: TextVariant.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnymexText(
                      text: timeago.format(DateTime.parse(comment.createdAt)),
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              // More options
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'reply':
                      onReply?.call();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                    case 'report':
                      onReport?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onReply != null)
                    const PopupMenuItem(value: 'reply', child: Text('Reply')),
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  if (onReport != null)
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment content
          if (comment.deleted)
            Text(
              '[This comment has been removed]',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              comment.commentText,
              style: const TextStyle(fontSize: 14),
            ),
          
          const SizedBox(height: 12),

          // Voting buttons
          Row(
            children: [
              // Upvote
              InkWell(
                onTap: () => onVote(1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userVote == 1 ? Colors.green.shade100 : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: userVote == 1 ? Colors.green : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: TextStyle(
                          color: userVote == 1 ? Colors.green : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Downvote
              InkWell(
                onTap: () => onVote(-1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userVote == -1 ? Colors.red.shade100 : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down,
                        size: 16,
                        color: userVote == -1 ? Colors.red : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.dislikes}',
                        style: TextStyle(
                          color: userVote == -1 ? Colors.red : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Reply button
              if (onReply != null)
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}