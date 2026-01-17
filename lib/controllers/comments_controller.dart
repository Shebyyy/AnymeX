import 'package:get/get.dart';
import 'package:anymex/database/comments_db.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';

class CommentsController extends GetxController {
  final CommentsDatabase _commentsDatabase = CommentsDatabase();
  
  // Reactive variables
  var isLoading = false.obs;
  var comments = <Comment>[].obs;
  var errorMessage = ''.obs;
  
  // Pagination
  var currentPage = 1.obs;
  var hasMoreComments = true.obs;
  var isFetchingMore = false.obs;
  
  // Current media context
  var currentMediaId = ''.obs;
  var currentMediaType = 'anime'.obs;
  
  // User interactions
  var userVotes = <int, int>{}.obs; // commentId -> voteType
  
  @override
  void onInit() {
    super.onInit();
    // Auto-login when controller initializes
    if (serviceHandler.anilistService.isLoggedIn.value) {
      _commentsDatabase.login();
    }
  }

  // Load comments for a specific media
  Future<void> loadComments(String mediaId, {String mediaType = 'anime', bool refresh = false}) async {
    if (mediaId.isEmpty) return;
    
    if (refresh) {
      currentPage.value = 1;
      hasMoreComments.value = true;
      comments.clear();
      userVotes.clear();
    }
    
    if (isLoading.value && !refresh) return;
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      currentMediaId.value = mediaId;
      currentMediaType.value = mediaType;
      
      final newComments = await _commentsDatabase.fetchComments(mediaId);
      
      if (refresh) {
        comments.assignAll(newComments);
      } else {
        comments.addAll(newComments);
      }
      
      // Update user votes
      for (final comment in newComments) {
        if (comment.userVote != 0) {
          userVotes[int.parse(comment.id)] = comment.userVote;
        }
      }
      
      // Check if there are more comments (simplified - in real app, use pagination info)
      hasMoreComments.value = newComments.length >= 20;
      currentPage.value++;
      
    } catch (e) {
      errorMessage.value = 'Failed to load comments: $e';
      Get.snackbar('Error', 'Failed to load comments');
    } finally {
      isLoading.value = false;
    }
  }

  // Load more comments (pagination)
  Future<void> loadMoreComments() async {
    if (!hasMoreComments.value || isFetchingMore.value || isLoading.value) return;
    
    isFetchingMore.value = true;
    
    try {
      final newComments = await _commentsDatabase.fetchComments(currentMediaId.value);
      comments.addAll(newComments);
      
      // Update user votes
      for (final comment in newComments) {
        if (comment.userVote != 0) {
          userVotes[int.parse(comment.id)] = comment.userVote;
        }
      }
      
      hasMoreComments.value = newComments.length >= 20;
      currentPage.value++;
      
    } catch (e) {
      errorMessage.value = 'Failed to load more comments: $e';
    } finally {
      isFetchingMore.value = false;
    }
  }

  // Add a new comment
  Future<bool> addComment(String content, {int? parentCommentId}) async {
    if (content.trim().isEmpty) {
      Get.snackbar('Error', 'Comment cannot be empty');
      return false;
    }
    
    if (currentMediaId.value.isEmpty) {
      Get.snackbar('Error', 'No media selected');
      return false;
    }
    
    try {
      final newComment = await _commentsDatabase.addComment(
        comment: content.trim(),
        mediaId: currentMediaId.value,
        tag: '0', // Default tag
      );
      
      if (newComment != null) {
        // Add to the beginning of the list
        comments.insert(0, newComment);
        Get.snackbar('Success', 'Comment added successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to add comment');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: $e');
      return false;
    }
  }

  // Update a comment
  Future<bool> updateComment(int commentId, String newContent) async {
    if (newContent.trim().isEmpty) {
      Get.snackbar('Error', 'Comment cannot be empty');
      return false;
    }
    
    try {
      final updatedComment = await _commentsDatabase.updateComment(commentId, newContent.trim());
      
      if (updatedComment != null) {
        // Find and update the comment in the list
        final index = comments.indexWhere((c) => int.parse(c.id) == commentId);
        if (index != -1) {
          comments[index] = updatedComment;
          comments.refresh();
        }
        Get.snackbar('Success', 'Comment updated successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update comment');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update comment: $e');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final success = await _commentsDatabase.deleteComment(commentId);
      
      if (success) {
        // Remove from the list
        comments.removeWhere((c) => int.parse(c.id) == commentId);
        userVotes.remove(commentId);
        Get.snackbar('Success', 'Comment deleted successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to delete comment');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment: $e');
      return false;
    }
  }

  // Vote on a comment
  Future<void> voteOnComment(int commentId, int voteType) async {
    try {
      final currentVote = userVotes[commentId] ?? 0;
      
      // If clicking the same vote type, remove the vote
      final newVote = (currentVote == voteType) ? 0 : voteType;
      
      final result = await _commentsDatabase.likeOrDislikeComment(commentId, currentVote, newVote);
      
      if (result != null) {
        // Update the comment in the list
        final index = comments.indexWhere((c) => int.parse(c.id) == commentId);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            likes: result['likes'] ?? comments[index].likes,
            dislikes: result['dislikes'] ?? comments[index].dislikes,
            userVote: result['userVote'] ?? 0,
          );
          comments.refresh();
        }
        
        // Update user votes
        if (newVote == 0) {
          userVotes.remove(commentId);
        } else {
          userVotes[commentId] = newVote;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to vote: $e');
    }
  }

  // Report a comment
  Future<bool> reportComment(int commentId, String reason) async {
    if (reason.trim().isEmpty) {
      Get.snackbar('Error', 'Please provide a reason for the report');
      return false;
    }
    
    try {
      final success = await _commentsDatabase.reportComment(commentId, reason.trim());
      if (!success) {
        Get.snackbar('Error', 'Failed to report comment');
      }
      return success;
    } catch (e) {
      Get.snackbar('Error', 'Failed to report comment: $e');
      return false;
    }
  }

  // Refresh comments
  Future<void> refreshComments() async {
    if (currentMediaId.value.isNotEmpty) {
      await loadComments(currentMediaId.value, mediaType: currentMediaType.value, refresh: true);
    }
  }

  // Get comment thread with replies
  Future<List<Comment>> getCommentThread(int commentId) async {
    try {
      return await _commentsDatabase.getCommentThread(commentId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load comment thread: $e');
      return [];
    }
  }

  // Moderation methods
  
  // Lock/unlock a thread
  Future<bool> lockThread(int commentId, bool isLocked) async {
    try {
      final success = await _commentsDatabase.lockThread(commentId, isLocked);
      
      if (success) {
        // Update the comment in the list
        final index = comments.indexWhere((c) => int.parse(c.id) == commentId);
        if (index != -1) {
          // This would need to be implemented in the Comment model
          // comments[index].isLocked = isLocked;
          comments.refresh();
        }
      }
      
      return success;
    } catch (e) {
      Get.snackbar('Error', 'Failed to ${isLocked ? 'lock' : 'unlock'} thread: $e');
      return false;
    }
  }

  // Soft delete a comment (moderation)
  Future<bool> softDeleteComment(int commentId, String reason) async {
    if (reason.trim().isEmpty) {
      Get.snackbar('Error', 'Please provide a reason for removing this comment');
      return false;
    }
    
    try {
      final success = await _commentsDatabase.softDeleteComment(commentId, reason.trim());
      
      if (success) {
        // Mark as deleted in the list (but don't remove)
        final index = comments.indexWhere((c) => int.parse(c.id) == commentId);
        if (index != -1) {
          comments[index] = comments[index].copyWith(deleted: true);
          comments.refresh();
        }
      }
      
      return success;
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove comment: $e');
      return false;
    }
  }

  // Get system stats (admin only)
  Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      return await _commentsDatabase.getSystemStats();
    } catch (e) {
      Get.snackbar('Error', 'Failed to get system stats: $e');
      return null;
    }
  }

  // Clear all comments (when switching media)
  void clearComments() {
    comments.clear();
    userVotes.clear();
    currentPage.value = 1;
    hasMoreComments.value = true;
    currentMediaId.value = '';
    errorMessage.value = '';
  }

  // Get user vote for a specific comment
  int getUserVote(int commentId) {
    return userVotes[commentId] ?? 0;
  }

  // Check if user can edit a comment
  bool canEditComment(Comment comment) {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) return false;
    
    // User can edit their own comments
    return comment.userId == currentUser.id.toString();
  }

  // Check if user can delete a comment
  bool canDeleteComment(Comment comment) {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) return false;
    
    // User can delete their own comments
    return comment.userId == currentUser.id.toString();
  }

  // Check if user is moderator or admin
  bool get isModerator => _commentsDatabase.isLoggedIn; // Simplified - check actual role
  
  // Check if user is admin
  bool get isAdmin => _commentsDatabase.isLoggedIn; // Simplified - check actual role
}