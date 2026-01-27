import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart' as d;
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';

import 'model/comment.dart';

class CommentsDatabase {
  final commentumService = Get.find<CommentumService>();

  void log(String msg) => d.Logger.i("[CommentsDatabase] $msg");

  // Fetch comments for a media using Commentum v2
  Future<List<Comment>> fetchComments(String mediaId) async {
    try {
      log("Fetching comments for media: $mediaId");
      final comments = await commentumService.fetchComments(mediaId);
      log("Fetched ${comments.length} comments");
      return comments;
    } catch (e) {
      log("Error fetching comments: $e");
      snackBar('Error fetching comments');
      return [];
    }
  }

  // Add a comment using Commentum v2
  Future<Comment?> addComment({
    required String comment,
    required String mediaId,
    required String tag,
  }) async {
    try {
      log("Adding comment to media: $mediaId");
      final newComment = await commentumService.createComment(
        mediaId: mediaId,
        content: comment,
      );
      
      if (newComment != null) {
        log('Comment added successfully');
      } else {
        log('Failed to add comment');
      }
      
      return newComment;
    } catch (e) {
      log("Error adding comment: $e");
      snackBar('Error adding comment');
      return null;
    }
  }

  // Vote on a comment using Commentum v2
  Future<Map<String, dynamic>?> likeOrDislikeComment(
      int commentId, int currentVote, int newVote) async {
    try {
      log("Voting on comment: $commentId, current: $currentVote, new: $newVote");
      
      String voteType;
      if (newVote == 0) {
        voteType = 'remove';
      } else if (newVote == 1) {
        voteType = 'upvote';
      } else if (newVote == -1) {
        voteType = 'downvote';
      } else {
        return null;
      }

      final result = await commentumService.voteComment(
        commentId: commentId,
        voteType: voteType,
      );

      if (result != null) {
        log("Vote updated successfully: $result");
        return {
          'likes': result['upvotes'],
          'dislikes': result['downvotes'],
          'userVote': result['userVote'] == 'upvote' 
              ? 1 
              : result['userVote'] == 'downvote' 
                  ? -1 
                  : 0,
        };
      } else {
        log('Failed to update vote');
        return null;
      }
    } catch (e) {
      log("Error updating vote: $e");
      snackBar('Error updating vote');
      return null;
    }
  }

  // Edit a comment using Commentum v2
  Future<Comment?> editComment(int commentId, String newContent) async {
    try {
      log("Editing comment: $commentId");
      final updatedComment = await commentumService.editComment(
        commentId: commentId,
        content: newContent,
      );
      
      if (updatedComment != null) {
        log('Comment edited successfully');
      } else {
        log('Failed to edit comment');
      }
      
      return updatedComment;
    } catch (e) {
      log("Error editing comment: $e");
      snackBar('Error editing comment');
      return null;
    }
  }

  // Delete a comment using Commentum v2
  Future<bool> deleteComment(int commentId) async {
    try {
      log("Deleting comment: $commentId");
      final success = await commentumService.deleteComment(commentId: commentId);
      
      if (success) {
        log('Comment deleted successfully');
      } else {
        log('Failed to delete comment');
      }
      
      return success;
    } catch (e) {
      log("Error deleting comment: $e");
      snackBar('Error deleting comment');
      return false;
    }
  }

  // Report a comment using Commentum v2
  Future<bool> reportComment(int commentId, String reason, {String? notes}) async {
    try {
      log("Reporting comment: $commentId, reason: $reason");
      final success = await commentumService.reportComment(
        commentId: commentId,
        reason: reason,
        notes: notes,
      );
      
      if (success) {
        log('Comment reported successfully');
        snackBar('Comment reported successfully');
      } else {
        log('Failed to report comment');
        snackBar('Failed to report comment');
      }
      
      return success;
    } catch (e) {
      log("Error reporting comment: $e");
      snackBar('Error reporting comment');
      return false;
    }
  }

  // Get moderation queue (admin/moderator only)
  Future<List<Map<String, dynamic>>> getModerationQueue() async {
    try {
      log("Fetching moderation queue");
      final queue = await commentumService.getModerationQueue();
      log("Fetched ${queue.length} items in moderation queue");
      return queue;
    } catch (e) {
      log("Error fetching moderation queue: $e");
      snackBar('Error fetching moderation queue');
      return [];
    }
  }

  // Moderate a comment (admin/moderator only)
  Future<bool> moderateComment({
    required String action,
    required int commentId,
    required String reason,
  }) async {
    try {
      log("Moderating comment: $commentId, action: $action");
      final success = await commentumService.moderateComment(
        action: action,
        commentId: commentId,
        reason: reason,
      );
      
      if (success) {
        log('Comment moderated successfully');
        snackBar('Comment moderated successfully');
      } else {
        log('Failed to moderate comment');
        snackBar('Failed to moderate comment');
      }
      
      return success;
    } catch (e) {
      log("Error moderating comment: $e");
      snackBar('Error moderating comment');
      return false;
    }
  }

  // User management (admin only)
  Future<bool> manageUser({
    required String action,
    required String targetUserId,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
  }) async {
    try {
      log("Managing user: $targetUserId, action: $action");
      final success = await commentumService.manageUser(
        action: action,
        targetUserId: targetUserId,
        reason: reason,
        severity: severity,
        duration: duration,
        shadowBan: shadowBan,
      );
      
      if (success) {
        log('User managed successfully');
        snackBar('User managed successfully');
      } else {
        log('Failed to manage user');
        snackBar('Failed to manage user');
      }
      
      return success;
    } catch (e) {
      log("Error managing user: $e");
      snackBar('Error managing user');
      return false;
    }
  }

  // Check if user is logged in (for compatibility)
  bool get isLoggedIn => commentumService.currentUserId != null;

  // Get current user info (for compatibility)
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    if (!isLoggedIn) return null;
    
    return {
      'id': commentumService.currentUserId,
      'username': commentumService.currentUsername,
      'avatar_url': commentumService.currentUserAvatar,
    };
  }

  // Login method (for compatibility - now uses AnymeX's existing auth)
  Future<void> login() async {
    // Commentum v2 doesn't require separate login
    // Uses AnymeX's existing authentication
    log("Using AnymeX authentication for Commentum v2");
  }

  // Logout method (for compatibility)
  Future<void> logout() async {
    // Commentum v2 doesn't require separate logout
    // Uses AnymeX's existing authentication
    log("Using AnymeX authentication for Commentum v2");
  }

  // Sync user data with AniList (for compatibility)
  Future<void> syncUserDataWithAniList() async {
    // Commentum v2 automatically fetches user data
    log("User data sync handled by Commentum v2 API");
  }
}
