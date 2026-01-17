class Comment {
  String id;
  int contentId;
  String userId;
  String username;
  String? avatarUrl;
  String commentText;
  int likes;
  int userVote;
  int dislikes;
  String tag;
  String createdAt;
  String updatedAt;
  bool deleted;
  bool isMod;
  bool isAdmin;
  bool isSuperAdmin;
  bool isLocked;
  bool isEdited;
  bool isPinned;
  bool isReported;
  int reportCount;
  String? userVoteType; // 'upvote', 'downvote', or null
  int? parentCommentId;
  List<Comment>? replies;

  Comment({
    required this.id,
    required this.userVote,
    required this.contentId,
    required this.userId,
    required this.username,
    required this.tag,
    required this.avatarUrl,
    required this.commentText,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.isMod = false,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.isLocked = false,
    this.isEdited = false,
    this.isPinned = false,
    this.isReported = false,
    this.reportCount = 0,
    this.userVoteType,
    this.parentCommentId,
    this.replies,
  });

  factory Comment.fromMap(Map m) {
    return Comment(
      id: m['comment_id']?.toString() ?? m['id']?.toString() ?? '',
      contentId: int.parse(m['media_id'].toString()),
      tag: m['tag'] ?? '0',
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? '',
      avatarUrl: m['profile_picture_url']?.toString() ?? m['avatar_url']?.toString(),
      commentText: m['content']?.toString() ?? m['comment']?.toString() ?? '',
      likes: m['upvotes'] ?? m['likes_count'] ?? 0,
      dislikes: m['downvotes'] ?? m['dislikes_count'] ?? 0,
      createdAt: m['created_at']?.toString() ?? '',
      updatedAt: m['updated_at']?.toString() ?? '',
      deleted: m['deleted'] ?? false,
      isMod: m['is_mod'] ?? false,
      isAdmin: m['is_admin'] ?? false,
      isSuperAdmin: m['is_super_admin'] ?? false,
      isLocked: m['is_locked'] ?? false,
      isEdited: m['is_edited'] ?? false,
      isPinned: m['is_pinned'] ?? false,
      isReported: m['is_reported'] ?? false,
      reportCount: m['report_count'] ?? 0,
      userVoteType: m['user_vote'],
      parentCommentId: m['parent_comment_id'],
      replies: m['replies'] != null 
          ? (m['replies'] as List).map((r) => Comment.fromMap(r)).toList()
          : null,
      userVote: 0, // Legacy support
    );
  }

  factory Comment.fromCommentData(CommentData data) {
    return Comment(
      id: data.commentId.toString(),
      contentId: data.mediaId,
      userId: data.userId.toString(),
      username: data.username,
      avatarUrl: data.profilePictureUrl,
      commentText: data.content,
      likes: data.totalVotes,
      dislikes: 0, // Backend combines this in total_votes
      tag: '0',
      createdAt: data.createdAt.toIso8601String(),
      updatedAt: data.updatedAt.toIso8601String(),
      deleted: data.deleted,
      isMod: data.isMod,
      isAdmin: data.isAdmin,
      isSuperAdmin: data.isSuperAdmin,
      isLocked: data.isLocked,
      isEdited: false,
      isPinned: false,
      isReported: false,
      reportCount: 0,
      userVoteType: data.userVote,
      parentCommentId: data.parentCommentId,
      replies: data.replies?.map((r) => Comment.fromCommentData(r)).toList(),
      userVote: 0, // Legacy support
    );
  }

  Comment copyWith({
    String? id,
    int? contentId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? commentText,
    int? likes,
    int? userVote,
    int? dislikes,
    String? tag,
    String? createdAt,
    String? updatedAt,
    bool? deleted,
    bool? isMod,
    bool? isAdmin,
    bool? isSuperAdmin,
    bool? isLocked,
    bool? isEdited,
    bool? isPinned,
    bool? isReported,
    int? reportCount,
    String? userVoteType,
    int? parentCommentId,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      commentText: commentText ?? this.commentText,
      likes: likes ?? this.likes,
      userVote: userVote ?? this.userVote,
      dislikes: dislikes ?? this.dislikes,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      isMod: isMod ?? this.isMod,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isLocked: isLocked ?? this.isLocked,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
      userVoteType: userVoteType ?? this.userVoteType,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}

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
}
