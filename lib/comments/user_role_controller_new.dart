import 'package:get/get.dart';
import 'comment_models_new.dart';

class UserRoleController extends GetxController {
  static UserRoleController get to => Get.find();

  final Rx<CommentUser?> _currentUser = Rx<CommentUser?>(null);
  final RxBool _isInitialized = false.obs;

  CommentUser? get currentUser => _currentUser.value;
  bool get isInitialized => _isInitialized.value;
  UserRole get userRole => _currentUser.value?.role ?? UserRole.normalUser;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isModerator => userRole.isModerator;
  bool get isAdmin => userRole.isAdmin;
  bool get isSuperAdmin => userRole.isSuperAdmin;

  @override
  void onInit() {
    super.onInit();
    _initializeMockUser();
  }

  void _initializeMockUser() {
    // Mock user for development - in real app this would come from backend
    final mockUser = CommentUser(
      id: 1,
      username: 'TestUser',
      avatarUrl: null,
      role: UserRole.normalUser, // Change this to test different roles
      isBanned: false,
      isShadowBanned: false,
      mutedUntil: null,
      anilistId: '5724017',
      malId: '13598844',
      simklId: '5081635',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );
    
    _currentUser.value = mockUser;
    _isInitialized.value = true;
  }

  void updateUserRole(UserRole newRole) {
    if (_currentUser.value != null) {
      _currentUser.value = _currentUser.value!.copyWith(role: newRole);
    }
  }

  void setUser(CommentUser user) {
    _currentUser.value = user;
    _isInitialized.value = true;
  }

  void logout() {
    _currentUser.value = null;
    _isInitialized.value = false;
  }

  // Permission checking methods
  bool canDeleteComment(Comment comment) {
    if (!isLoggedIn || currentUser == null) return false;
    
    // Users can delete their own comments (unless pinned)
    if (comment.user.id == currentUser!.id && !comment.isPinned) {
      return true;
    }
    
    // Moderators can delete any comment
    if (isModerator) {
      return true;
    }
    
    return false;
  }

  bool canEditComment(Comment comment) {
    if (!isLoggedIn || currentUser == null) return false;
    
    // Users can edit their own comments (unless pinned or locked)
    if (comment.user.id == currentUser!.id && !comment.isPinned && !comment.isLocked) {
      return true;
    }
    
    // Moderators can edit any comment
    if (isModerator) {
      return true;
    }
    
    return false;
  }

  bool canPinComment() {
    return isModerator;
  }

  bool canLockComment() {
    return isModerator;
  }

  bool canTagComment() {
    return isModerator;
  }

  bool canBanUser() {
    return isAdmin;
  }

  bool canMuteUser() {
    return isModerator;
  }

  bool canShadowBanUser() {
    return isAdmin;
  }

  bool canPromoteUser() {
    return isSuperAdmin;
  }

  bool canAccessAdminSettings() {
    return isAdmin;
  }

  bool canAccessModeratorSettings() {
    return isModerator;
  }

  bool canAccessSuperAdminSettings() {
    return isSuperAdmin;
  }

  bool canViewModerationQueue() {
    return isModerator;
  }

  bool canHandleReports() {
    return isModerator;
  }

  bool canManageRoles() {
    return isSuperAdmin;
  }

  bool canViewAuditLogs() {
    return isAdmin;
  }

  bool canManageSystemSettings() {
    return isSuperAdmin;
  }

  // Mock methods for testing different scenarios
  void mockAsNormalUser() {
    updateUserRole(UserRole.normalUser);
  }

  void mockAsModerator() {
    updateUserRole(UserRole.moderator);
  }

  void mockAsAdmin() {
    updateUserRole(UserRole.admin);
  }

  void mockAsSuperAdmin() {
    updateUserRole(UserRole.superAdmin);
  }

  void mockAsBannedUser() {
    if (_currentUser.value != null) {
      _currentUser.value = CommentUser(
        id: _currentUser.value!.id,
        username: _currentUser.value!.username,
        avatarUrl: _currentUser.value!.avatarUrl,
        role: UserRole.normalUser,
        isBanned: true,
        isShadowBanned: false,
        mutedUntil: null,
        anilistId: _currentUser.value!.anilistId,
        malId: _currentUser.value!.malId,
        simklId: _currentUser.value!.simklId,
        createdAt: _currentUser.value!.createdAt,
      );
    }
  }

  void mockAsMutedUser() {
    if (_currentUser.value != null) {
      _currentUser.value = CommentUser(
        id: _currentUser.value!.id,
        username: _currentUser.value!.username,
        avatarUrl: _currentUser.value!.avatarUrl,
        role: _currentUser.value!.role,
        isBanned: false,
        isShadowBanned: false,
        mutedUntil: DateTime.now().add(const Duration(hours: 1)),
        anilistId: _currentUser.value!.anilistId,
        malId: _currentUser.value!.malId,
        simklId: _currentUser.value!.simklId,
        createdAt: _currentUser.value!.createdAt,
      );
    }
  }
}

extension CommentUserExtension on CommentUser {
  CommentUser copyWith({
    int? id,
    String? username,
    String? avatarUrl,
    UserRole? role,
    bool? isBanned,
    bool? isShadowBanned,
    DateTime? mutedUntil,
    String? anilistId,
    String? malId,
    String? simklId,
    DateTime? createdAt,
  }) {
    return CommentUser(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      isShadowBanned: isShadowBanned ?? this.isShadowBanned,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      anilistId: anilistId ?? this.anilistId,
      malId: malId ?? this.malId,
      simklId: simklId ?? this.simklId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}