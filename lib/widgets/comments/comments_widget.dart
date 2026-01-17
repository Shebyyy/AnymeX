import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:anymex/controllers/comments_controller.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.comment_outlined, size: 24),
              const SizedBox(width: 8),
              Text(
                'Comments',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.mediaTitle != null)
                Flexible(
                  child: Text(
                    widget.mediaTitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Comment input
          _buildCommentInput(),
          const SizedBox(height: 16),

          // Comments list
          _buildCommentsList(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Write a comment...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _commentController.clear();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitComment,
                child: const Text('Post'),
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

      if (_commentsController.comments.isEmpty && !_commentsController.isLoading.value) {
        return Center(
          child: Column(
            children: [
              Icon(Icons.comment_bank_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share your thoughts!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
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
      builder: (context) => AlertDialog(
        title: const Text('Reply to Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Replying to ${parentComment.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              parentComment.commentText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your reply...',
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
          ElevatedButton(
            onPressed: () async {
              final success = await _commentsController.addComment(
                replyController.text.trim(),
              );
              if (success) {
                Navigator.pop(context);
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Comment comment) {
    final editController = TextEditingController(text: comment.commentText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 3,
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
          ElevatedButton(
            onPressed: () async {
              final success = await _commentsController.updateComment(
                int.parse(comment.id),
                editController.text.trim(),
              );
              if (success) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _commentsController.deleteComment(int.parse(comment.id));
              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Comment comment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reporting comment by ${comment.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              comment.commentText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for reporting...',
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
          ElevatedButton(
            onPressed: () async {
              final success = await _commentsController.reportComment(
                int.parse(comment.id),
                reasonController.text.trim(),
              );
              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: comment.deleted ? Colors.grey.shade100 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: comment.avatarUrl != null
                    ? CachedNetworkImageProvider(comment.avatarUrl!)
                    : null,
                child: comment.avatarUrl == null
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (comment.isMod || comment.isAdmin) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: comment.isSuperAdmin ? Colors.purple : Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              comment.isSuperAdmin ? 'Admin' : 'Mod',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeago.format(DateTime.parse(comment.createdAt)),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
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