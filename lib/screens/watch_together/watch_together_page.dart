import 'package:anymex/services/watchium_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class WatchTogetherPage extends StatefulWidget {
  const WatchTogetherPage({super.key});

  @override
  State<WatchTogetherPage> createState() => _WatchTogetherPageState();
}

class _WatchTogetherPageState extends State<WatchTogetherPage> {
  final _roomCodeController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final WatchiumService _service = Get.find<WatchiumService>();

  List<WatchiumRoom> _publicRooms = [];
  bool _isLoadingRooms = false;

  @override
  void initState() {
    super.initState();
    _loadPublicRooms();
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _accessKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicRooms() async {
    setState(() => _isLoadingRooms = true);
    final result = await _service.listPublicRooms();
    if (mounted) {
      setState(() {
        _publicRooms = result.data ?? [];
        _isLoadingRooms = false;
      });
    }
  }

  Future<void> _joinByCode() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      warningSnackBar('Enter a room code');
      return;
    }
    final key = _accessKeyController.text.trim();
    final result = await _service.joinRoom(
      code,
      accessKey: key.isNotEmpty ? key : null,
    );
    if (mounted) {
      if (result.success) {
        successSnackBar('Joined room!');
        Get.back();
      } else {
        errorSnackBar(
          _service.error.value.isNotEmpty
              ? _service.error.value
              : 'Failed to join room',
        );
      }
    }
  }

  Future<void> _joinPublicRoom(WatchiumRoom room) async {
    final roomId = room.roomId;
    if (roomId == null || roomId.isEmpty) return;
    final result = await _service.joinRoom(roomId);
    if (mounted) {
      if (result.success) {
        successSnackBar('Joined room!');
        Get.back();
      } else {
        errorSnackBar(
          _service.error.value.isNotEmpty
              ? _service.error.value
              : 'Failed to join room',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final tt = context.theme.textTheme;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Watch Together'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Join by Code Section ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.surfaceContainer.opaque(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.outline.opaque(0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.primary.opaque(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Symbols.tag_rounded,
                                  size: 22,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnymexText(
                                      text: 'Join by Code',
                                      variant: TextVariant.bold,
                                      size: 17,
                                    ),
                                    const SizedBox(height: 3),
                                    AnymexText(
                                      text:
                                          'Enter a room code shared by your friend',
                                      size: 12,
                                      color: theme.onSurface.opaque(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Room code input
                          AnymexText(
                            text: 'Room Code',
                            size: 13,
                            color: theme.onSurface.opaque(0.7),
                            variant: TextVariant.semiBold,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _roomCodeController,
                            textCapitalization: TextCapitalization.characters,
                            style: tt.bodyLarge?.copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. ABCD-1234',
                              hintStyle: tt.bodyLarge?.copyWith(
                                color: theme.onSurface.opaque(0.35),
                                letterSpacing: 2,
                              ),
                              prefixIcon: Icon(
                                Symbols.tag_rounded,
                                color: theme.onSurface.opaque(0.4),
                              ),
                              filled: true,
                              fillColor: theme.surfaceContainerHigh
                                  .opaque(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.outline.opaque(0.15),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.outline.opaque(0.15),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.primary.opaque(0.5),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Access key input
                          AnymexText(
                            text: 'Access Key (optional)',
                            size: 13,
                            color: theme.onSurface.opaque(0.7),
                            variant: TextVariant.semiBold,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _accessKeyController,
                            obscureText: true,
                            style: tt.bodyLarge?.copyWith(
                              color: theme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Required for private rooms',
                              hintStyle: tt.bodyLarge?.copyWith(
                                color: theme.onSurface.opaque(0.35),
                              ),
                              prefixIcon: Icon(
                                Symbols.key_rounded,
                                color: theme.onSurface.opaque(0.4),
                              ),
                              filled: true,
                              fillColor: theme.surfaceContainerHigh
                                  .opaque(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.outline.opaque(0.15),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.outline.opaque(0.15),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.primary.opaque(0.5),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Join button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Obx(() {
                              final isLoading = _service.isLoading.value;
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading ? null : _joinByCode,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2.5),
                                      )
                                    : const Icon(
                                        Symbols.login_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  isLoading
                                      ? 'Joining...'
                                      : 'Join Room',
                                  style: tt.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: theme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Public Rooms Section ──
                    Row(
                      children: [
                        Icon(
                          Symbols.explore_rounded,
                          size: 20,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 8),
                        AnymexText(
                          text: 'Public Rooms',
                          variant: TextVariant.bold,
                          size: 17,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadPublicRooms,
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: theme.onSurface.opaque(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_isLoadingRooms)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_publicRooms.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Column(
                            children: [
                              Icon(
                                Symbols.group_rounded,
                                size: 56,
                                color:
                                    theme.onSurface.opaque(0.15),
                              ),
                              const SizedBox(height: 16),
                              AnymexText(
                                text: 'No public rooms right now',
                                size: 15,
                                color: theme.onSurface
                                    .opaque(0.45),
                              ),
                              const SizedBox(height: 6),
                              AnymexText(
                                text:
                                    'Create one from the player or check back later',
                                size: 12,
                                color: theme.onSurface
                                    .opaque(0.3),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._publicRooms.map((room) => _PublicRoomCard(
                            room: room,
                            onTap: () => _joinPublicRoom(room),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicRoomCard extends StatelessWidget {
  final WatchiumRoom room;
  final VoidCallback onTap;

  const _PublicRoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final tt = context.theme.textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anime poster
                if (room.animeImage != null &&
                    room.animeImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: room.animeImage!,
                      width: 52,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 52,
                        height: 72,
                        color: theme.surfaceVariant.opaque(0.3),
                        child: Icon(
                          Symbols.tv_rounded,
                          size: 22,
                          color:
                              theme.onSurface.opaque(0.2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 72,
                        color: theme.surfaceVariant.opaque(0.3),
                        child: Icon(
                          Symbols.tv_rounded,
                          size: 22,
                          color:
                              theme.onSurface.opaque(0.2),
                        ),
                      ),
                    ),
                  ),
                if (room.animeImage != null &&
                    room.animeImage!.isNotEmpty)
                  const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AnymexText(
                              text: room.title ?? 'Untitled Room',
                              variant: TextVariant.semiBold,
                              size: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primary.opaque(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Symbols.person_rounded,
                                  size: 12,
                                  color: theme.primary,
                                ),
                                const SizedBox(width: 4),
                                AnymexText(
                                  text: '${room.memberCount ?? 1}',
                                  size: 11,
                                  color: theme.primary,
                                  variant: TextVariant.semiBold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (room.animeTitle != null &&
                          room.animeTitle!.isNotEmpty)
                        AnymexText(
                          text: room.animeTitle!,
                          size: 12,
                          color: theme.onSurface.opaque(0.6),
                        ),
                      if (room.episodeNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AnymexText(
                            text: 'Episode ${room.episodeNumber}',
                            size: 11,
                            color: theme.onSurface.opaque(0.45),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Symbols.play_circle_rounded,
                            size: 13,
                            color: room.isPlaying == true
                                ? const Color(0xFF4CAF50)
                                : theme.onSurface
                                    .opaque(0.35),
                          ),
                          const SizedBox(width: 4),
                          AnymexText(
                            text: room.isPlaying == true
                                ? 'Playing'
                                : 'Paused',
                            size: 11,
                            color: room.isPlaying == true
                                ? const Color(0xFF4CAF50)
                                : theme.onSurface
                                    .opaque(0.45),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Symbols.person_rounded,
                            size: 13,
                            color: theme.onSurface.opaque(0.35),
                          ),
                          const SizedBox(width: 4),
                          AnymexText(
                            text: room.hostUsername ?? 'Host',
                            size: 11,
                            color: theme.onSurface.opaque(0.45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
