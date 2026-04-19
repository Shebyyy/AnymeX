import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/ai_advisor/ai_advisor_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  late final AiAdvisorService _advisorService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestions = [
    'What should I watch?',
    'Analyze my taste',
    'Why did I drop these?',
    'Give me a binge recommendation',
  ];

  @override
  void initState() {
    super.initState();
    _advisorService = Get.put(AiAdvisorService());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _advisorService.isLoading.value) return;

    _textController.clear();
    _focusNode.unfocus();

    await _advisorService.sendMessage(text);
    _scrollToBottom();
  }

  void _handleSuggestion(String suggestion) {
    _textController.text = suggestion;
    _handleSend();
  }

  void _handleNewChat() {
    _advisorService.clearChat();
  }

  void _navigateToMediaDetails(MediaRef ref) {
    final media = Media(
      id: ref.id,
      title: ref.title,
      poster: ref.cover ?? '',
      mediaType: ref.type == 'ANIME' ? ItemType.anime : ItemType.manga,
      serviceType:
          ref.service == 'mal' ? ServicesType.mal : ServicesType.anilist,
    );

    if (media.mediaType == ItemType.anime) {
      navigate(
        () => AnimeDetailsPage(
          media: media,
          tag: getRandomTag(addition: 'ai-advisor'),
        ),
      );
    } else {
      navigate(
        () => MangaDetailsPage(
          media: media,
          tag: getRandomTag(addition: 'ai-advisor'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnymexText(
          text: 'AI Advisor',
          size: 20,
          variant: TextVariant.bold,
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (_advisorService.messages.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(
                HugeIcons.strokeRoundedReload,
                color: theme.onSurface.opaque(0.7),
                size: 22,
              ),
              onPressed: _handleNewChat,
              tooltip: 'New Chat',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_advisorService.messages.isEmpty) {
                return _buildEmptyState(theme);
              }
              return _buildChatList(theme);
            }),
          ),
          _buildLoadingIndicator(theme),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.primaryContainer.opaque(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                HugeIcons.strokeRoundedAiSetting,
                size: 36,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 16),
            AnymexText(
              text: 'Your AI Anime Advisor',
              size: 20,
              variant: TextVariant.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnymexText(
              text:
                  'Ask me about anime recommendations, taste analysis, or anything about your watchlist!',
              size: 14,
              color: theme.onSurface.opaque(0.6),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) {
                return _buildSuggestionChip(theme, suggestion);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(ColorScheme theme, String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleSuggestion(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest.opaque(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.outline.opaque(0.12),
            ),
          ),
          child: AnymexText(
            text: text,
            size: 13,
            variant: TextVariant.semiBold,
            color: theme.onSurface.opaque(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(ColorScheme theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _advisorService.messages.length,
      itemBuilder: (context, index) {
        final message = _advisorService.messages[index];
        final isUser = message.role == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8, top: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.opaque(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        HugeIcons.strokeRoundedAiSetting,
                        size: 16,
                        color: theme.primary,
                      ),
                    ),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.primary
                            : theme.surfaceContainerHighest.opaque(0.4),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 6),
                          bottomRight: Radius.circular(isUser ? 6 : 18),
                        ),
                      ),
                      child: AnymexText(
                        text: message.content,
                        size: 14,
                        color: isUser
                            ? theme.onPrimary
                            : theme.onSurface,
                        maxLines: 50,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.opaque(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              // Media refs section for assistant messages
              if (!isUser &&
                  message.mediaRefs != null &&
                  message.mediaRefs!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 8),
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.mediaRefs!.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, refIndex) {
                        final ref = message.mediaRefs![refIndex];
                        return _buildMediaRefCard(theme, ref);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaRefCard(ColorScheme theme, MediaRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMediaDetails(ref),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.outline.opaque(0.12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ref.cover != null && ref.cover!.isNotEmpty
                      ? AnymeXImage(
                          imageUrl: ref.cover!,
                          width: 80,
                          height: 80,
                          radius: 0,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: theme.surfaceContainerHighest.opaque(0.3),
                          child: Icon(
                            ref.type == 'ANIME'
                                ? Icons.movie_rounded
                                : Icons.menu_book_rounded,
                            size: 24,
                            color: theme.onSurface.opaque(0.3),
                          ),
                        ),
                ),
              ),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                color: theme.surfaceContainer.opaque(0.5),
                child: AnymexText(
                  text: ref.title,
                  size: 10,
                  variant: TextVariant.semiBold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme theme) {
    return Obx(() {
      if (!_advisorService.isLoading.value) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.primaryContainer.opaque(0.4),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                HugeIcons.strokeRoundedAiSetting,
                size: 14,
                color: theme.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest.opaque(0.4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: _TypingDots(color: theme.onSurface.opaque(0.6)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInputArea(ColorScheme theme) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(
            color: theme.outline.opaque(0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.surfaceContainerHighest.opaque(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.outline.opaque(0.1),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: TextStyle(
                    color: theme.onSurface,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your advisor...',
                    hintStyle: TextStyle(
                      color: theme.onSurface.opaque(0.4),
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              return Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _advisorService.isLoading.value
                      ? theme.onSurface.opaque(0.1)
                      : theme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap:
                        _advisorService.isLoading.value ? null : _handleSend,
                    child: Center(
                      child: _advisorService.isLoading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.onSurface.opaque(0.4),
                              ),
                            )
                          : Icon(
                              HugeIcons.strokeRoundedArrowUp01,
                              size: 20,
                              color: theme.onPrimary,
                            ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay) % 1.0;
            final opacity = progress < 0.5
                ? progress * 2
                : (1.0 - progress) * 2;
            final scale = 0.8 + (opacity * 0.4);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale.clamp(0.6, 1.2),
                child: Opacity(
                  opacity: opacity.clamp(0.2, 1.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
