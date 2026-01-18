import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'comment_models_new.dart';
import 'user_role_controller_new.dart';

class CommentsControllerNew extends GetxController {
  final int mediaId;
  final MediaType mediaType;
  final UserRoleController _userRoleController = Get.find();

  CommentsControllerNew({
    required this.mediaId,
    required this.mediaType,
  });

  // Observables
  final RxList<Comment> _comments = <Comment>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxString _error = ''.obs;
  final Rx<CommentSortType> _sortType = CommentSortType.best.obs;
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMore = true.obs;
  final Rx<CommentStats?> _stats = Rx<CommentStats?>(null);
  final RxBool _isPostingComment = false.obs;
  final RxBool _isVoting = false.obs;

  // Text controllers
  final TextEditingController replyController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  final FocusNode replyFocusNode = FocusNode();
  final FocusNode editFocusNode = FocusNode();

  // Reply state
  final RxInt _replyingToCommentId = RxInt?>(null);
  final RxInt _editingCommentId = RxInt?>(null);
  final RxBool _showReplyInput = false.obs;

  // Getters
  List<Comment> get comments => _comments.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String get error => _error.value;
  CommentSortType get sortType => _sortType.value;
  int get currentPage => _currentPage.value;
  bool get hasMore => _hasMore.value;
  CommentStats? get stats => _stats.value;
  bool get isPostingComment => _isPostingComment.value;
  bool get isVoting => _isVoting.value;
  int? get replyingToCommentId => _replyingToCommentId.value;
  int? get editingCommentId => _editingCommentId.value;
  bool get showReplyInput => _showReplyInput.value;

  bool get canComment => _userRoleController.isLoggedIn && 
                        !_userRoleController.currentUser!.isBanned &&
                        !_userRoleController.currentUser!.isMuted;

  @override
  void onInit() {
    super.onInit();
    timeago.setLocaleMessages('en', timeago.EnMessages());
    _loadComments();
  }

  @override
  void onClose() {
    replyController.dispose();
    editController.dispose();
    replyFocusNode.dispose();
    editFocusNode.dispose();
    super.onClose();
  }

  // Loading methods
  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMore.value = true;
      _comments.clear();
    }

    if (_isLoading.value && !refresh) return;
    if (_isLoadingMore.value) return;

    if (refresh) {
      _isLoading.value = true;
    } else {
      _isLoadingMore.value = true;
    }
    _error.value = '';

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final mockComments = _generateMockComments();
      final mockStats = CommentStats(
        totalComments: mockComments.length,
        totalUpvotes: mockComments.fold(0, (sum, c) => sum + c.upvotes),
        totalDownvotes: mockComments.fold(0, (sum, c) => sum + c.downvotes),
        totalUsers: mockComments.map((c) => c.user.id).toSet().length,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      if (refresh) {
        _comments.assignAll(mockComments);
      } else {
        _comments.addAll(mockComments);
      }

      _stats.value = mockStats;
      _currentPage.value++;
      _hasMore.value = mockComments.length >= 10; // Assume 10 per page

    } catch (e) {
      _error.value = 'Failed to load comments: ${e.toString()}';
    } finally {
      _isLoading.value = false;
      _isLoadingMore.value = false;
    }
  }

  Future<void> refreshComments() async {
    await _loadComments(refresh: true);
  }

  Future<void> loadMoreComments() async {
    if (!hasMore || isLoadingMore) return;
    await _loadComments();
  }

  // Sorting methods
  void changeSortType(CommentSortType newSortType) {
    if (_sortType.value == newSortType) return;
    _sortType.value = newSortType;
    _sortComments();
  }

  void _sortComments() {
    switch (_sortType.value) {
      case CommentSortType.best:
        _comments.sort((a, b) {
          // Sort by vote score and recency
          final aScore = a.upvotes - a.downvotes;
          final bScore = b.upvotes - b.downvotes;
          if (aScore != bScore) return bScore.compareTo(aScore);
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case CommentSortType.new:
        _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CommentSortType.old:
        _comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CommentSortType.top:
        _comments.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
    }
  }

  // Comment actions
  Future<void> postComment(String content, {int? parentId}) async {
    if (!canComment || content.trim().isEmpty) return;

    _isPostingComment.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch,
        mediaId: mediaId,
        mediaType: mediaType,
        userId: _userRoleController.currentUser!.id,
        user: _userRoleController.currentUser!,
        parentId: parentId,
        content: content.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        replies: [],
        upvotes: 0,
        downvotes: 0,
        totalVotes: 0,
        userVote: 0,
        tags: [],
        replyCount: 0,
      );

      if (parentId != null) {
        _addReplyToComment(parentId, newComment);
      } else {
        _comments.insert(0, newComment);
      }

      _clearReplyState();
      _sortComments();

    } catch (e) {
      Get.snackbar('Error', 'Failed to post comment: ${e.toString()}');
    } finally {
      _isPostingComment.value = false;
    }
  }

  Future<void> voteComment(int commentId, int voteType) async {
    if (!_userRoleController.isLoggedIn || _isVoting.value) return;

    _isVoting.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay

      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return;

      final comment = _comments[commentIndex];
      int newVoteType = voteType;
      int upvotes = comment.upvotes;
      int downvotes = comment.downvotes;

      if (comment.userVote == voteType) {
        // Remove vote
        newVoteType = 0;
        if (voteType == 1) {
          upvotes--;
        } else {
          downvotes--;
        }
      } else {
        // Change or add vote
        if (comment.userVote == 1) {
          upvotes--;
        } else if (comment.userVote == -1) {
          downvotes--;
        }
        
        if (voteType == 1) {
          upvotes++;
        } else {
          downvotes++;
        }
      }

      _comments[commentIndex] = comment.copyWith(
        upvotes: upvotes,
        downvotes: downvotes,
        totalVotes: upvotes - downvotes,
        userVote: newVoteType == 0 ? null : newVoteType,
      );

    } catch (e) {
      Get.snackbar('Error', 'Failed to vote: ${e.toString()}');
    } finally {
      _isVoting.value = false;
    }
  }

  Future<void> editComment(int commentId, String newContent) async {
    if (!_userRoleController.canEditComment(_comments.firstWhereOrNull((c) => c.id == commentId))) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return;

      final comment = _comments[commentIndex];
      _comments[commentIndex] = comment.copyWith(
        content: newContent.trim(),
        isEdited: true,
        editedAt: DateTime.now(),
        editCount: comment.editCount + 1,
        updatedAt: DateTime.now(),
      );

      _clearEditState();

    } catch (e) {
      Get.snackbar('Error', 'Failed to edit comment: ${e.toString()}');
    }
  }

  Future<void> deleteComment(int commentId) async {
    if (!_userRoleController.canDeleteComment(_comments.firstWhereOrNull((c) => c.id == commentId))) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return;

      final comment = _comments[commentIndex];
      _comments[commentIndex] = comment.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        deletedBy: _userRoleController.currentUser!.id,
        content: '[deleted]',
        updatedAt: DateTime.now(),
      );

    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment: ${e.toString()}');
    }
  }

  // Moderation actions
  Future<void> pinComment(int commentId) async {
    if (!_userRoleController.canPinComment()) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return;

      final comment = _comments[commentIndex];
      _comments[commentIndex] = comment.copyWith(
        isPinned: !comment.isPinned,
        pinnedAt: comment.isPinned ? null : DateTime.now(),
        pinnedBy: comment.isPinned ? null : _userRoleController.currentUser!.id,
        updatedAt: DateTime.now(),
      );

      _sortComments();

    } catch (e) {
      Get.snackbar('Error', 'Failed to pin comment: ${e.toString()}');
    }
  }

  Future<void> lockComment(int commentId) async {
    if (!_userRoleController.canLockComment()) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return;

      final comment = _comments[commentIndex];
      _comments[commentIndex] = comment.copyWith(
        isLocked: !comment.isLocked,
        lockedAt: comment.isLocked ? null : DateTime.now(),
        lockedBy: comment.isLocked ? null : _userRoleController.currentUser!.id,
        updatedAt: DateTime.now(),
      );

    } catch (e) {
      Get.snackbar('Error', 'Failed to lock comment: ${e.toString()}');
    }
  }

  // UI state management
  void startReply(int commentId) {
    _replyingToCommentId.value = commentId;
    _showReplyInput.value = true;
    replyFocusNode.requestFocus();
  }

  void startEdit(int commentId, String currentContent) {
    _editingCommentId.value = commentId;
    editController.text = currentContent;
    editFocusNode.requestFocus();
  }

  void cancelReply() {
    _clearReplyState();
  }

  void cancelEdit() {
    _clearEditState();
  }

  void _clearReplyState() {
    _replyingToCommentId.value = null;
    _showReplyInput.value = false;
    replyController.clear();
    replyFocusNode.unfocus();
  }

  void _clearEditState() {
    _editingCommentId.value = null;
    editController.clear();
    editFocusNode.unfocus();
  }

  void _addReplyToComment(int parentId, Comment reply) {
    final parentIndex = _comments.indexWhere((c) => c.id == parentId);
    if (parentIndex != -1) {
      final parent = _comments[parentIndex];
      final updatedReplies = List<Comment>.from(parent.replies)..add(reply);
      _comments[parentIndex] = parent.copyWith(
        replies: updatedReplies,
        replyCount: parent.replyCount + 1,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Mock data generation
  List<Comment> _generateMockComments() {
    final now = DateTime.now();
    final mockUsers = [
      CommentUser(
        id: 2,
        username: 'AnimeFan99',
        avatarUrl: null,
        role: UserRole.normalUser,
        createdAt: now.subtract(const Duration(days: 200)),
      ),
      CommentUser(
        id: 3,
        username: 'ModeratorChan',
        avatarUrl: null,
        role: UserRole.moderator,
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      CommentUser(
        id: 4,
        username: 'WeebMaster',
        avatarUrl: null,
        role: UserRole.admin,
        createdAt: now.subtract(const Duration(days: 800)),
      ),
    ];

    return [
      Comment(
        id: 1,
        mediaId: mediaId,
        mediaType: mediaType,
        userId: mockUsers[0].id,
        user: mockUsers[0],
        content: 'This anime is absolutely amazing! The animation quality is top-notch and the story is so engaging. I can\'t wait for the next episode!',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        upvotes: 42,
        downvotes: 2,
        totalVotes: 40,
        userVote: 1,
        replies: [],
        replyCount: 3,
      ),
      Comment(
        id: 2,
        mediaId: mediaId,
        mediaType: mediaType,
        userId: mockUsers[1].id,
        user: mockUsers[1],
        content: 'Please remember to keep discussions civil and on-topic. Any spoilers should be properly marked. Enjoy the discussion!',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        upvotes: 15,
        downvotes: 0,
        totalVotes: 15,
        userVote: 1,
        isPinned: true,
        replies: [],
        replyCount: 0,
      ),
      Comment(
        id: 3,
        mediaId: mediaId,
        mediaType: mediaType,
        userId: mockUsers[2].id,
        user: mockUsers[2],
        content: 'The character development in this season has been phenomenal. The way they handled the protagonist\'s arc is masterful.',
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        upvotes: 28,
        downvotes: 1,
        totalVotes: 27,
        userVote: 0,
        replies: [],
        replyCount: 1,
      ),
      Comment(
        id: 4,
        mediaId: mediaId,
        mediaType: mediaType,
        userId: mockUsers[0].id,
        user: mockUsers[0],
        content: 'Does anyone else think the pacing feels a bit rushed in the latest episode?',
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        upvotes: 8,
        downvotes: 3,
        totalVotes: 5,
        userVote: 0,
        replies: [],
        replyCount: 2,
      ),
    ];
  }

  // Utility methods
  String formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'en');
  }

  Comment? findCommentById(int commentId) {
    try {
      return _comments.firstWhere((c) => c.id == commentId);
    } catch (e) {
      return null;
    }
  }

  List<Comment> getRootComments() {
    return _comments.where((c) => c.parentId == null).toList();
  }

  List<Comment> getRepliesForComment(int commentId) {
    return _comments.where((c) => c.parentId == commentId).toList();
  }
}