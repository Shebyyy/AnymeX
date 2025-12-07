import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/error_handler.dart';
import 'package:anymex/utils/performance.dart';
import 'package:anymex/utils/resource_manager.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

/// Enhanced novel reader controller with advanced features
class EnhancedNovelReaderController extends BaseController with ResourceMixin {
  Chapter initialChapter;
  List<Chapter> chapters;
  Media media;
  Source source;

  EnhancedNovelReaderController({
    required this.initialChapter,
    required this.chapters,
    required this.media,
    required this.source,
  });

  final offlineStorageController = Get.find<OfflineStorageController>();

  // Enhanced reading modes
  final Rx<EnhancedReadingMode> readingMode = EnhancedReadingMode.standard.obs;
  final Rx<EnhancedScrollMode> scrollMode = EnhancedScrollMode.smooth.obs;
  final RxBool enableAnimations = true.obs;
  final RxBool enablePageTransitions = true.obs;

  // Enhanced display settings
  final RxDouble fontSize = 16.0.obs;
  final RxDouble lineHeight = 1.6.obs;
  final RxDouble letterSpacing = 0.0.obs;
  final RxDouble wordSpacing = 0.0.obs;
  final RxDouble paragraphSpacing = 16.0.obs;
  final RxString fontFamily = 'System'.obs;
  final RxInt textAlign = 0.obs;
  final RxDouble textWidth = 0.8.obs; // 0.0 to 1.0
  final RxInt columnCount = 1.obs;

  // Enhanced theme settings
  final Rx<EnhancedThemeMode> themeMode = EnhancedThemeMode.light.obs;
  final RxDouble backgroundOpacity = 1.0.obs;
  final RxString customBackgroundColor = ''.obs;
  final RxBool enableSepiaEffect = false.obs;

  // Enhanced navigation
  final RxBool showControls = true.obs;
  final RxBool showSettings = false;
  final RxBool showTableOfContents = false.obs;
  final RxBool showSearchPanel = false;
  final RxBool showReadingProgress = true.obs;

  // Reading progress tracking
  final RxDouble readingProgress = 0.0.obs;
  final RxInt currentWordCount = 0.obs;
  final RxInt estimatedReadingTime = 0.obs;
  final RxDouble readingSpeed = 0.0.obs;
  final RxInt wordsPerMinute = 200.obs; // Average reading speed

  // Advanced features
  final RxList<NovelBookmark> bookmarks = RxList();
  final RxList<NovelAnnotation> annotations = RxList();
  final RxList<ReadingSession> readingSessions = RxList();
  final RxBool enableTextToSpeech = false.obs;
  final RxBool enableTranslation = false.obs;

  // Search functionality
  final RxString searchQuery = ''.obs;
  final RxList<SearchResult> searchResults = RxList();
  final RxInt currentSearchIndex = 0.obs;
  final RxBool searchCaseSensitive = false.obs;
  final RxBool searchWholeWords = false.obs;

  // Auto-reading features
  final RxBool autoScrollEnabled = false.obs;
  final RxDouble autoScrollSpeed = 1.0.obs;
  final RxBool autoPageTurn = false.obs;
  final RxInt autoPageDelay = 30.obs; // seconds

  // Performance and optimization
  final RxBool enableHardwareAcceleration = true.obs;
  final RxBool enableVirtualScrolling = true.obs;
  final RxInt cacheSize = 100.obs; // MB

  // Controllers and timers
  ScrollController scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _autoPageTimer;
  Timer? _readingSessionTimer;
  DateTime? _sessionStartTime;

  // Navigation
  RxBool canGoNext = true.obs;
  RxBool canGoPrevious = true.obs;

  // Auto-hide timer
  final RxBool autoHideEnabled = true.obs;
  Timer? _autoHideTimer;

  Rx<Chapter> currentChapter = Chapter().obs;
  RxString novelContent = ''.obs;
  Rx<LoadingState> loadingState = LoadingState.loading.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentChapter.value = initialChapter;
    _loadEnhancedSettings();
    _startReadingSession();
    updateNavigationButtons();
    fetchData();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    _endReadingSession();
    _saveAllData();
    _cancelAllTimers();
    scrollController.removeListener(_onScroll);
    super.onClose();
  }

  void _loadEnhancedSettings() {
    // Load enhanced reading settings
    readingMode.value = EnhancedReadingMode.values[
        settingsController.preferences.get('enhanced_reading_mode', defaultValue: 0)];
    scrollMode.value = EnhancedScrollMode.values[
        settingsController.preferences.get('enhanced_scroll_mode', defaultValue: 1)];
    enableAnimations.value = settingsController.preferences
        .get('enable_animations', defaultValue: true);
    enablePageTransitions.value = settingsController.preferences
        .get('enable_page_transitions', defaultValue: true);
    
    fontSize.value = settingsController.preferences
        .get('enhanced_font_size', defaultValue: 16.0);
    lineHeight.value = settingsController.preferences
        .get('enhanced_line_height', defaultValue: 1.6);
    letterSpacing.value = settingsController.preferences
        .get('enhanced_letter_spacing', defaultValue: 0.0);
    wordSpacing.value = settingsController.preferences
        .get('enhanced_word_spacing', defaultValue: 0.0);
    paragraphSpacing.value = settingsController.preferences
        .get('enhanced_paragraph_spacing', defaultValue: 16.0);
    fontFamily.value = settingsController.preferences
        .get('enhanced_font_family', defaultValue: 'System');
    textAlign.value = settingsController.preferences
        .get('enhanced_text_align', defaultValue: 0);
    textWidth.value = settingsController.preferences
        .get('enhanced_text_width', defaultValue: 0.8);
    columnCount.value = settingsController.preferences
        .get('enhanced_column_count', defaultValue: 1);
    
    themeMode.value = EnhancedThemeMode.values[
        settingsController.preferences.get('enhanced_theme_mode', defaultValue: 0)];
    backgroundOpacity.value = settingsController.preferences
        .get('enhanced_background_opacity', defaultValue: 1.0);
    customBackgroundColor.value = settingsController.preferences
        .get('enhanced_custom_bg_color', defaultValue: '');
    enableSepiaEffect.value = settingsController.preferences
        .get('enhanced_sepia_effect', defaultValue: false);
    
    showControls.value = settingsController.preferences
        .get('enhanced_show_controls', defaultValue: true);
    showTableOfContents.value = settingsController.preferences
        .get('enhanced_show_toc', defaultValue: false);
    showSearchPanel.value = settingsController.preferences
        .get('enhanced_show_search', defaultValue: false);
    showReadingProgress.value = settingsController.preferences
        .get('enhanced_show_progress', defaultValue: true);
    
    enableTextToSpeech.value = settingsController.preferences
        .get('enable_tts', defaultValue: false);
    enableTranslation.value = settingsController.preferences
        .get('enable_translation', defaultValue: false);
    
    autoScrollEnabled.value = settingsController.preferences
        .get('auto_scroll_enabled', defaultValue: false);
    autoScrollSpeed.value = settingsController.preferences
        .get('auto_scroll_speed', defaultValue: 1.0);
    autoPageTurn.value = settingsController.preferences
        .get('auto_page_turn', defaultValue: false);
    autoPageDelay.value = settingsController.preferences
        .get('auto_page_delay', defaultValue: 30);
    
    enableHardwareAcceleration.value = settingsController.preferences
        .get('hardware_acceleration', defaultValue: true);
    enableVirtualScrolling.value = settingsController.preferences
        .get('virtual_scrolling', defaultValue: true);
    cacheSize.value = settingsController.preferences
        .get('cache_size', defaultValue: 100);
    
    wordsPerMinute.value = settingsController.preferences
        .get('reading_speed_wpm', defaultValue: 200);
    
    // Load bookmarks and annotations
    _loadBookmarksAndAnnotations();
  }

  void _saveEnhancedSettings() {
    settingsController.preferences
        .put('enhanced_reading_mode', readingMode.value.index);
    settingsController.preferences
        .put('enhanced_scroll_mode', scrollMode.value.index);
    settingsController.preferences
        .put('enable_animations', enableAnimations.value);
    settingsController.preferences
        .put('enable_page_transitions', enablePageTransitions.value);
    
    settingsController.preferences
        .put('enhanced_font_size', fontSize.value);
    settingsController.preferences
        .put('enhanced_line_height', lineHeight.value);
    settingsController.preferences
        .put('enhanced_letter_spacing', letterSpacing.value);
    settingsController.preferences
        .put('enhanced_word_spacing', wordSpacing.value);
    settingsController.preferences
        .put('enhanced_paragraph_spacing', paragraphSpacing.value);
    settingsController.preferences
        .put('enhanced_font_family', fontFamily.value);
    settingsController.preferences
        .put('enhanced_text_align', textAlign.value);
    settingsController.preferences
        .put('enhanced_text_width', textWidth.value);
    settingsController.preferences
        .put('enhanced_column_count', columnCount.value);
    
    settingsController.preferences
        .put('enhanced_theme_mode', themeMode.value.index);
    settingsController.preferences
        .put('enhanced_background_opacity', backgroundOpacity.value);
    settingsController.preferences
        .put('enhanced_custom_bg_color', customBackgroundColor.value);
    settingsController.preferences
        .put('enhanced_sepia_effect', enableSepiaEffect.value);
    
    settingsController.preferences
        .put('enhanced_show_controls', showControls.value);
    settingsController.preferences
        .put('enhanced_show_toc', showTableOfContents.value);
    settingsController.preferences
        .put('enhanced_show_search', showSearchPanel.value);
    settingsController.preferences
        .put('enhanced_show_progress', showReadingProgress.value);
    
    settingsController.preferences
        .put('enable_tts', enableTextToSpeech.value);
    settingsController.preferences
        .put('enable_translation', enableTranslation.value);
    
    settingsController.preferences
        .put('auto_scroll_enabled', autoScrollEnabled.value);
    settingsController.preferences
        .put('auto_scroll_speed', autoScrollSpeed.value);
    settingsController.preferences
       put('auto_page_turn', autoPageTurn.value);
    settingsController.preferences
        .put('auto_page_delay', autoPageDelay.value);
    
    settingsController.preferences
        .put('hardware_acceleration', enableHardwareAcceleration.value);
    settingsController.preferences
        .put('virtual_scrolling', enableVirtualScrolling.value);
    settingsController.preferences.put('cache_size', cacheSize.value);
    settingsController.preferences
        .put('reading_speed_wpm', wordsPerMinute.value);
  }

  void _loadBookmarksAndAnnotations() {
    // Load bookmarks and annotations for current media/chapter
    final mediaId = media.id;
    final chapterId = currentChapter.value?.id ?? '';
    
    if (mediaId.isNotEmpty && chapterId.isNotEmpty) {
      // Load from storage
      _loadBookmarksFromStorage(mediaId, chapterId);
      _loadAnnotationsFromStorage(mediaId, chapterId);
    }
  }

  void _loadBookmarksFromStorage(String mediaId, String chapterId) {
    // Implement bookmark loading from storage
    // This would integrate with the storage system
  }

  void _loadAnnotationsFromStorage(String mediaId, String chapterId) {
    // Implement annotation loading from storage
    // This would integrate with the storage system
  }

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    _readingSessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateReadingStats();
    });
  }

  void _endReadingSession() {
    _readingSessionTimer?.cancel();
    if (_sessionStartTime != null) {
      final session = ReadingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        wordsRead: currentWordCount.value,
        chapterId: currentChapter.value?.id ?? '',
      );
      
      readingSessions.add(session);
      _saveReadingSessions();
    }
  }

  void _updateReadingStats() {
    // Update reading statistics
    if (scrollController.hasClients) {
      final offset = scrollController.offset;
      final maxScroll = scrollController.position.maxScrollExtent;
      
      if (maxScroll > 0) {
        final progress = offset / maxScroll;
        readingProgress.value = progress;
        
        // Estimate words read based on progress
        final totalWords = _estimateTotalWords();
        currentWordCount.value = (totalWords * progress).toInt();
        
        // Calculate reading speed
        final elapsedMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
        if (elapsedMinutes > 0) {
          readingSpeed.value = currentWordCount.value / elapsedMinutes;
        }
        
        // Estimate remaining reading time
        final remainingWords = totalWords - currentWordCount.value;
        estimatedReadingTime.value = (remainingWords / wordsPerMinute.value).ceil();
      }
    }
  }

  int _estimateTotalWords() {
    // Simple word count estimation
    final content = novelContent.value;
    if (content.isEmpty) return 0;
    
    return content.split(RegExp(r'\s+')).length;
  }

  void _saveReadingSessions() {
    // Save reading sessions to storage
    // This would integrate with the storage system
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (loadingState.value == LoadingState.loading) return;

    final offset = scrollController.offset;
    final maxScroll = scrollController.position.maxScrollExtent;

    if (offset < 0) return;
    if (offset > maxScroll) return;

    readingProgress.value = offset / maxScroll;
    _updateReadingStats();
    _resetAutoHideTimer();
  }

  void _resetAutoHideTimer() {
    if (!autoHideEnabled.value) return;
    
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (showControls.value) {
        showControls.value = false;
      }
    });
  }

  Future<void> fetchData() async {
    try {
      setLoading(true);
      _saveTracking();
      
      final data = await source.methods.getNovelContent(
        currentChapter.value.title!,
        currentChapter.value.link!
      );
      
      if (data != null && data.isNotEmpty) {
        novelContent.value = _buildEnhancedHtml(data);
        _optimizeContent();
      }
      
      loadingState.value = LoadingState.loaded;
      _waitForScrollAndJump();
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to fetch novel content',
      );
      setError('Failed to load content');
    }
  }

  String _buildEnhancedHtml(String input) {
    final width = textWidth.value > 0 ? (Get.width * textWidth.value).toInt() : Get.width;
    final columnStyle = columnCount.value > 1 ? 'columns: $columnCount; column-gap: 16px;' : '';
    
    return '''
      <div id="enhancedReaderView" style="
        padding: 2em;
        line-height: ${lineHeight.value};
        letter-spacing: ${letterSpacing.value}px;
        word-spacing: ${wordSpacing.value}px;
        text-align: ${_getTextAlignment()};
        $columnStyle
        max-width: ${width}px;
        font-family: ${_getFontFamily()};
        font-size: ${fontSize.value}px;
        background-color: ${_getBackgroundColor()};
        color: ${_getTextColor()};
        ${_getSepiaEffect()}
      ">
        ${_processContent(input)}
      </div>
    ''';
  }

  String _processContent(String input) {
    return input
        .replaceAll("\\n", "")
        .replaceAll("\\t", "")
        .replaceAll("\\\"", "\"")
        .replaceAll("*'", '')
        .replaceAll('"*', '');
  }

  void _optimizeContent() {
    // Add performance optimizations
    // This could include lazy loading of large chapters,
    // image optimization, etc.
  }

  String _getTextAlignment() {
    switch (textAlign.value) {
      case 1:
        return 'center';
      case 2:
        return 'justify';
      default:
        return 'left';
    }
  }

  String _getFontFamily() {
    switch (fontFamily.value) {
      case 'Serif':
        return 'serif';
      case 'Roboto':
        return 'Roboto';
      case 'Open Sans':
        return 'OpenSans';
      case 'Lato':
        return 'Lato';
      case 'Merriweather':
        return 'Merriweather';
      case 'Crimson Text':
        return 'Crimson Text';
      case 'Libre Baskerville':
        return 'Libre Baskerville';
      default:
        return '';
    }
  }

  String _getBackgroundColor() {
    if (customBackgroundColor.value.isNotEmpty) {
      return customBackgroundColor.value;
    }
    
    switch (themeMode.value) {
      case EnhancedThemeMode.light:
        return '#FFFFFF';
      case EnhancedThemeMode.dark:
        return '#1A1A1A';
      case EnhancedThemeMode.sepia:
        return '#F4E8D0';
      case EnhancedThemeMode.custom:
        return customBackgroundColor.value;
      default:
        return '#FFFFFF';
    }
  }

  String _getTextColor() {
    switch (themeMode.value) {
      case EnhancedThemeMode.light:
        return '#000000';
      case EnhancedThemeMode.dark:
        return '#FFFFFF';
      case EnhancedThemeMode.sepia:
        return '#000000';
      case EnhancedThemeMode.custom:
        return '#000000';
      default:
        return '#000000';
    }
  }

  String _getSepiaEffect() {
    if (!enableSepiaEffect.value) return '';
    
    return '''
      filter: sepia(100%) brightness(0.8) contrast(1.2);
    ''';
  }

  Future<void> _waitForScrollAndJump() async {
    final current = currentChapter.value.currentOffset ?? 0;
    final max = currentChapter.value.maxOffset ?? 0;

    if (current == null || max == null) return;
    if (current < 0 || current > max) return;

    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));

      if (!scrollController.hasClients) continue;
      if (scrollController.position.maxScrollExtent >= current) {
        scrollController.animateTo(
          current,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      }
    }
  }

  void _saveTracking() {
    final chapter = currentChapter.value;
    if (chapter == null) return;

    if (scrollController.hasClients) {
      final offset = scrollController.offset;
      final maxScroll = scrollController.position.maxScrollExtent;
      
      chapter.currentOffset = offset;
      chapter.maxOffset = maxScroll;
      chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
      
      final progress = offset / maxScroll;
      final totalPages = (maxScroll / Get.height).ceil() + 1;
      final currentPage = (offset / Get.height).floor() + 1;
      
      chapter.pageNumber = currentPage;
      chapter.totalPages = totalPages;
    }
    
    offlineStorageController.addOrUpdateNovel(media, chapters, chapter, source);
    offlineStorageController.addOrUpdateReadChapter(media.id, chapter, source);
  }

  void _saveAllData() {
    _saveTracking();
    _saveBookmarks();
    _saveAnnotations();
    _saveReadingSessions();
    _saveEnhancedSettings();
  }

  void _saveBookmarks() {
    // Save bookmarks to storage
  }

  void _saveAnnotations() {
    // Save annotations to storage
  }

  void _cancelAllTimers() {
    _autoScrollTimer?.cancel();
    _autoPageTimer?.cancel();
    _autoHideTimer?.cancel();
    _readingSessionTimer?.cancel();
  }

  // Enhanced navigation methods
  void updateNavigationButtons() {
    final currentIndex = chapters.indexWhere(
      (ch) => ch.link == currentChapter.value.link,
    );
    
    canGoPrevious.value = currentIndex > 0;
    canGoNext.value = currentIndex < chapters.length - 1;
  }

  Future<void> goToNextChapter() async {
    final currentIndex = chapters.indexWhere(
      (ch) => ch.link == currentChapter.value.link,
    );
    
    if (currentIndex < chapters.length - 1) {
      currentChapter.value = chapters[currentIndex + 1];
      updateNavigationButtons();
      _loadBookmarksAndAnnotations();
      await fetchData();
    }
  }

  Future<void> goToPreviousChapter() async {
    final currentIndex = chapters.indexWhere(
      (ch) => ch.link == currentChapter.value.link,
    );
    
    if (currentIndex > 0) {
      currentChapter.value = chapters[currentIndex - 1];
      updateNavigationButtons();
      _loadBookmarksAndAnnotations();
      await fetchData();
    }
  }

  void goToChapter(int index) async {
    if (index < 0 || index >= chapters.length) return;
    
    currentChapter.value = chapters[index];
    updateNavigationButtons();
    _loadBookmarksAndAnnotations();
    await fetchData();
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void scrollToPosition(double position) {
    scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Enhanced control methods
  void toggleControls() {
    showControls.value = !showControls.value;
    
    if (!showControls.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void toggleSettings() {
    showSettings.value = !showSettings.value;
  }

  void toggleTableOfContents() {
    showTableOfContents.value = !showTableOfContents.value;
  }

  void toggleSearchPanel() {
    showSearchPanel.value = !showSearchPanel.value;
  }

  void toggleReadingProgress() {
    showReadingProgress.value = !showReadingProgress.value;
  }

  // Enhanced display methods
  void increaseFontSize() {
    fontSize.value = math.min(24, fontSize.value + 1);
    _saveEnhancedSettings();
  }

  void decreaseFontSize() {
    fontSize.value = math.max(12, fontSize.value - 1);
    _saveEnhancedSettings();
  }

  void adjustLineHeight(double delta) {
    lineHeight.value = (lineHeight.value + delta).clamp(1.2, 2.0);
    _saveEnhancedSettings();
  }

  void adjustTextWidth(double delta) {
    textWidth.value = (textWidth.value + delta).clamp(0.3, 1.0);
    _saveEnhancedSettings();
  }

  void adjustColumnCount(int delta) {
    columnCount.value = (columnCount.value + delta).clamp(1, 3);
    _saveEnhancedSettings();
  }

  // Enhanced theme methods
  void toggleThemeMode(EnhancedThemeMode mode) {
    themeMode.value = mode;
    _saveEnhancedSettings();
  }

  void adjustBackgroundOpacity(double delta) {
    backgroundOpacity.value = (backgroundOpacity.value + delta).clamp(0.3, 1.0);
    _saveEnhancedSettings();
  }

  void toggleSepiaEffect() {
    enableSepiaEffect.value = !enableSepiaEffect.value;
    _saveEnhancedSettings();
  }

  void setCustomBackgroundColor(String color) {
    customBackgroundColor.value = color;
    _saveEnhancedSettings();
  }

  // Auto-reading methods
  void toggleAutoScroll() {
    autoScrollEnabled.value = !autoScrollEnabled.value;
    
    if (autoScrollEnabled.value) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(
      Duration(milliseconds: (50 / autoScrollSpeed.value).toInt()),
      (timer) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.offset + 50,
            duration: Duration.zero,
          );
        }
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void increaseAutoScrollSpeed() {
    autoScrollSpeed.value = math.min(3.0, autoScrollSpeed.value + 0.2);
    _saveEnhancedSettings();
  }

  void decreaseAutoScrollSpeed() {
    autoScrollSpeed.value = math.max(0.2, autoScrollSpeed.value - 0.2);
    _saveEnhancedSettings();
  }

  void toggleAutoPageTurn() {
    autoPageTurn.value = !autoPageTurn.value;
    
    if (autoPageTurn.value) {
      _startAutoPageTurn();
    } else {
      _stopAutoPageTurn();
    }
  }

  void _startAutoPageTurn() {
    _autoPageTimer = Timer.periodic(
      Duration(seconds: autoPageDelay.value),
      (timer) {
        _simulatePageTurn();
      },
    );
  }

  void _stopAutoPageTurn() {
    _autoPageTimer?.cancel();
    _autoPageTimer = null;
  }

  void _simulatePageTurn() {
    // Simulate page turn by scrolling
    if (scrollController.hasClients) {
      final currentOffset = scrollController.offset;
      final pageHeight = Get.height;
      final newOffset = currentOffset + pageHeight;
      
      if (newOffset < scrollController.position.maxScrollExtent) {
        scrollController.animateTo(
          newOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        toggleAutoPageTurn();
      }
    }
  }

  void adjustAutoPageDelay(int delta) {
    autoPageDelay.value = (autoPageDelay.value + delta).clamp(10, 120);
    _saveEnhancedSettings();
  }

  // Search functionality
  void performSearch(String query) {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    
    searchQuery.value = query;
    _performSearchInContent(query);
  }

  void _performSearchInContent(String query) {
    final content = novelContent.value.toLowerCase();
    final searchQuery = searchCaseSensitive.value ? query : query.toLowerCase();
    final words = searchWholeWords.value 
        ? searchQuery.split(' ')
        : searchQuery.split(RegExp(r'\W+'));
    
    searchResults.clear();
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      int index = content.indexOf(word);
      
      while (index != -1) {
        searchResults.add(SearchResult(
          text: word,
          index: index,
          context: _getContextAroundIndex(index, content),
        ));
        
        index = content.indexOf(word, index + 1);
      }
    }
    
    if (searchResults.isNotEmpty) {
      currentSearchIndex.value = 0;
      _goToSearchResult(0);
    }
  }

  String _getContextAroundIndex(int index, String content) {
    final start = math.max(0, index - 50);
    final end = math.min(content.length, index + 50);
    return content.substring(start, end);
  }

  void goToNextSearchResult() {
    if (currentSearchIndex.value < searchResults.length - 1) {
      currentSearchIndex.value++;
      _goToSearchResult(currentSearchIndex.value);
    }
  }

  void goToPreviousSearchResult() {
    if (currentSearchIndex.value > 0) {
      currentSearchIndex.value--;
      _goToSearchResult(currentSearchIndex.value);
    }
  }

  void _goToSearchResult(int index) {
    if (index < searchResults.length) {
      final result = searchResults[index];
      scrollToPosition(result.index.toDouble());
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    currentSearchIndex.value = 0;
  }

  void toggleSearchCaseSensitivity() {
    searchCaseSensitive.value = !searchCaseSensitive.value;
    _saveEnhancedSettings();
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }

  void toggleSearchWholeWords() {
    searchWholeWords.value = !searchWholeWords.value;
    _saveEnhancedSettings();
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }

  // Bookmark functionality
  void addBookmark({
    String? note,
    String? preview,
  }) {
    final bookmark = NovelBookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chapterId: currentChapter.value?.id ?? '',
      position: scrollController.offset,
      progress: readingProgress.value,
      note: note,
      preview: preview,
      createdAt: DateTime.now(),
    );
    
    bookmarks.add(bookmark);
    _saveBookmarks();
    
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      const SnackBar(content: 'Bookmark added'),
    );
  }

  void removeBookmark(String bookmarkId) {
    bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    _saveBookmarks();
    
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      const SnackBar(content: 'Bookmark removed'),
    );
  }

  void goToBookmark(NovelBookmark bookmark) {
    scrollToPosition(bookmark.position);
  }

  // Enhanced settings reset
  void resetSettings() {
    readingMode.value = EnhancedReadingMode.standard;
    scrollMode.value = EnhancedScrollMode.smooth;
    enableAnimations.value = true;
    enablePageTransitions.value = true;
    
    fontSize.value = 16.0;
    lineHeight.value = 1.6;
    letterSpacing.value = 0.0;
    wordSpacing.value = 0.0;
    paragraphSpacing.value = 16.0;
    fontFamily.value = 'System';
    textAlign.value = 0;
    textWidth.value = 0.8;
    columnCount.value = 1;
    
    themeMode.value = EnhancedThemeMode.light;
    backgroundOpacity.value = 1.0;
    customBackgroundColor.value = '';
    enableSepiaEffect.value = false;
    
    showControls.value = true;
    showTableOfContents.value = false;
    showSearchPanel.value = false;
    showReadingProgress.value = true;
    
    enableTextToSpeech.value = false;
    enableTranslation.value = false;
    
    autoScrollEnabled.value = false;
    autoScrollSpeed.value = 1.0;
    autoPageTurn.value = false;
    autoPageDelay.value = 30;
    
    enableHardwareAcceleration.value = true;
    enableVirtualScrolling.value = true;
    cacheSize.value = 100;
    wordsPerMinute.value = 200;
    
    _saveEnhancedSettings();
  }

  // Performance methods
  Map<String, dynamic> getPerformanceStats() {
    return {
      'readingProgress': readingProgress.value,
      'currentWordCount': currentWordCount.value,
      'estimatedReadingTime': estimatedReadingTime.value,
      'readingSpeed': readingSpeed.value,
      'bookmarksCount': bookmarks.length,
      'annotationsCount': annotations.length,
      'readingSessionsCount': readingSessions.length,
      'autoScrollEnabled': autoScrollEnabled.value,
      'autoScrollSpeed': autoScrollSpeed.value,
      'autoPageTurnEnabled': autoPageTurn.value,
      'autoPageDelay': autoPageDelay.value,
      'enableHardwareAcceleration': enableHardwareAcceleration.value,
      'cacheSize': cacheSize.value,
    };
  }

  void clearCache() {
    // Clear content cache
  }
}

// Enhanced enums
enum EnhancedReadingMode {
  standard,
  focus,
  speed,
}

enum EnhancedScrollMode {
  smooth,
  momentum,
  virtual,
}

enum EnhancedThemeMode {
  light,
  dark,
  sepia,
  custom,
}

// Enhanced data models
class NovelBookmark {
  final String id;
  final String chapterId;
  final double position;
  final double progress;
  final String? note;
  final String? preview;
  final DateTime createdAt;
  
  NovelBookmark({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.progress,
    this.note,
    this.preview,
    required this.createdAt,
  });
}

class NovelAnnotation {
  final String id;
  final String chapterId;
  final double position;
  final String text;
  final String? note;
  final Color color;
  final DateTime createdAt;
  
  NovelAnnotation({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.text,
    this.note,
    this.color,
    required this.createdAt,
  });
}

class ReadingSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int wordsRead;
  final String chapterId;
  
  ReadingSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.wordsRead,
    required this.chapterId,
  });
}

class SearchResult {
  final String text;
  final int index;
  final String context;
  
  SearchResult({
    required this.text,
    required this.index,
    required this.context,
  });
}