import 'package:anymex/utils/logger.dart' as d;
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/comments_service.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:get/get.dart';

class CommentsDatabase {
  final CommentsService _commentsService = CommentsService();
  
  void log(String msg) => d.Logger.i("[CommentsDatabase] $msg");

  // Login to comments system using AniList token
  Future<void> login() async {
    if (!serviceHandler.anilistService.isLoggedIn.value) {
      snackBar('Login on Anilist First');
      return;
    }

    try {
      final success = await _commentsService.login();
      if (success) {
        log("Successfully logged into comments system");
      } else {
        log("Failed to login to comments system");
      }
    } catch (e) {
      log("Login error: $e");
      snackBar('Failed to login to comments system');
    }
  }

  // Fetch comments for a media (anime/manga)
  Future<List<Comment>> fetchComments(String animeId) async {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) {
      log('Please login first');
      return [];
    }

    try {
      // Convert animeId to int and determine media type
      final mediaId = int.tryParse(animeId);
      if (mediaId == null) {
        log('Invalid media ID: $animeId');
        return [];
      }

      // For now, assume anime type - you can enhance this to detect manga
      final mediaType = 'anime';
      
      final commentsData = await _commentsService.getMediaComments(mediaId, mediaType);
      
      return commentsData.map((commentData) {
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0', // Default tag - you can enhance this
          likes: commentData.userVote == 'upvote' ? 1 : 0, // Simplified
          dislikes: commentData.userVote == 'downvote' ? 1 : 0, // Simplified
          userVote: _convertVoteType(commentData.userVote),
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
        );
      }).toList();
    } catch (e) {
      log("Error fetching comments: $e");
      snackBar('Error fetching comments');
      return [];
    }
  }

  // Add a new comment
  Future<Comment?> addComment({
    required String comment,
    required String mediaId,
    required String tag,
  }) async {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) {
      log('Please login first');
      return null;
    }

    try {
      final mediaIdInt = int.tryParse(mediaId);
      if (mediaIdInt == null) {
        log('Invalid media ID: $mediaId');
        return null;
      }

      final mediaType = 'anime'; // Default to anime
      
      final commentData = await _commentsService.createComment(
        mediaId: mediaIdInt,
        mediaType: mediaType,
        content: comment.trim(),
      );

      if (commentData != null) {
        log('Comment added successfully');
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: tag,
          likes: 0,
          dislikes: 0,
          userVote: 0,
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
        );
      }
    } catch (e) {
      log("Error adding comment: $e");
      snackBar('Error adding comment');
    }
    return null;
  }

  // Vote on a comment (like/dislike)
  Future<Map<String, dynamic>?> likeOrDislikeComment(
    int commentId, int currentVote, int newVote) async {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (!serviceHandler.anilistService.isLoggedIn.value) {
      snackBar('Please login first');
      return null;
    }

    try {
      final voteType = _convertToVoteType(newVote);
      if (voteType == null) {
        log('Invalid vote type: $newVote');
        return null;
      }

      final voteResult = await _commentsService.voteOnComment(commentId, voteType);
      
      if (voteResult != null) {
        log("Vote recorded successfully for comment $commentId");
        return {
          'likes': voteResult.upvotes,
          'dislikes': voteResult.downvotes,
          'userVote': _convertVoteType(voteResult.userVote),
        };
      }
    } catch (e) {
      log("Error updating vote: $e");
      snackBar('Error updating vote');
    }
    return null;
  }

  // Update a comment
  Future<Comment?> updateComment(int commentId, String newContent) async {
    try {
      final commentData = await _commentsService.updateComment(commentId, newContent.trim());
      
      if (commentData != null) {
        log('Comment updated successfully');
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0',
          likes: 0,
          dislikes: 0,
          userVote: 0,
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
        );
      }
    } catch (e) {
      log("Error updating comment: $e");
      snackBar('Error updating comment');
    }
    return null;
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final success = await _commentsService.deleteComment(commentId);
      if (success) {
        log("Comment deleted successfully");
      }
      return success;
    } catch (e) {
      log("Error deleting comment: $e");
      snackBar('Error deleting comment');
      return false;
    }
  }

  // Report a comment
  Future<bool> reportComment(int commentId, String reason) async {
    try {
      final success = await _commentsService.reportComment(commentId, reason);
      if (success) {
        log("Comment reported successfully");
        snackBar('Comment reported successfully');
      }
      return success;
    } catch (e) {
      log("Error reporting comment: $e");
      snackBar('Error reporting comment');
      return false;
    }
  }

  // Get comment thread with replies
  Future<List<Comment>> getCommentThread(int commentId) async {
    try {
      final threadData = await _commentsService.getCommentThread(commentId);
      
      List<Comment> comments = [];
      
      // Add root comment
      comments.add(_convertToComment(threadData.rootComment));
      
      // Add all replies recursively
      for (final reply in threadData.replies) {
        comments.add(_convertToComment(reply));
      }
      
      return comments;
    } catch (e) {
      log("Error fetching comment thread: $e");
      snackBar('Error fetching comment thread');
      return [];
    }
  }

  // Get current user info from comments system
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) return null;

    try {
      // This would need to be implemented in the backend
      // For now, return AniList user info
      return {
        'anilist_user_id': currentUser.id,
        'username': currentUser.name,
        'profile_picture_url': currentUser.avatar,
      };
    } catch (e) {
      log("Error getting user info: $e");
      return null;
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => serviceHandler.anilistService.isLoggedIn.value;

  // Logout from comments system
  Future<void> logout() async {
    try {
      // The comments system uses AniList tokens, so no separate logout needed
      log("Logged out from comments system");
    } catch (e) {
      log("Error logging out: $e");
    }
  }

  // Add a reply to a comment
  Future<Comment?> addReply({
    required int parentCommentId,
    required String comment,
    required String mediaId,
  }) async {
    final currentUser = serviceHandler.anilistService.profileData.value;
    if (currentUser.id == null) {
      log('Please login first');
      return null;
    }

    try {
      final mediaIdInt = int.tryParse(mediaId);
      if (mediaIdInt == null) {
        log('Invalid media ID: $mediaId');
        return null;
      }

      final mediaType = 'anime'; // Default to anime
      
      final commentData = await _commentsService.createComment(
        mediaId: mediaIdInt,
        mediaType: mediaType,
        content: comment.trim(),
        parentCommentId: parentCommentId,
      );

      if (commentData != null) {
        log('Reply added successfully');
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0',
          likes: 0,
          dislikes: 0,
          userVote: 0,
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
          parentCommentId: parentCommentId,
        );
      }
    } catch (e) {
      log("Error adding reply: $e");
      snackBar('Error adding reply');
    }
    return null;
  }

  // Get user's comment history
  Future<List<Comment>> getUserCommentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final commentsData = await _commentsService.getOwnCommentHistory(
        page: page,
        limit: limit,
      );
      
      return commentsData.map((commentData) {
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0',
          likes: commentData.totalVotes,
          dislikes: 0,
          userVote: _convertVoteType(commentData.userVote),
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
          parentCommentId: commentData.parentCommentId,
        );
      }).toList();
    } catch (e) {
      log("Error fetching comment history: $e");
      snackBar('Error fetching comment history');
      return [];
    }
  }

  // Get pinned comments for media
  Future<List<Comment>> getPinnedComments(String mediaId) async {
    try {
      final commentsData = await _commentsService.getMediaComments(
        int.parse(mediaId),
        'anime',
        sort: 'pinned',
      );
      
      return commentsData.map((commentData) {
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0',
          likes: commentData.totalVotes,
          dislikes: 0,
          userVote: _convertVoteType(commentData.userVote),
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
          isPinned: true,
          parentCommentId: commentData.parentCommentId,
        );
      }).toList();
    } catch (e) {
      log("Error fetching pinned comments: $e");
      return [];
    }
  }

  // Search comments by content
  Future<List<Comment>> searchComments(String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final commentsData = await _commentsService.searchComments(
        query,
        page: page,
        limit: limit,
      );
      
      return commentsData.map((commentData) {
        return Comment(
          id: commentData.commentId.toString(),
          userId: commentData.userId.toString(),
          commentText: commentData.content,
          contentId: commentData.mediaId,
          tag: '0',
          likes: commentData.totalVotes,
          dislikes: 0,
          userVote: _convertVoteType(commentData.userVote),
          username: commentData.username,
          avatarUrl: commentData.profilePictureUrl,
          createdAt: commentData.createdAt.toIso8601String(),
          updatedAt: commentData.updatedAt.toIso8601String(),
          deleted: commentData.deleted,
          isMod: commentData.isMod,
          isAdmin: commentData.isAdmin,
          isSuperAdmin: commentData.isSuperAdmin,
          parentCommentId: commentData.parentCommentId,
        );
      }).toList();
    } catch (e) {
      log("Error searching comments: $e");
      return [];
    }
  }

  // Get comment analytics (for content creators)
  Future<Map<String, dynamic>?> getCommentAnalytics(String mediaId) async {
    try {
      final analytics = await _commentsService.getCommentAnalytics(
        int.parse(mediaId),
      );
      
      if (analytics != null) {
        return {
          'total_comments': analytics['total_comments'] ?? 0,
          'total_votes': analytics['total_votes'] ?? 0,
          'engagement_rate': analytics['engagement_rate'] ?? 0.0,
          'top_comments': analytics['top_comments'] ?? [],
          'sentiment_analysis': analytics['sentiment_analysis'] ?? {},
        };
      }
    } catch (e) {
      log("Error fetching comment analytics: $e");
    }
    return null;
  }

  // Sync user data with AniList
  Future<void> syncUserDataWithAniList() async {
    if (!serviceHandler.anilistService.isLoggedIn.value) return;

    try {
      // The backend automatically syncs with AniList on each request
      log("User data sync with AniList handled automatically");
    } catch (e) {
      log("Error syncing user data: $e");
    }
  }

  // Helper method to convert vote types
  int _convertVoteType(String? voteType) {
    switch (voteType) {
      case 'upvote':
        return 1;
      case 'downvote':
        return -1;
      default:
        return 0;
    }
  }

  // Helper method to convert to vote type string
  String? _convertToVoteType(int vote) {
    switch (vote) {
      case 1:
        return 'upvote';
      case -1:
        return 'downvote';
      case 0:
        return null; // Remove vote
      default:
        return null;
    }
  }

  // Convert CommentData to Comment model
  Comment _convertToComment(CommentData commentData) {
    return Comment(
      id: commentData.commentId.toString(),
      userId: commentData.userId.toString(),
      commentText: commentData.content,
      contentId: commentData.mediaId,
      tag: '0',
      likes: commentData.userVote == 'upvote' ? 1 : 0,
      dislikes: commentData.userVote == 'downvote' ? 1 : 0,
      userVote: _convertVoteType(commentData.userVote),
      username: commentData.username,
      avatarUrl: commentData.profilePictureUrl,
      createdAt: commentData.createdAt.toIso8601String(),
      updatedAt: commentData.updatedAt.toIso8601String(),
      deleted: commentData.deleted,
      isMod: commentData.isMod,
      isAdmin: commentData.isAdmin,
      isSuperAdmin: commentData.isSuperAdmin,
    );
  }

  // Moderation methods (if user has permissions)
  
  // Lock/unlock a comment thread
  Future<bool> lockThread(int commentId, bool isLocked) async {
    try {
      final success = await _commentsService.lockThread(commentId, isLocked);
      if (success) {
        log("Thread ${isLocked ? 'locked' : 'unlocked'} successfully");
        snackBar('Thread ${isLocked ? 'locked' : 'unlocked'} successfully');
      }
      return success;
    } catch (e) {
      log("Error locking thread: $e");
      snackBar('Error locking thread');
      return false;
    }
  }

  // Soft delete a comment (moderation)
  Future<bool> softDeleteComment(int commentId, String reason) async {
    try {
      final success = await _commentsService.softDeleteComment(commentId, reason);
      if (success) {
        log("Comment soft deleted successfully");
        snackBar('Comment removed successfully');
      }
      return success;
    } catch (e) {
      log("Error soft deleting comment: $e");
      snackBar('Error removing comment');
      return false;
    }
  }

  // Get system stats (admin only)
  Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      final stats = await _commentsService.getSystemStats();
      if (stats != null) {
        log("System stats retrieved successfully");
        return {
          'users': stats.users,
          'comments': stats.comments,
          'votes': stats.votes,
          'reports': stats.reports,
        };
      }
    } catch (e) {
      log("Error getting system stats: $e");
      snackBar('Error getting system stats');
    }
    return null;
  }
}