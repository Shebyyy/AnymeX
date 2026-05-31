import 'package:anymex/services/watchium_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:share_plus/share_plus.dart';

/// A modal bottom sheet for the Watch Together feature with three tabs:
/// - **Create Room**: title field, public/private toggle, create button.
/// - **Join Room**: room code input, optional access key, join button.
/// - **Room Info** (only when in a room): room details, member list,
///   sync indicators, comments, leave/end room actions.
class WatchRoomBottomSheet extends StatefulWidget {
  /// Optional anime metadata to pre-fill when creating a room.
  final String? animeId;
  final String? animeTitle;
  final int? episodeNumber;
  final String? videoUrl;
  final List<WatchiumVideoUrl>? videoUrls;
  final String? sourceId;
  final String? anilistId;
  final String? malId;
  final String? simklId;

  const WatchRoomBottomSheet({
    super.key,
    this.animeId,
    this.animeTitle,
    this.episodeNumber,
    this.videoUrl,
    this.videoUrls,
    this.sourceId,
    this.anilistId,
    this.malId,
    this.simklId,
  });

  /// Convenience method to show the bottom sheet with anime context.
  static Future<void> show(
    BuildContext context, {
    String? animeId,
    String? animeTitle,
    int? episodeNumber,
    String? videoUrl,
    List<WatchiumVideoUrl>? videoUrls,
    String? sourceId,
    String? anilistId,
    String? malId,
    String? simklId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WatchRoomBottomSheet(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeNumber: episodeNumber,
        videoUrl: videoUrl,
        videoUrls: videoUrls,
        sourceId: sourceId,
        anilistId: anilistId,
        malId: malId,
        simklId: simklId,
      ),
    );
  }

  @override
  State<WatchRoomBottomSheet> createState() => _WatchRoomBottomSheetState();
}

class _WatchRoomBottomSheetState extends State<WatchRoomBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late TabController _tabController;

  // ── Create Room ──────────────────────────────────────────────────
  final _createTitleController = TextEditingController();
  bool _isPublic = true;

  // ── Join Room ────────────────────────────────────────────────────
  final _roomCodeController = TextEditingController();
  final _accessKeyController = TextEditingController();

  // ── Room Info ────────────────────────────────────────────────────
  final _commentController = TextEditingController();

  WatchiumService? _service;

  @override
  void initState() {
    super.initState();

    _service = _tryGetService();

    // Determine initial tab index.
    final isInRoom = _service?.isInRoom.value ?? false;
    final initialIndex = isInRoom ? 2 : 0;

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);

    // Pre-fill the create title with anime title when available.
    _createTitleController.text = _service?.currentRoom.value?.animeTitle ?? '';

    // Slide + fade animations matching the existing DynamicBottomSheet pattern.
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
  }

  WatchiumService? _tryGetService() {
    try {
      return Get.find<WatchiumService>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _tabController.dispose();
    _createTitleController.dispose();
    _roomCodeController.dispose();
    _accessKeyController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _close() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    if (mounted) Get.back();
  }

  // ── Copy helper ─────────────────────────────────────────────────
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    successSnackBar('Copied to clipboard');
  }

  // ── Tab content builders ────────────────────────────────────────
  Widget _buildCreateRoomTab(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room title
          Text('Room Title', style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _createTitleController,
            style: tt.bodyLarge?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Let\'s watch together!',
              hintStyle: tt.bodyLarge?.copyWith(
                color: cs.onSurface.opaque(0.4, iReallyMeanIt: true),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHigh.opaque(0.5, iReallyMeanIt: true),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.primary.opaque(0.5, iReallyMeanIt: true),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Public / Private toggle
          Text('Room Visibility', style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _VisibilityOption(
                  label: 'Public',
                  subtitle: 'Anyone with code can join',
                  icon: Symbols.public_rounded,
                  isSelected: _isPublic,
                  onTap: () => setState(() => _isPublic = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisibilityOption(
                  label: 'Private',
                  subtitle: 'Requires access key',
                  icon: Symbols.lock_rounded,
                  isSelected: !_isPublic,
                  onTap: () => setState(() => _isPublic = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Create button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleCreateRoom,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Symbols.add_circle_rounded, size: 20),
              label: Text(
                _isLoading ? 'Creating...' : 'Create Room',
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isLoading => _service?.isLoading.value ?? false;

  Future<void> _handleCreateRoom() async {
    final service = _service;
    if (service == null) return;

    final title = _createTitleController.text.trim();
    if (title.isEmpty) {
      warningSnackBar('Please enter a room title');
      return;
    }

    // Use anime metadata from widget props (passed from player controller),
    // falling back to current room data if already in a room.
    final room = service.currentRoom.value;
    final animeId = widget.animeId ?? room?.animeId ?? '';
    final animeTitle = widget.animeTitle ?? room?.animeTitle ?? title;
    final episodeNumber = widget.episodeNumber ?? room?.episodeNumber ?? 1;
    final videoUrl = widget.videoUrl ?? room?.videoUrl ?? '';
    final videoUrls = widget.videoUrls ?? room?.videoUrls;
    final sourceId = widget.sourceId ?? room?.sourceId;
    final anilistId = widget.anilistId ?? room?.anilistId;
    final malId = widget.malId ?? room?.malId;
    final simklId = widget.simklId ?? room?.simklId;

    final success = await service.createRoom(
      title: title,
      animeId: animeId,
      animeTitle: animeTitle,
      episodeNumber: episodeNumber,
      videoUrl: videoUrl,
      videoUrls: videoUrls,
      sourceId: sourceId,
      anilistId: anilistId,
      malId: malId,
      simklId: simklId,
      isPublic: _isPublic,
    );

    if (success.success && mounted) {
      successSnackBar('Room created!');
      // Switch to room info tab
      _tabController.animateTo(2);
    } else if (mounted) {
      errorSnackBar(service.error.value.isNotEmpty
          ? service.error.value
          : 'Failed to create room');
    }
  }

  Widget _buildJoinRoomTab(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room code
          Text('Room Code', style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _roomCodeController,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. ABCD-1234',
              hintStyle: tt.bodyLarge?.copyWith(
                color: cs.onSurface.opaque(0.4, iReallyMeanIt: true),
                letterSpacing: 2,
              ),
              prefixIcon: Icon(
                Symbols.tag_rounded,
                color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHigh.opaque(0.5, iReallyMeanIt: true),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.primary.opaque(0.5, iReallyMeanIt: true),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Optional access key
          Text('Access Key (optional)', style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _accessKeyController,
            obscureText: true,
            style: tt.bodyLarge?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Required for private rooms',
              hintStyle: tt.bodyLarge?.copyWith(
                color: cs.onSurface.opaque(0.4, iReallyMeanIt: true),
              ),
              prefixIcon: Icon(
                Symbols.key_rounded,
                color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHigh.opaque(0.5, iReallyMeanIt: true),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.primary.opaque(0.5, iReallyMeanIt: true),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 28),

          // Join button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleJoinRoom,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Symbols.login_rounded, size: 20),
              label: Text(
                _isLoading ? 'Joining...' : 'Join Room',
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinRoom() async {
    final service = _service;
    if (service == null) return;

    final roomCode = _roomCodeController.text.trim().toUpperCase();
    if (roomCode.isEmpty) {
      warningSnackBar('Please enter a room code');
      return;
    }

    final accessKey = _accessKeyController.text.trim();
    if (accessKey.isEmpty) {
      // Try joining without key (public room).
    }

    final success = await service.joinRoom(
      roomCode,
      accessKey: accessKey.isNotEmpty ? accessKey : null,
    );

    if (success.success && mounted) {
      successSnackBar('Joined room!');
      _tabController.animateTo(2);
    } else if (mounted) {
      errorSnackBar(service.error.value.isNotEmpty
          ? service.error.value
          : 'Failed to join room');
    }
  }

  Widget _buildRoomInfoTab(BuildContext context) {
    final service = _service;
    if (service == null) {
      return const Center(
        child: Text('Watch Together service unavailable'),
      );
    }

    return Obx(() {
      final room = service.currentRoom.value;
      final members = service.members;
      final isHost = service.isHost.value;
      final syncState = service.syncState.value;
      final comments = service.roomComments;

      if (room == null) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.group_rounded,
                  size: 48,
                  color: context.theme.colorScheme.onSurface.opaque(
                    0.3,
                    iReallyMeanIt: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not in a room',
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    color: context.theme.colorScheme.onSurface.opaque(
                      0.5,
                      iReallyMeanIt: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create or join a room to watch together',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface.opaque(
                      0.4,
                      iReallyMeanIt: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Room Header ────────────────────────────────────────
              _RoomHeaderCard(room: room),
              const SizedBox(height: 16),

              // ── Room Code ─────────────────────────────────────────
              _RoomCodeCard(
                roomId: room.roomId ?? '',
                accessKey: room.accessKey,
                isPublic: room.isPublic ?? true,
              ),
              const SizedBox(height: 16),

              // ── Sync Status ───────────────────────────────────────
              _SyncStatusCard(syncState: syncState),
              const SizedBox(height: 16),

              // ── Members ──────────────────────────────────────────
              _MembersSection(members: members),
              const SizedBox(height: 20),

              // ── Comments ──────────────────────────────────────────
              _CommentsSection(
                comments: comments,
                commentController: _commentController,
                service: service,
              ),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────────
              _RoomActionsSection(
                isHost: isHost,
                onLeave: () async {
                  final left = await service.leaveRoom();
                  if (left && mounted) {
                    successSnackBar('Left the room');
                    _close();
                  }
                },
                onEndRoom: () async {
                  final deleted = await service.deleteRoom();
                  if (deleted && mounted) {
                    successSnackBar('Room ended');
                    _close();
                  }
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                    minHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: cs.outline.opaque(0.2, iReallyMeanIt: true),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.opaque(0.08, iReallyMeanIt: true),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                      BoxShadow(
                        color: Colors.black.opaque(0.25, iReallyMeanIt: true),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.outline.opaque(0.3, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Title row
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      cs.primary.opaque(0.1, iReallyMeanIt: true),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Symbols.group_rounded,
                                  size: 20,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Watch Together',
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _close,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceVariant
                                        .opaque(0.3, iReallyMeanIt: true),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: cs.onSurface
                                        .opaque(0.7, iReallyMeanIt: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tab bar
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Obx(() {
                          final isInRoom =
                              _service?.isInRoom.value ?? false;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 2.5,
                              indicatorColor: cs.primary,
                              unselectedLabelColor: cs.onSurface.opaque(
                                  0.45, iReallyMeanIt: true),
                              labelColor: cs.primary,
                              labelStyle: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              tabs: [
                                const Tab(text: 'Create'),
                                const Tab(text: 'Join'),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Room'),
                                      if (isInRoom) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),

                      // Tab content
                      Flexible(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCreateRoomTab(context),
                            _buildJoinRoomTab(context),
                            _buildRoomInfoTab(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sub-widgets used inside the bottom sheet
// ═══════════════════════════════════════════════════════════════════

class _VisibilityOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.opaque(0.12, iReallyMeanIt: true)
              : cs.surfaceContainerHigh.opaque(0.4, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? cs.primary.opaque(0.35, iReallyMeanIt: true)
                : cs.outline.opaque(0.15, iReallyMeanIt: true),
            width: isSelected ? 1.0 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        cs.primary.opaque(0.12, iReallyMeanIt: true),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? cs.primary : cs.onSurface.opaque(0.6, iReallyMeanIt: true)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomHeaderCard extends StatelessWidget {
  final WatchiumRoom room;

  const _RoomHeaderCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.opaque(0.5, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.opaque(0.15, iReallyMeanIt: true),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  room.title ?? '',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(
                  room.isPublic == true
                      ? Symbols.public_rounded
                      : Symbols.lock_rounded,
                  size: 14,
                  color: cs.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
                label: Text(
                  room.isPublic == true ? 'Public' : 'Private',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide.none,
                backgroundColor: cs.surfaceVariant.opaque(0.5, iReallyMeanIt: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Symbols.tv_rounded,
                size: 16,
                color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
              const SizedBox(width: 6),
              Text(
                room.animeTitle ?? '',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Text(
                'E${room.episodeNumber}',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  backgroundColor:
                      cs.primary.opaque(0.1, iReallyMeanIt: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String roomId;
  final String? accessKey;
  final bool isPublic;

  const _RoomCodeCard({
    required this.roomId,
    this.accessKey,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.opaque(0.5, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.opaque(0.15, iReallyMeanIt: true),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Code',
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.opaque(0.6, iReallyMeanIt: true),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primary.opaque(0.06, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.opaque(0.15, iReallyMeanIt: true),
                    ),
                  ),
                  child: Text(
                    roomId.toUpperCase(),
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconButton(
                icon: Symbols.content_copy_rounded,
                tooltip: 'Copy Code',
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: roomId.toUpperCase()));
                  successSnackBar('Room code copied');
                },
                color: cs.primary,
              ),
              _IconButton(
                icon: Symbols.share_rounded,
                tooltip: 'Share',
                onTap: () {
                  Share.share(
                    'Join my watch room! Code: ${roomId.toUpperCase()}',
                  );
                },
                color: cs.primary,
              ),
            ],
          ),
          if (!isPublic && accessKey != null && accessKey!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Access Key',
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.opaque(0.6, iReallyMeanIt: true),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant
                          .opaque(0.5, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '••••••••',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
                        letterSpacing: 3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: Symbols.content_copy_rounded,
                  tooltip: 'Copy Key',
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: accessKey!));
                    successSnackBar('Access key copied');
                  },
                  color: cs.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final WatchiumSyncState syncState;

  const _SyncStatusCard({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isSynced = syncState.isSynced;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSynced
            ? const Color(0xFF4CAF50).opaque(0.08, iReallyMeanIt: true)
            : const Color(0xFFFFB74D).opaque(0.08, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSynced
              ? const Color(0xFF4CAF50).opaque(0.2, iReallyMeanIt: true)
              : const Color(0xFFFFB74D).opaque(0.2, iReallyMeanIt: true),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSynced
                  ? const Color(0xFF4CAF50).opaque(0.15, iReallyMeanIt: true)
                  : const Color(0xFFFFB74D).opaque(0.15, iReallyMeanIt: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSynced
                  ? Symbols.check_circle_rounded
                  : Symbols.sync_rounded,
              size: 18,
              color: isSynced
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFFB74D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSynced ? 'Synced' : 'Syncing...',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSynced
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFB74D),
                  ),
                ),
                if (!isSynced)
                  Text(
                    'Waiting for sync...',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final List<WatchiumMember> members;

  const _MembersSection({required this.members});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Members',
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.opaque(0.1, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${members.length}',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...members.map((member) => _MemberTile(member: member)),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final WatchiumMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.opaque(0.35, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outline.opaque(0.1, iReallyMeanIt: true),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(context),
            const SizedBox(width: 12),

            // Username + host badge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      member.username ?? '',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.isHost == true) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Symbols.workspace_premium_rounded,
                      size: 16,
                      color: const Color(0xFFFFD54F),
                    ),
                  ],
                ],
              ),
            ),

            // Sync indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: member.isSynced == true
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFB74D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (member.isSynced == true
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFB74D))
                        .opaque(0.4, iReallyMeanIt: true),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final cs = context.theme.colorScheme;
    final hasAvatar =
        member.avatarUrl != null && member.avatarUrl!.isNotEmpty;

    if (!hasAvatar) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.primary.opaque(0.12, iReallyMeanIt: true),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            (member.username ?? '').isNotEmpty ? (member.username ?? '')[0].toUpperCase() : '?',
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: member.avatarUrl!,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 36,
          height: 36,
          color: cs.primary.opaque(0.12, iReallyMeanIt: true),
          child: Center(
            child: Text(
              (member.username ?? '').isNotEmpty
                  ? (member.username ?? '')[0].toUpperCase()
                  : '?',
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final List<WatchiumComment> comments;
  final TextEditingController commentController;
  final WatchiumService service;

  const _CommentsSection({
    required this.comments,
    required this.commentController,
    required this.service,
  });

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    final text = widget.commentController.text.trim();
    if (text.isEmpty) return;

    widget.commentController.clear();
    HapticFeedback.lightImpact();

    final success = await widget.service.sendComment(text);
    if (success.success) {
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      errorSnackBar(widget.service.error.value.isNotEmpty
          ? widget.service.error.value
          : 'Failed to send comment');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),

        // Comments list
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.opaque(0.3, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outline.opaque(0.1, iReallyMeanIt: true),
              width: 0.5,
            ),
          ),
          child: widget.comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No comments yet. Say something!',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.opaque(0.35, iReallyMeanIt: true),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: widget.comments.length,
                  itemBuilder: (context, index) {
                    final comment = widget.comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.primary
                                  .opaque(0.1, iReallyMeanIt: true),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (comment.username ?? '').isNotEmpty
                                    ? (comment.username ?? '')[0].toUpperCase()
                                    : '?',
                                style: tt.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.username ?? '',
                                      style: tt.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.opaque(
                                            0.7,
                                            iReallyMeanIt: true),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (comment.videoTimestamp != null)
                                      Text(
                                        _formatTimestamp(
                                            comment.videoTimestamp!),
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.primary.opaque(
                                              0.6,
                                              iReallyMeanIt: true),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comment.message ?? '',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurface.opaque(
                                        0.85,
                                        iReallyMeanIt: true),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 10),

        // Comment input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.commentController,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.opaque(0.35, iReallyMeanIt: true),
                  ),
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHigh.opaque(0.4, iReallyMeanIt: true),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.outline.opaque(0.15, iReallyMeanIt: true),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.outline.opaque(0.15, iReallyMeanIt: true),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.primary.opaque(0.4, iReallyMeanIt: true),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(Symbols.send_rounded, size: 18),
                color: cs.onPrimary,
                onPressed: _sendComment,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _RoomActionsSection extends StatelessWidget {
  final bool isHost;
  final VoidCallback onLeave;
  final VoidCallback onEndRoom;

  const _RoomActionsSection({
    required this.isHost,
    required this.onLeave,
    required this.onEndRoom,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      children: [
        // Leave Room button (always visible)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Symbols.logout_rounded, size: 18),
            label: Text(
              'Leave Room',
              style: tt.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: cs.error.opaque(0.4, iReallyMeanIt: true),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: cs.error,
            ),
          ),
        ),

        // End Room button (host only)
        if (isHost) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Confirm before ending
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'End Room?',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.error,
                      ),
                    ),
                    content: Text(
                      'This will remove all members and close the room. This action cannot be undone.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.opaque(
                            0.7, iReallyMeanIt: true),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onEndRoom();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('End Room'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Symbols.delete_forever_rounded, size: 18),
              label: Text(
                'End Room for Everyone',
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A small circular icon button used in the room code card.
class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.opaque(0.08, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.opaque(0.15, iReallyMeanIt: true),
              width: 0.5,
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
