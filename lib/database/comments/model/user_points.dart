class UserPoints {
  final String userId;
  final int totalPoints;
  final String tier;
  final String tierEmoji;
  final int currentStreak;
  final int longestStreak;
  final String? role;
  final PointsBreakdown breakdown;
  final PointsStats stats;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.tier,
    required this.tierEmoji,
    required this.currentStreak,
    required this.longestStreak,
    this.role,
    required this.breakdown,
    required this.stats,
  });

  factory UserPoints.fromMap(Map m) {
    final breakdownData = m['breakdown'] as Map? ?? {};
    final statsData = m['stats'] as Map? ?? {};

    return UserPoints(
      userId: m['user_id']?.toString() ?? '',
      totalPoints: _parseInt(m['total_points']),
      tier: m['tier']?.toString() ?? 'Newcomer',
      tierEmoji: m['tier_emoji']?.toString() ?? '🌱',
      currentStreak: _parseInt(m['current_streak']),
      longestStreak: _parseInt(m['longest_streak']),
      role: m['role']?.toString(),
      breakdown: PointsBreakdown.fromMap(breakdownData),
      stats: PointsStats.fromMap(statsData),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String getTierForPoints(int points) {
    if (points >= 5000) return 'Elite';
    if (points >= 1500) return 'Veteran';
    if (points >= 500) return 'Active';
    if (points >= 100) return 'Regular';
    return 'Newcomer';
  }

  static String getTierEmojiForPoints(int points) {
    if (points >= 5000) return '💎';
    if (points >= 1500) return '⭐';
    if (points >= 500) return '🌸';
    if (points >= 100) return '🍃';
    return '🌱';
  }

  static String getTierEmoji(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return '💎';
      case 'veteran':
        return '⭐';
      case 'active':
        return '🌸';
      case 'regular':
        return '🍃';
      default:
        return '🌱';
    }
  }
}

class PointsBreakdown {
  final int commentsPoints;
  final int repliesPoints;
  final int upvotesReceivedPoints;
  final int votesCastPoints;
  final int pinnedPoints;
  final int downvotesReceivedPoints;
  final int warningsPoints;
  final int deletedPoints;
  final int bannedPoints;
  final int streakBonus;
  final int roleBonus;

  PointsBreakdown({
    required this.commentsPoints,
    required this.repliesPoints,
    required this.upvotesReceivedPoints,
    required this.votesCastPoints,
    required this.pinnedPoints,
    required this.downvotesReceivedPoints,
    required this.warningsPoints,
    required this.deletedPoints,
    required this.bannedPoints,
    required this.streakBonus,
    required this.roleBonus,
  });

  factory PointsBreakdown.fromMap(Map m) {
    return PointsBreakdown(
      commentsPoints: UserPoints._parseInt(m['comments']),
      repliesPoints: UserPoints._parseInt(m['replies']),
      upvotesReceivedPoints: UserPoints._parseInt(m['upvotes_from_others']),
      votesCastPoints: UserPoints._parseInt(m['votes_cast']),
      pinnedPoints: UserPoints._parseInt(m['pinned']),
      downvotesReceivedPoints: UserPoints._parseInt(m['downvotes_from_others']),
      warningsPoints: UserPoints._parseInt(m['warnings']),
      deletedPoints: UserPoints._parseInt(m['mod_deletions']),
      bannedPoints: UserPoints._parseInt(m['banned']),
      streakBonus: UserPoints._parseInt(m['streak_bonus']),
      roleBonus: UserPoints._parseInt(m['role_bonus']),
    );
  }

  int get totalPositive =>
      commentsPoints +
      repliesPoints +
      upvotesReceivedPoints +
      votesCastPoints +
      pinnedPoints +
      streakBonus +
      roleBonus;

  int get totalNegative =>
      downvotesReceivedPoints.abs() +
      warningsPoints.abs() +
      deletedPoints.abs() +
      bannedPoints.abs();
}

class PointsStats {
  final int totalComments;
  final int totalReplies;
  final int totalUpvotesReceived;
  final int totalDownvotesReceived;
  final int totalVotesCast;

  PointsStats({
    required this.totalComments,
    required this.totalReplies,
    required this.totalUpvotesReceived,
    required this.totalDownvotesReceived,
    required this.totalVotesCast,
  });

  factory PointsStats.fromMap(Map m) {
    return PointsStats(
      totalComments: UserPoints._parseInt(m['total_comments']),
      totalReplies: UserPoints._parseInt(m['total_replies']),
      totalUpvotesReceived: UserPoints._parseInt(m['total_upvotes_received']),
      totalDownvotesReceived:
          UserPoints._parseInt(m['total_downvotes_received']),
      totalVotesCast: UserPoints._parseInt(m['total_votes_cast']),
    );
  }
}
