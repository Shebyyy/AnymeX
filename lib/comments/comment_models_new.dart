enum CommentSortType {
  best,
  new,
  old,
  top,
}

enum MediaType {
  anime,
  manga,
  novel,
}

enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  moderator('moderator'),
  normalUser('normal_user');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.normalUser,
    );
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isAdmin => this == UserRole.admin || isSuperAdmin;
  bool get isModerator => this == UserRole.moderator || isAdmin;
  bool get isNormalUser => this == UserRole.normalUser;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.normalUser:
        return 'User';
    }
  }
}

enum CommentTagType {
  spoiler('spoiler'),
  nsfw('nsfw'),
  warning('warning'),
  offensive('offensive'),
  spam('spam');

  const CommentTagType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case CommentTagType.spoiler:
        return 'Spoiler';
      case CommentTagType.nsfw:
        return 'NSFW';
      case CommentTagType.warning:
        return 'Warning';
      case CommentTagType.offensive:
        return 'Offensive';
      case CommentTagType.spam:
        return 'Spam';
    }
  }
}

class CommentUser {
  final int id;
  final String username;
  final String? avatarUrl;
  final UserRole role;
  final bool isBanned;
  final bool isShadowBanned;
  final DateTime? mutedUntil;
  final String? anilistId;
  final String? malId;
  final String? simklId;
  final DateTime createdAt;

  CommentUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
    this.isBanned = false,
    this.isShadowBanned = false,
    this.mutedUntil,
    this.anilistId,
    this.malId,
    this.simklId,
    required this.createdAt,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      role: UserRole.fromString(json['role'] ?? 'normal_user'),
      isBanned: json['banned'] ?? false,
      isShadowBanned: json['shadow_banned'] ?? false,
      mutedUntil: json['muted_until'] != null 
          ? DateTime.parse(json['muted_until']) 
          : null,
      anilistId: json['anilist_id'],
      malId: json['mal_id'],
      simklId: json['simkl_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'role': role.value,
      'banned': isBanned,
      'shadow_banned': isShadowBanned,
      'muted_until': mutedUntil?.toIso8601String(),
      'anilist_id': anilistId,
      'mal_id': malId,
      'simkl_id': simklId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isMuted => mutedUntil != null && mutedUntil!.isAfter(DateTime.now());
}

class CommentVote {
  final int id;
  final int commentId;
  final int userId;
  final int voteType; // -1 for downvote, 1 for upvote
  final DateTime createdAt;

  CommentVote({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.voteType,
    required this.createdAt,
  });

  factory CommentVote.fromJson(Map<String, dynamic> json) {
    return CommentVote(
      id: json['id'] ?? 0,
      commentId: json['comment_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      voteType: json['vote_type'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CommentTag {
  final int id;
  final int commentId;
  final CommentTagType tagType;
  final int taggedBy;
  final DateTime createdAt;

  CommentTag({
    required this.id,
    required this.commentId,
    required this.tagType,
    required this.taggedBy,
    required this.createdAt,
  });

  factory CommentTag.fromJson(Map<String, dynamic> json) {
    return CommentTag(
      id: json['id'] ?? 0,
      commentId: json['comment_id'] ?? 0,
      tagType: CommentTagType.values.firstWhere(
        (type) => type.value == json['tag_type'],
        orElse: () => CommentTagType.warning,
      ),
      taggedBy: json['tagged_by'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Comment {
  final int id;
  final int mediaId;
  final MediaType mediaType;
  final int userId;
  final CommentUser user;
  final int? parentId;
  final String content;
  final String? contentHtml;
  final bool isDeleted;
  final DateTime? deletedAt;
  final int? deletedBy;
  final bool isPinned;
  final DateTime? pinnedAt;
  final int? pinnedBy;
  final bool isLocked;
  final DateTime? lockedAt;
  final int? lockedBy;
  final bool isEdited;
  final DateTime? editedAt;
  final int editCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> replies;
  final int upvotes;
  final int downvotes;
  final int totalVotes;
  final int? userVote; // -1, 0, 1
  final List<CommentTag> tags;
  final int replyCount;

  Comment({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.userId,
    required this.user,
    this.parentId,
    required this.content,
    this.contentHtml,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.isLocked = false,
    this.lockedAt,
    this.lockedBy,
    this.isEdited = false,
    this.editedAt,
    this.editCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
    this.upvotes = 0,
    this.downvotes = 0,
    this.totalVotes = 0,
    this.userVote,
    this.tags = const [],
    this.replyCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      mediaId: json['media_id'] ?? 0,
      mediaType: MediaType.values.firstWhere(
        (type) => type.name == json['media_type'],
        orElse: () => MediaType.anime,
      ),
      userId: json['user_id'] ?? 0,
      user: CommentUser.fromJson(json['user'] ?? {}),
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      contentHtml: json['content_html'],
      isDeleted: json['deleted'] ?? false,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
      deletedBy: json['deleted_by'],
      isPinned: json['pinned'] ?? false,
      pinnedAt: json['pinned_at'] != null 
          ? DateTime.parse(json['pinned_at']) 
          : null,
      pinnedBy: json['pinned_by'],
      isLocked: json['locked'] ?? false,
      lockedAt: json['locked_at'] != null 
          ? DateTime.parse(json['locked_at']) 
          : null,
      lockedBy: json['locked_by'],
      isEdited: json['edited'] ?? false,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at']) 
          : null,
      editCount: json['edit_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => Comment.fromJson(reply))
          .toList() ?? [],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
      userVote: json['user_vote'],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => CommentTag.fromJson(tag))
          .toList() ?? [],
      replyCount: json['reply_count'] ?? 0,
    );
  }

  Comment copyWith({
    int? id,
    int? mediaId,
    MediaType? mediaType,
    int? userId,
    CommentUser? user,
    int? parentId,
    String? content,
    String? contentHtml,
    bool? isDeleted,
    DateTime? deletedAt,
    int? deletedBy,
    bool? isPinned,
    DateTime? pinnedAt,
    int? pinnedBy,
    bool? isLocked,
    DateTime? lockedAt,
    int? lockedBy,
    bool? isEdited,
    DateTime? editedAt,
    int? editCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? replies,
    int? upvotes,
    int? downvotes,
    int? totalVotes,
    int? userVote,
    List<CommentTag>? tags,
    int? replyCount,
  }) {
    return Comment(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      contentHtml: contentHtml ?? this.contentHtml,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      lockedBy: lockedBy ?? this.lockedBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      editCount: editCount ?? this.editCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      totalVotes: totalVotes ?? this.totalVotes,
      userVote: userVote ?? this.userVote,
      tags: tags ?? this.tags,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  bool get canReply => !isLocked && !isDeleted;
  bool get canEdit => !isLocked && !isDeleted && !isPinned;
  bool get canDelete => !isLocked && !isDeleted && !isPinned;
  bool get hasSpoiler => tags.any((tag) => tag.tagType == CommentTagType.spoiler);
  bool get hasNsfw => tags.any((tag) => tag.tagType == CommentTagType.nsfw);
  bool get isOwnComment => user.id == userId; // This would be set by the current user context
}

class CommentThread {
  final Comment rootComment;
  final List<Comment> allComments;
  final int totalDepth;

  CommentThread({
    required this.rootComment,
    this.allComments = const [],
    this.totalDepth = 0,
  });

  factory CommentThread.fromComments(List<Comment> comments) {
    if (comments.isEmpty) {
      throw ArgumentError('Comments list cannot be empty');
    }

    final rootComments = comments.where((c) => c.parentId == null).toList();
    if (rootComments.isEmpty) {
      throw ArgumentError('No root comments found');
    }

    // For now, we'll just return the first root comment
    // In a real implementation, you might want to handle multiple threads
    final rootComment = rootComments.first;
    
    return CommentThread(
      rootComment: rootComment,
      allComments: comments,
      totalDepth: _calculateMaxDepth(rootComment, comments),
    );
  }

  static int _calculateMaxDepth(Comment comment, List<Comment> allComments) {
    if (comment.replies.isEmpty) return 0;
    
    int maxDepth = 0;
    for (final reply in comment.replies) {
      final depth = 1 + _calculateMaxDepth(reply, allComments);
      if (depth > maxDepth) maxDepth = depth;
    }
    return maxDepth;
  }
}

class CommentStats {
  final int totalComments;
  final int totalUpvotes;
  final int totalDownvotes;
  final int totalUsers;
  final DateTime? lastActivity;

  CommentStats({
    required this.totalComments,
    required this.totalUpvotes,
    required this.totalDownvotes,
    required this.totalUsers,
    this.lastActivity,
  });

  factory CommentStats.fromJson(Map<String, dynamic> json) {
    return CommentStats(
      totalComments: json['total_comments'] ?? 0,
      totalUpvotes: json['total_upvotes'] ?? 0,
      totalDownvotes: json['total_downvotes'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }
}