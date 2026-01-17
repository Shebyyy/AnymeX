import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anymex/utils/logger.dart' as d;
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:hive/hive.dart';

class CommentsService {
  final storage = Hive.box('auth');
  final String baseUrl = 'https://fuaomunoacfwepcnppua.supabase.co/functions/v1';
  
  void log(String msg) => d.Logger.i("[CommentsService] $msg");

  // Get the current AniList token
  Future<String?> _getAnilistToken() async {
    return await storage.get('auth_token');
  }

  // Get the current user profile
  Profile? _getCurrentUser() {
    return serviceHandler.anilistService.profileData.value;
  }

  // Make authenticated API call to Supabase Edge Functions
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAnilistToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Auth-Provider': 'anilist',
    };
  }

  // Handle API errors
  void _handleError(dynamic error, String context) {
    log("Error in $context: $error");
    if (error.toString().contains('401') || error.toString().contains('403')) {
      if (error.toString().contains('Invalid JWT')) {
        snackBar('Comments system is currently being updated. Please try again later.');
      } else {
        snackBar('Authentication failed. Please login again.');
      }
    } else if (error.toString().contains('429')) {
      snackBar('Too many requests. Please try again later.');
    } else {
      snackBar('Error: $error');
    }
  }

  // Login to comments system using AniList token
  Future<bool> login() async {
    final token = await _getAnilistToken();
    if (token == null) {
      log('No AniList token found');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/auth/login'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("Successfully logged into comments system");
        return true;
      } else {
        log("Login failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'login');
      return false;
    }
  }

  // Get comments for a specific media
  Future<List<CommentData>> getMediaComments(
    int mediaId, 
    String mediaType, {
    String sort = 'top',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/media/$mediaId/$mediaType?sort=$sort&page=$page&limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsData = data['comments'] as List<dynamic>;
        
        return commentsData.map((comment) => CommentData.fromJson(comment)).toList();
      } else {
        log("Failed to fetch comments: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _handleError(e, 'getMediaComments');
      return [];
    }
  }

  // Get comment thread with replies
  Future<CommentThreadData> getCommentThread(int commentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/thread/$commentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommentThreadData.fromJson(data);
      } else {
        log("Failed to fetch comment thread: ${response.statusCode}");
        throw Exception('Failed to fetch comment thread');
      }
    } catch (e) {
      _handleError(e, 'getCommentThread');
      rethrow;
    }
  }

  // Create a new comment
  Future<CommentData?> createComment({
    required int mediaId,
    required String mediaType,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/create'),
        headers: await _getHeaders(),
        body: json.encode({
          'media_id': mediaId,
          'media_type': mediaType,
          'content': content,
          'parent_comment_id': parentCommentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("Comment created successfully");
        return CommentData.fromJson(data['comment']);
      } else {
        log("Failed to create comment: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'createComment');
      return null;
    }
  }

  // Update a comment
  Future<CommentData?> updateComment(int commentId, String content) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/comments/update/$commentId'),
        headers: await _getHeaders(),
        body: json.encode({
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("Comment updated successfully");
        return CommentData.fromJson(data['comment']);
      } else {
        log("Failed to update comment: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'updateComment');
      return null;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/delete/$commentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        log("Comment deleted successfully");
        return true;
      } else {
        log("Failed to delete comment: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'deleteComment');
      return false;
    }
  }

  // Vote on a comment
  Future<VoteResult?> voteOnComment(int commentId, String voteType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/vote'),
        headers: await _getHeaders(),
        body: json.encode({
          'comment_id': commentId,
          'vote_type': voteType, // 'upvote' or 'downvote'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("Vote recorded successfully");
        return VoteResult.fromJson(data);
      } else {
        log("Failed to vote: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'voteOnComment');
      return null;
    }
  }

  // Get vote summary for a comment
  Future<VoteSummary?> getVoteSummary(int commentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/votes/$commentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VoteSummary.fromJson(data);
      } else {
        log("Failed to get vote summary: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'getVoteSummary');
      return null;
    }
  }

  // Report a comment
  Future<bool> reportComment(int commentId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/report'),
        headers: await _getHeaders(),
        body: json.encode({
          'comment_id': commentId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        log("Comment reported successfully");
        return true;
      } else {
        log("Failed to report comment: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'reportComment');
      return false;
    }
  }

  // Get user's comments
  Future<List<CommentData>> getUserComments(
    int userId, {
    int page = 1,
    int limit = 20,
    bool includeDeleted = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/user/$userId?page=$page&limit=$limit&include_deleted=$includeDeleted'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsData = data['comments'] as List<dynamic>;
        
        return commentsData.map((comment) => CommentData.fromJson(comment)).toList();
      } else {
        log("Failed to fetch user comments: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _handleError(e, 'getUserComments');
      return [];
    }
  }

  // Get own comment history
  Future<List<CommentData>> getOwnCommentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/history?page=$page&limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsData = data['comments'] as List<dynamic>;
        
        return commentsData.map((comment) => CommentData.fromJson(comment)).toList();
      } else {
        log("Failed to fetch comment history: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _handleError(e, 'getOwnCommentHistory');
      return [];
    }
  }

  // Moderation: Lock/unlock a thread
  Future<bool> lockThread(int commentId, bool isLocked) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moderation/thread/$commentId/lock'),
        headers: await _getHeaders(),
        body: json.encode({
          'is_locked': isLocked,
        }),
      );

      if (response.statusCode == 200) {
        log("Thread ${isLocked ? 'locked' : 'unlocked'} successfully");
        return true;
      } else {
        log("Failed to ${isLocked ? 'lock' : 'unlock'} thread: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'lockThread');
      return false;
    }
  }

  // Moderation: Soft delete a comment
  Future<bool> softDeleteComment(int commentId, String reason) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moderation/moderate/delete/$commentId'),
        headers: await _getHeaders(),
        body: json.encode({
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        log("Comment soft deleted successfully");
        return true;
      } else {
        log("Failed to soft delete comment: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'softDeleteComment');
      return false;
    }
  }

  // Moderation: Get reports
  Future<List<ReportData>> getReports({
    String status = 'open',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/reports?status=$status&page=$page&limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reportsData = data['reports'] as List<dynamic>;
        
        return reportsData.map((report) => ReportData.fromJson(report)).toList();
      } else {
        log("Failed to fetch reports: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _handleError(e, 'getReports');
      return [];
    }
  }

  // Admin: Get system stats
  Future<SystemStats?> getSystemStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SystemStats.fromJson(data);
      } else {
        log("Failed to fetch system stats: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'getSystemStats');
      return null;
    }
  }

  // Admin: Ban or unban user
  Future<bool> banUser(int userId, bool isBanned, {String? reason, int? durationDays}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/user/$userId/ban'),
        headers: await _getHeaders(),
        body: json.encode({
          'is_banned': isBanned,
          'reason': reason,
          'duration_days': durationDays,
        }),
      );

      if (response.statusCode == 200) {
        log("User ${isBanned ? 'banned' : 'unbanned'} successfully");
        return true;
      } else {
        log("Failed to ${isBanned ? 'ban' : 'unban'} user: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'banUser');
      return false;
    }
  }

  // Admin: Change user role
  Future<bool> changeUserRole(int userId, String role, {String? reason}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/user/$userId/role'),
        headers: await _getHeaders(),
        body: json.encode({
          'role': role,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        log("User role changed to $role successfully");
        return true;
      } else {
        log("Failed to change user role: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'changeUserRole');
      return false;
    }
  }

  // Admin: Get user activity
  Future<UserActivity?> getUserActivity(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/user/$userId/activity'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserActivity.fromJson(data);
      } else {
        log("Failed to fetch user activity: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _handleError(e, 'getUserActivity');
      return null;
    }
  }

  // Admin: Get moderation logs
  Future<List<ModerationLog>> getModerationLogs({
    String? action,
    int? targetUserId,
    int? performedBy,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (action != null) queryParams['action'] = action;
      if (targetUserId != null) queryParams['target_user_id'] = targetUserId.toString();
      if (performedBy != null) queryParams['performed_by'] = performedBy.toString();
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final uri = Uri.parse('$baseUrl/admin/logs').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logsData = data['logs'] as List<dynamic>;
        
        return logsData.map((log) => ModerationLog.fromJson(log)).toList();
      } else {
        log("Failed to fetch moderation logs: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      _handleError(e, 'getModerationLogs');
      return [];
    }
  }

  // Moderation: Resolve or dismiss report
  Future<bool> resolveReport(int reportId, String status, {String? notes}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moderation/reports/$reportId/resolve'),
        headers: await _getHeaders(),
        body: json.encode({
          'status': status, // 'resolved' or 'dismissed'
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        log("Report $status successfully");
        return true;
      } else {
        log("Failed to $status report: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'resolveReport');
      return false;
    }
  }

  // Moderation: Tag or untag comment
  Future<bool> tagComment(int commentId, Map<String, bool> tags) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moderation/tag/$commentId'),
        headers: await _getHeaders(),
        body: json.encode({
          'tags': tags,
        }),
      );

      if (response.statusCode == 200) {
        log("Comment tagged successfully");
        return true;
      } else {
        log("Failed to tag comment: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _handleError(e, 'tagComment');
      return false;
    }
  }
}

// Data models for the API responses
class CommentData {
  final int commentId;
  final int userId;
  final String username;
  final String? profilePictureUrl;
  final int mediaId;
  final String mediaType;
  final String content;
  final int? parentCommentId;
  final int totalVotes;
  final String? userVote;
  final bool isMod;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool isLocked;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommentData>? replies;

  CommentData({
    required this.commentId,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    required this.mediaId,
    required this.mediaType,
    required this.content,
    this.parentCommentId,
    required this.totalVotes,
    this.userVote,
    required this.isMod,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.isLocked,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      commentId: json['comment_id'],
      userId: json['user_id'],
      username: json['username'],
      profilePictureUrl: json['profile_picture_url'],
      mediaId: json['media_id'],
      mediaType: json['media_type'],
      content: json['content'],
      parentCommentId: json['parent_comment_id'],
      totalVotes: json['total_votes'] ?? 0,
      userVote: json['user_vote'],
      isMod: json['is_mod'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isSuperAdmin: json['is_super_admin'] ?? false,
      isLocked: json['is_locked'] ?? false,
      deleted: json['deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replies: json['replies'] != null 
          ? (json['replies'] as List).map((r) => CommentData.fromJson(r)).toList()
          : null,
    );
  }
}

class CommentThreadData {
  final CommentData rootComment;
  final List<CommentData> replies;
  final int totalComments;

  CommentThreadData({
    required this.rootComment,
    required this.replies,
    required this.totalComments,
  });

  factory CommentThreadData.fromJson(Map<String, dynamic> json) {
    return CommentThreadData(
      rootComment: CommentData.fromJson(json['root_comment']),
      replies: (json['replies'] as List).map((r) => CommentData.fromJson(r)).toList(),
      totalComments: json['total_comments'],
    );
  }
}

class VoteResult {
  final int upvotes;
  final int downvotes;
  final String? userVote;

  VoteResult({
    required this.upvotes,
    required this.downvotes,
    this.userVote,
  });

  factory VoteResult.fromJson(Map<String, dynamic> json) {
    return VoteResult(
      upvotes: json['upvotes'],
      downvotes: json['downvotes'],
      userVote: json['user_vote'],
    );
  }
}

class VoteSummary {
  final int upvotes;
  final int downvotes;
  final int totalVotes;

  VoteSummary({
    required this.upvotes,
    required this.downvotes,
    required this.totalVotes,
  });

  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    return VoteSummary(
      upvotes: json['upvotes'],
      downvotes: json['downvotes'],
      totalVotes: json['total_votes'],
    );
  }
}

class ReportData {
  final int reportId;
  final int commentId;
  final int reporterUserId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;
  final String? reporterProfilePictureUrl;

  ReportData({
    required this.reportId,
    required this.commentId,
    required this.reporterUserId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
    this.reporterProfilePictureUrl,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      reportId: json['report_id'],
      commentId: json['comment_id'],
      reporterUserId: json['reporter_user_id'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      reporterUsername: json['reporter_username'],
      reporterProfilePictureUrl: json['reporter_profile_picture_url'],
    );
  }
}

class SystemStats {
  final Map<String, dynamic> users;
  final Map<String, dynamic> comments;
  final Map<String, dynamic> votes;
  final Map<String, dynamic> reports;
  final Map<String, dynamic> moderation;

  SystemStats({
    required this.users,
    required this.comments,
    required this.votes,
    required this.reports,
    required this.moderation,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      users: json['users'] ?? {},
      comments: json['comments'] ?? {},
      votes: json['votes'] ?? {},
      reports: json['reports'] ?? {},
      moderation: json['moderation'] ?? {},
    );
  }
}

class UserActivity {
  final Map<String, dynamic> user;
  final Map<String, dynamic> stats;
  final List<CommentData> recentComments;
  final List<dynamic> recentVotes;
  final List<ReportData> reports;

  UserActivity({
    required this.user,
    required this.stats,
    required this.recentComments,
    required this.recentVotes,
    required this.reports,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      user: json['user'] ?? {},
      stats: json['stats'] ?? {},
      recentComments: (json['recent_comments'] as List?)
          ?.map((c) => CommentData.fromJson(c))
          .toList() ?? [],
      recentVotes: json['recent_votes'] ?? [],
      reports: (json['reports'] as List?)
          ?.map((r) => ReportData.fromJson(r))
          .toList() ?? [],
    );
  }
}

class ModerationLog {
  final int logId;
  final String action;
  final int? targetUserId;
  final int? targetCommentId;
  final int performedBy;
  final String? performedByUsername;
  final String? performedByProfilePictureUrl;
  final String? targetUsername;
  final String? targetProfilePictureUrl;
  final String? targetCommentContent;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ModerationLog({
    required this.logId,
    required this.action,
    this.targetUserId,
    this.targetCommentId,
    required this.performedBy,
    this.performedByUsername,
    this.performedByProfilePictureUrl,
    this.targetUsername,
    this.targetProfilePictureUrl,
    this.targetCommentContent,
    this.details,
    required this.createdAt,
  });

  factory ModerationLog.fromJson(Map<String, dynamic> json) {
    return ModerationLog(
      logId: json['log_id'],
      action: json['action'],
      targetUserId: json['target_user_id'],
      targetCommentId: json['target_comment_id'],
      performedBy: json['performed_by'],
      performedByUsername: json['performed_by_username'],
      performedByProfilePictureUrl: json['performed_by_profile_picture_url'],
      targetUsername: json['target_username'],
      targetProfilePictureUrl: json['target_profile_picture_url'],
      targetCommentContent: json['target_comment_content'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SystemStats {
  final Map<String, dynamic> users;
  final Map<String, dynamic> comments;
  final Map<String, dynamic> votes;
  final Map<String, dynamic> reports;

  SystemStats({
    required this.users,
    required this.comments,
    required this.votes,
    required this.reports,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      users: json['users'],
      comments: json['comments'],
      votes: json['votes'],
      reports: json['reports'],
    );
  }
}