import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments_db.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CommentSectionController extends GetxController
    with GetTickerProviderStateMixin {
  final String mediaId;
  final String? currentTag;

  CommentSectionController({
    required this.mediaId,
    this.currentTag,
  });

  final profile = serviceHandler.anilistService.profileData.value;
  final commentsDB = CommentsDatabase();

  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  final RxList<Comment> comments = <Comment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isInputExpanded = false.obs;

  final RxSet<String> votingComments = <String>{}.obs;
  final RxSet<String> editingComments = <String>{}.obs;
  final RxMap<String, String> replyText = <String, String>{}.obs;
  final RxMap<String, bool> showReplyInput = <String, bool>{}.obs;

  late AnimationController expandController;
  late AnimationController fadeController;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _setupFocusListener();
    loadComments();
  }

  @override
  void onClose() {
    expandController.dispose();
    fadeController.dispose();
    commentController.dispose();
    commentFocusNode.dispose();
    super.onClose();
  }

  void _initializeAnimations() {
    expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _setupFocusListener() {
    commentFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (commentFocusNode.hasFocus && !isInputExpanded.value) {
      isInputExpanded.value = true;
      expandController.forward();
      fadeController.forward();
    }
  }

  Future<void> loadComments() async {
    isLoading.value = true;
    try {
      final fetchedComments = await commentsDB.fetchComments(mediaId);
      comments.assignAll(fetchedComments);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load comments. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment() async {
    if (commentController.text.trim().isEmpty || isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      final newComment = await commentsDB.addComment(
        comment: commentController.text.trim(),
        mediaId: mediaId,
        tag: currentTag ?? 'General',
      );

      if (newComment != null) {
        comments.insert(0, newComment);
      }

      HapticFeedback.lightImpact();
      clearInputs();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearInputs() {
    commentController.clear();
    isInputExpanded.value = false;
    expandController.reverse();
    fadeController.reverse();
    commentFocusNode.unfocus();
  }

  Future<void> handleVote(Comment comment, int newVote) async {
    if (votingComments.contains(comment.id)) {
      return;
    }

    if (comment.userVote == newVote) {
      newVote = 0;
    }

    HapticFeedback.selectionClick();

    votingComments.add(comment.id);

    final index = comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) {
      votingComments.remove(comment.id);
      return;
    }

    final originalLikes = comment.likes;
    final originalDislikes = comment.dislikes;
    final originalUserVote = comment.userVote;

    final updatedComment = _createUpdatedComment(comment, newVote);
    comments[index] = updatedComment;

    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        throw Exception("Invalid comment ID: ${comment.id}");
      }

      final result = await commentsDB.likeOrDislikeComment(
          commentId, originalUserVote, newVote);

      if (result == null) {
        comment.likes = originalLikes;
        comment.dislikes = originalDislikes;
        comment.userVote = originalUserVote;
        comments[index] = comment;
        Get.snackbar('Error', 'Failed to update vote. Please try again.');
      } else {
        comment.likes = result['likes'];
        comment.dislikes = result['dislikes'];
        comment.userVote = result['userVote'];
        comments[index] = comment;
      }
    } catch (e) {
      comment.likes = originalLikes;
      comment.dislikes = originalDislikes;
      comment.userVote = originalUserVote;
      comments[index] = comment;
      Get.snackbar('Error', 'Failed to update vote. Please try again.');
    } finally {
      votingComments.remove(comment.id);
    }
  }

  Comment _createUpdatedComment(Comment original, int newVote) {
    int newLikes = original.likes;
    int newDislikes = original.dislikes;

    if (original.userVote == 1) {
      newLikes--;
    } else if (original.userVote == -1) {
      newDislikes--;
    }

    if (newVote == 1) {
      newLikes++;
    } else if (newVote == -1) {
      newDislikes++;
    }

    newLikes = newLikes < 0 ? 0 : newLikes;
    newDislikes = newDislikes < 0 ? 0 : newDislikes;

    return Comment(
      id: original.id,
      userId: original.userId,
      commentText: original.commentText,
      contentId: original.contentId,
      tag: original.tag,
      likes: newLikes,
      dislikes: newDislikes,
      userVote: newVote,
      username: original.username,
      avatarUrl: original.avatarUrl,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      deleted: original.deleted,
    );
  }

  Future<void> refreshComments() async {
    await loadComments();
  }

  // Reply to a comment
  Future<void> addReply(Comment parentComment) async {
    final replyText = this.replyText[parentComment.id]?.trim() ?? '';
    if (replyText.isEmpty) return;

    try {
      final newComment = await commentsDB.addReply(
        parentCommentId: int.parse(parentComment.id),
        comment: replyText,
        mediaId: mediaId,
      );

      if (newComment != null) {
        // Add reply to parent comment
        final parentIndex = comments.indexWhere((c) => c.id == parentComment.id);
        if (parentIndex != -1) {
          final updatedParent = comments[parentIndex].copyWith(
            replies: [...(comments[parentIndex].replies ?? []), newComment],
          );
          comments[parentIndex] = updatedParent;
        }
        
        // Clear reply input
        this.replyText[parentComment.id] = '';
        showReplyInput[parentComment.id] = false;
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add reply. Please try again.');
    }
  }

  // Edit a comment
  Future<void> editComment(Comment comment, String newContent) async {
    if (editingComments.contains(comment.id)) return;

    editingComments.add(comment.id);
    try {
      final updatedComment = await commentsDB.updateComment(
        int.parse(comment.id),
        newContent.trim(),
      );

      if (updatedComment != null) {
        final index = comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            commentText: newContent.trim(),
            isEdited: true,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar('Error', 'Failed to edit comment. Please try again.');
    } finally {
      editingComments.remove(comment.id);
    }
  }

  // Delete a comment
  Future<void> deleteComment(Comment comment) async {
    try {
      final success = await commentsDB.deleteComment(int.parse(comment.id));
      
      if (success) {
        comments.removeWhere((c) => c.id == comment.id);
        HapticFeedback.lightImpact();
        Get.snackbar('Success', 'Comment deleted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment. Please try again.');
    }
  }

  // Report a comment
  Future<void> reportComment(Comment comment, String reason) async {
    try {
      final success = await commentsDB.reportComment(
        int.parse(comment.id),
        reason,
      );
      
      if (success) {
        HapticFeedback.lightImpact();
        Get.snackbar('Success', 'Comment reported successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to report comment. Please try again.');
    }
  }

  // Toggle reply input
  void toggleReplyInput(String commentId) {
    showReplyInput[commentId] = !(showReplyInput[commentId] ?? false);
    if (showReplyInput[commentId] == true) {
      replyText[commentId] = '';
    }
  }

  // Toggle edit mode
  void toggleEditMode(String commentId) {
    if (editingComments.contains(commentId)) {
      editingComments.remove(commentId);
    } else {
      editingComments.add(commentId);
    }
  }
}
