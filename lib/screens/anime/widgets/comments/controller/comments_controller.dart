import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments_db.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/services/commentum_service.dart';
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
  final commentumService = Get.find<CommentumService>();

  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  final RxList<Comment> comments = <Comment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isInputExpanded = false.obs;

  final RxSet<String> votingComments = <String>{}.obs;
  
  // Commentum v2 specific states
  final RxBool isModerator = false.obs;
  final RxBool isAdmin = false.obs;
  final RxBool isSuperAdmin = false.obs;
  final RxString currentUserRole = 'user'.obs;

  late AnimationController expandController;
  late AnimationController fadeController;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _setupFocusListener();
    _checkUserRole();
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

  // Check user role for Commentum v2
  Future<void> _checkUserRole() async {
    try {
      isModerator.value = await commentumService.isModerator();
      isAdmin.value = await commentumService.isAdmin();
      isSuperAdmin.value = await commentumService.isSuperAdmin();
      
      if (isSuperAdmin.value) {
        currentUserRole.value = 'super_admin';
      } else if (isAdmin.value) {
        currentUserRole.value = 'admin';
      } else if (isModerator.value) {
        currentUserRole.value = 'moderator';
      } else {
        currentUserRole.value = 'user';
      }
    } catch (e) {
      print('Error checking user role: $e');
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

  Future<void> addReply(Comment parentComment, String replyContent) async {
    if (replyContent.trim().isEmpty || isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      // For now, create a reply as a new comment with parent reference
      // In a full implementation, this would be a nested reply system
      final newComment = await commentsDB.addComment(
        comment: replyContent.trim(),
        mediaId: mediaId,
        tag: currentTag ?? 'General',
      );

      if (newComment != null) {
        // For now, add as a regular comment. In future, implement nested replies
        comments.insert(0, newComment);
        
        // Optionally show that it's a reply
        Get.snackbar('Reply posted', 'Your reply has been posted successfully');
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar('Error', 'Failed to post reply. Please try again.');
    } finally {
      isSubmitting.value = false;
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
      // Commentum v2 fields
      pinned: original.pinned,
      locked: original.locked,
      edited: original.edited,
      editCount: original.editCount,
      editHistory: original.editHistory,
      reported: original.reported,
      reportCount: original.reportCount,
      reportStatus: original.reportStatus,
      userBanned: original.userBanned,
      userMutedUntil: original.userMutedUntil,
      userShadowBanned: original.userShadowBanned,
      userWarnings: original.userWarnings,
      moderatedBy: original.moderatedBy,
      moderationReason: original.moderationReason,
      parentId: original.parentId,
      replies: original.replies,
    );
  }

  // Commentum v2 specific methods

  Future<void> editComment(Comment comment, String newContent) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        Get.snackbar('Error', 'Invalid comment ID');
        return;
      }

      final updatedComment = await commentsDB.editComment(commentId, newContent);
      
      if (updatedComment != null) {
        final index = comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          comments[index] = updatedComment;
        }
        Get.snackbar('Success', 'Comment edited successfully');
      } else {
        Get.snackbar('Error', 'Failed to edit comment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to edit comment');
    }
  }

  Future<void> deleteComment(Comment comment) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        Get.snackbar('Error', 'Invalid comment ID');
        return;
      }

      final success = await commentsDB.deleteComment(commentId);
      
      if (success) {
        comments.removeWhere((c) => c.id == comment.id);
        Get.snackbar('Success', 'Comment deleted successfully');
      } else {
        Get.snackbar('Error', 'Failed to delete comment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment');
    }
  }

  Future<void> reportComment(Comment comment, String reason, {String? notes}) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        Get.snackbar('Error', 'Invalid comment ID');
        return;
      }

      final success = await commentsDB.reportComment(commentId, reason, notes: notes);
      
      if (success) {
        // Update local comment state
        final index = comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            reported: true,
            reportCount: (comments[index].reportCount ?? 0) + 1,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to report comment');
    }
  }

  Future<void> moderateComment({
    required Comment comment,
    required String action,
    required String reason,
  }) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        Get.snackbar('Error', 'Invalid comment ID');
        return;
      }

      final success = await commentsDB.moderateComment(
        action: action,
        commentId: commentId,
        reason: reason,
      );
      
      if (success) {
        await loadComments(); // Refresh comments to see moderation changes
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to moderate comment');
    }
  }

  Future<void> manageUser({
    required String targetUserId,
    required String action,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
  }) async {
    try {
      final success = await commentsDB.manageUser(
        action: action,
        targetUserId: targetUserId,
        reason: reason,
        severity: severity,
        duration: duration,
        shadowBan: shadowBan,
      );
      
      if (success) {
        await loadComments(); // Refresh comments to see user status changes
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to manage user');
    }
  }

  bool canEditComment(Comment comment) {
    // Only comment owners can edit their own comments
    return comment.userId == profile.id?.toString();
  }

  bool canDeleteComment(Comment comment) {
    // Users can delete their own comments, moderators/admins can delete any
    if (comment.userId == profile.id?.toString()) {
      return true;
    }
    return isModerator.value || isAdmin.value;
  }

  bool canModerate() {
    return isModerator.value || isAdmin.value;
  }

  bool canManageUsers() {
    return isAdmin.value;
  }

  Future<void> refreshComments() async {
    await loadComments();
  }
}
