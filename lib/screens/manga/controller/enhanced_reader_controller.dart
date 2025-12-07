import 'dart:async';
import 'dart:math' as math;
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/error_handler.dart';
import 'package:anymex/utils/performance.dart';
import 'package:anymex/utils/resource_manager.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/reader/reading_stats.dart';
import 'package:anymex/screens/manga/widgets/reader/advanced_features.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Enhanced reader modes
enum MangaPageViewMode {
  continuous,
  paged,
  webtoon,
}

/// Enhanced reading direction with more options
enum MangaPageViewDirection {
  up,
  down,
  left,
  right,
  rtl, // Right-to-left for manga
  auto, // Auto-detect based on content
}

/// Enhanced reader controller with advanced features
class EnhancedReaderController extends BaseController with ResourceMixin {
  late Media media;
  late List<Chapter> chapterList;
  final Rxn<Chapter> currentChapter = Rxn();
  final RxList<PageUrl> pageList = RxList();
  late ServicesType serviceHandler;
  final bool shouldTrack;

  // Enhanced reading modes
  final Rx<MangaPageViewMode> readingLayout = MangaPageViewMode.continuous.obs;
  final Rx<MangaPageViewDirection> readingDirection = MangaPageViewDirection.down.obs;
  final RxBool autoDetectDirection = true.obs;
  final RxBool smartZoom = true.obs;
  final RxBool doubleTapToZoom = true.obs;

  // Enhanced navigation
  final RxInt currentPageIndex = 1.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;
  final RxInt preloadPages = 5.obs;
  final RxBool spacedPages = false.obs;
  final RxBool overscrollToChapter = true.obs;
  final RxBool showPageIndicator = true.obs;
  final RxBool showProgress = true.obs;

  // Enhanced controls
  final RxBool showControls = true.obs;
  final RxBool showAdvancedControls = false.obs;
  final RxBool showBookmarks = false.obs;
  final RxBool showAnnotations = false.obs;

  // Performance and optimization
  final RxInt imageQuality = 2.obs; // 0: Low, 1: Medium, 2: High
  final RxBool enableHardwareAcceleration = true.obs;
  final RxBool adaptiveQuality = true.obs;

  // Reading progress tracking
  final RxDouble readingProgress = 0.0.obs;
  final RxInt estimatedReadingTime = 0.obs;
  final RxString readingSpeed = ''.obs;

  // Advanced features
  final RxList<Bookmark> bookmarks = RxList();
  final RxList<Annotation> annotations = RxList();
  final RxList<Highlight> highlights = RxList();

  // Auto-reading features
  final RxBool autoScrollEnabled = false.obs;
  final RxDouble autoScrollSpeed = 1.0.obs;
  Timer? _autoScrollTimer;

  // Controllers
  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;
  ScrollOffsetListener? scrollOffsetListener;
  PreloadPageController? pageController;

  // Enhanced navigation
  final RxBool canGoNext = false.obs;
  final RxBool canGoPrev = false.obs;
  final RxBool canGoToNextChapter = false.obs;
  final RxBool canGoToPrevChapter = false.obs;

  // Overscroll handling
  final RxBool isOverscrolling = false.obs;
  final RxDouble overscrollProgress = 0.0.obs;
  final RxBool isOverscrollingNext = true.obs;
  double _overscrollStartOffset = 0.0;
  final double _maxOverscrollDistance = 50.0;
  Timer? _overscrollResetTimer;

  // Performance monitoring
  final RxInt pageLoadTime = 0.obs;
  final RxInt memoryUsage = 0.obs;
  final RxDouble fps = 60.0.obs;

  EnhancedReaderController({
    required this.shouldTrack,
  });

  final SourceController sourceController = Get.find<SourceController>();
  final OfflineStorageController offlineStorageController = Get.find<OfflineStorageController>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _performSave(reason: 'Reader opened');
    _initializePerformanceMonitoring();
    _loadEnhancedSettings();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _overscrollResetTimer?.cancel();
    pageController?.dispose();
    _saveAllData();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        Logger.i('App paused - saving enhanced reading progress');
        _performSave(reason: 'App paused');
        break;
      case AppLifecycleState.detached:
        Logger.i('App detached - performing final save');
        _performFinalSave();
        break;
      case AppLifecycleState.resumed:
        Logger.i('App resumed');
        break;
      case AppLifecycleState.inactive:
        Logger.i('App inactive');
        break;
      case AppLifecycleState.hidden:
        Logger.i('App hidden - saving progress');
        _performSave(reason: 'App hidden');
        break;
    }
  }

  void _initializePerformanceMonitoring() {
    // Start performance monitoring
    PerformanceMonitor.instance.startTimer('page_load');
    
    // Update FPS periodically
    registerTimer(Timer.periodic(const Duration(seconds: 1), (timer) {
      final stats = PerformanceMonitor.instance.getStats();
      fps.value = stats.fps;
      memoryUsage.value = stats.memoryUsage;
    }), key: 'fps_monitor');
  }

  void _loadEnhancedSettings() {
    // Load enhanced settings
    readingLayout.value = MangaPageViewMode.values[
        settingsController.preferences.get('enhanced_reading_layout', defaultValue: 0)];
    readingDirection.value = MangaPageViewDirection.values[
        settingsController.preferences.get('enhanced_reading_direction', defaultValue: 1)];
    autoDetectDirection.value = settingsController.preferences
        .get('auto_detect_direction', defaultValue: true);
    smartZoom.value = settingsController.preferences
        .get('smart_zoom', defaultValue: true);
    doubleTapToZoom.value = settingsController.preferences
        .get('double_tap_zoom', defaultValue: true);
    
    pageWidthMultiplier.value =
        settingsController.preferences.get('enhanced_image_width', defaultValue: 1.0);
    scrollSpeedMultiplier.value =
        settingsController.preferences.get('enhanced_scroll_speed', defaultValue: 1.0);
    spacedPages.value =
        settingsController.preferences.get('enhanced_spaced_pages', defaultValue: false);
    overscrollToChapter.value = settingsController.preferences
        .get('enhanced_overscroll_to_chapter', defaultValue: true);
    preloadPages.value =
        settingsController.preferences.get('enhanced_preload_pages', defaultValue: 5);
    showPageIndicator.value = settingsController.preferences
        .get('enhanced_show_page_indicator', defaultValue: true);
    showProgress.value = settingsController.preferences
        .get('enhanced_show_progress', defaultValue: true);
    
    imageQuality.value = settingsController.preferences
        .get('image_quality', defaultValue: 2);
    enableHardwareAcceleration.value = settingsController.preferences
        .get('hardware_acceleration', defaultValue: true);
    adaptiveQuality.value = settingsController.preferences
        .get('adaptive_quality', defaultValue: true);
  }

  void _saveEnhancedSettings() {
    settingsController.preferences
        .put('enhanced_reading_layout', readingLayout.value.index);
    settingsController.preferences
        .put('enhanced_reading_direction', readingDirection.value.index);
    settingsController.preferences
        .put('auto_detect_direction', autoDetectDirection.value);
    settingsController.preferences
        .put('smart_zoom', smartZoom.value);
    settingsController.preferences
        .put('double_tap_zoom', doubleTapToZoom.value);
    settingsController.preferences
        .put('enhanced_image_width', pageWidthMultiplier.value);
    settingsController.preferences
        .put('enhanced_scroll_speed', scrollSpeedMultiplier.value);
    settingsController.preferences.put('enhanced_spaced_pages', spacedPages.value);
    settingsController.preferences
        .put('enhanced_overscroll_to_chapter', overscrollToChapter.value);
    settingsController.preferences.put('enhanced_preload_pages', preloadPages.value);
    settingsController.preferences
        .put('enhanced_show_page_indicator', showPageIndicator.value);
    settingsController.preferences.put('enhanced_show_progress', showProgress.value);
    settingsController.preferences.put('image_quality', imageQuality.value);
    settingsController.preferences.put('hardware_acceleration', enableHardwareAcceleration.value);
    settingsController.preferences.put('adaptive_quality', adaptiveQuality.value);
  }

  Future<void> init(Media data, List<Chapter> chList, Chapter curCh) async {
    media = data;
    chapterList = chList;
    currentChapter.value = curCh;
    serviceHandler = data.serviceType;
    
    _initializeControllers();
    _loadBookmarksAndAnnotations();
    
    DiscordRPCController.instance.updateMangaPresence(
      manga: media,
      chapter: currentChapter.value!,
      totalChapters: chapterList.length.toString(),
    );

    if (curCh.link != null) {
      await fetchImagesWithOptimization(curCh.link!);
    }
    
    _updateNavigationButtons();
    _updateReadingProgress();
  }

  void _initializeControllers() {
    itemScrollController = ItemScrollController();
    scrollOffsetController = ScrollOffsetController();
    itemPositionsListener = ItemPositionsListener.create();
    scrollOffsetListener = ScrollOffsetListener.create();
    pageController = PreloadPageController(initialPage: 0);
    _setupPositionListener();
    _setupScrollListener();
  }

  void _loadBookmarksAndAnnotations() {
    // Load bookmarks and annotations for current media/chapter
    final mediaId = media.id;
    final chapterId = currentChapter.value?.id ?? '';
    
    if (mediaId.isNotEmpty && chapterId.isNotEmpty) {
      bookmarks.value = AdvancedReaderFeatures.instance.getBookmarks(mediaId, chapterId).obs;
      annotations.value = AdvancedReaderFeatures.instance.getAnnotations(mediaId, chapterId).obs;
      highlights.value = AdvancedReaderFeatures.instance.getHighlights(mediaId, chapterId).obs;
    }
  }

  Future<void> fetchImagesWithOptimization(String chapterUrl) async {
    try {
      setLoading(true);
      
      final startTime = DateTime.now();
      
      // Use performance monitoring
      PerformanceMonitor.instance.startTimer('image_fetch');
      
      final data = await sourceController.activeMangaSource.value?.methods
          .getChapterPages(chapterUrl);
      
      if (data != null && data.isNotEmpty) {
        pageList.value = data.map((url) => PageUrl(
          url: url,
          headers: _getOptimizedHeaders(),
        )).toList();
        
        _optimizeImageLoading();
      }
      
      final endTime = DateTime.now();
      pageLoadTime.value = endTime.difference(startTime).inMilliseconds;
      
      setSuccess();
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to fetch chapter pages',
      );
      setError('Failed to load pages');
    }
  }

  Map<String, String> _getOptimizedHeaders() {
    final headers = <String, String>{};
    
    // Add referer for some sources
    final baseUrl = sourceController.activeMangaSource.value?.baseUrl;
    if (baseUrl != null) {
      headers['Referer'] = baseUrl;
    }
    
    // Add quality settings
    switch (imageQuality.value) {
      case 0: // Low quality
        headers['Image-Quality'] = 'low';
        break;
      case 1: // Medium quality
        headers['Image-Quality'] = 'medium';
        break;
      case 2: // High quality
        headers['Image-Quality'] = 'high';
        break;
    }
    
    return headers;
  }

  void _optimizeImageLoading() {
    // Implement adaptive quality based on device performance
    if (adaptiveQuality.value && PerformanceUtils.isLowEndDevice()) {
      // Reduce preload pages for low-end devices
      preloadPages.value = math.max(1, preloadPages.value ~/ 2);
    }
  }

  void _updateNavigationButtons() {
    final currentIndex = chapterList.indexWhere(
      (ch) => ch.id == currentChapter.value?.id,
    );
    
    canGoPrev.value = currentIndex > 0;
    canGoNext.value = currentIndex < chapterList.length - 1;
    canGoToPrevChapter.value = canGoPrev.value;
    canGoToNextChapter.value = canGoNext.value;
  }

  void _updateReadingProgress() {
    if (pageList.isEmpty) return;
    
    final progress = currentPageIndex.value / pageList.length;
    readingProgress.value = progress;
    
    // Estimate reading time based on average speed
    final remainingPages = pageList.length - currentPageIndex.value;
    estimatedReadingTime.value = (remainingPages * 2).toInt(); // 2 seconds per page average
    
    // Calculate reading speed
    if (pageLoadTime.value > 0) {
      final speed = (1000 / pageLoadTime.value).toStringAsFixed(1);
      readingSpeed.value = '$speed pages/sec';
    }
  }

  // Enhanced navigation methods
  void goToNextPage() {
    if (currentPageIndex.value < pageList.length) {
      currentPageIndex.value++;
      _updateReadingProgress();
      _saveProgress();
    }
  }

  void goToPreviousPage() {
    if (currentPageIndex.value > 1) {
      currentPageIndex.value--;
      _updateReadingProgress();
      _saveProgress();
    }
  }

  void goToNextChapter() {
    final currentIndex = chapterList.indexWhere(
      (ch) => ch.id == currentChapter.value?.id,
    );
    
    if (currentIndex < chapterList.length - 1) {
      currentChapter.value = chapterList[currentIndex + 1];
      _updateNavigationButtons();
      _loadBookmarksAndAnnotations();
      fetchImagesWithOptimization(chapterList[currentIndex + 1].link!);
    }
  }

  void goToPreviousChapter() {
    final currentIndex = chapterList.indexWhere(
      (ch) => ch.id == currentChapter.value?.id,
    );
    
    if (currentIndex > 0) {
      currentChapter.value = chapterList[currentIndex - 1];
      _updateNavigationButtons();
      _loadBookmarksAndAnnotations();
      fetchImagesWithOptimization(chapterList[currentIndex - 1].link!);
    }
  }

  void goToPage(int pageNumber) {
    if (pageNumber > 0 && pageNumber <= pageList.length) {
      currentPageIndex.value = pageNumber;
      _updateReadingProgress();
      _saveProgress();
    }
  }

  void goToBookmark(Bookmark bookmark) {
    goToPage(bookmark.pageNumber);
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

  void toggleAdvancedControls() {
    showAdvancedControls.value = !showAdvancedControls.value;
  }

  void toggleBookmarks() {
    showBookmarks.value = !showBookmarks.value;
  }

  void toggleAnnotations() {
    showAnnotations.value = !showAnnotations.value;
  }

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
        if (itemScrollController != null) {
          itemScrollController?.scrollTo(
            itemScrollController!.position.pixels + 50,
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
  }

  void decreaseAutoScrollSpeed() {
    autoScrollSpeed.value = math.max(0.2, autoScrollSpeed.value - 0.2);
  }

  // Bookmark management
  void addBookmark({
    String? note,
    String? preview,
  }) {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mediaId: media.id,
      chapterId: currentChapter.value?.id ?? '',
      pageNumber: currentPageIndex.value,
      note: note,
      preview: preview,
      createdAt: DateTime.now(),
    );
    
    bookmarks.add(bookmark);
    AdvancedReaderFeatures.instance.addBookmark(
      mediaId: media.id,
      chapterId: currentChapter.value?.id ?? '',
      pageNumber: currentPageIndex.value,
      note: note,
      preview: preview,
    );
  }

  void removeBookmark(String bookmarkId) {
    bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    AdvancedReaderFeatures.instance.removeBookmark(bookmarkId);
  }

  // Annotation management
  void addAnnotation({
    required String text,
    String? note,
    Color? color,
  }) {
    final annotation = Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageNumber: currentPageIndex.value,
      text: text,
      note: note,
      color: color ?? Colors.yellow,
      createdAt: DateTime.now(),
    );
    
    annotations.add(annotation);
    AdvancedReaderFeatures.instance.addAnnotation(
      mediaId: media.id,
      chapterId: currentChapter.value?.id ?? '',
      pageNumber: currentPageIndex.value,
      annotation: annotation,
    );
  }

  void addHighlight({
    required String text,
    Color? color,
  }) {
    final highlight = Highlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageNumber: currentPageIndex.value,
      text: text,
      color: color ?? Colors.yellow,
      createdAt: DateTime.now(),
    );
    
    highlights.add(highlight);
    AdvancedReaderFeatures.instance.addHighlight(
      mediaId: media.id,
      chapterId: currentChapter.value?.id ?? '',
      pageNumber: currentPageIndex.value,
      highlight: highlight,
    );
  }

  // Enhanced settings methods
  void toggleReadingMode(MangaPageViewMode mode) {
    readingLayout.value = mode;
    _saveEnhancedSettings();
  }

  void toggleDirection(MangaPageViewDirection direction) {
    readingDirection.value = direction;
    autoDetectDirection.value = false;
    _saveEnhancedSettings();
  }

  void toggleSmartZoom() {
    smartZoom.value = !smartZoom.value;
    _saveEnhancedSettings();
  }

  void toggleDoubleTapToZoom() {
    doubleTapToZoom.value = !doubleTapToZoom.value;
    _saveEnhancedSettings();
  }

  void setImageQuality(int quality) {
    imageQuality.value = quality.clamp(0, 2);
    _saveEnhancedSettings();
  }

  void toggleHardwareAcceleration() {
    enableHardwareAcceleration.value = !enableHardwareAcceleration.value;
    _saveEnhancedSettings();
  }

  void toggleAdaptiveQuality() {
    adaptiveQuality.value = !adaptiveQuality.value;
    _saveEnhancedSettings();
  }

  // Progress tracking
  void _performSave({required String reason}) {
    try {
      if (!_canSaveProgress()) {
        Logger.i('Cannot save progress - invalid state ($reason)');
        return;
      }

      Logger.i('Saving enhanced reading progress - reason: $reason');
      _saveTracking();
      _saveBookmarksAndAnnotations();
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to save reading progress',
      );
    }
  }

  void _performFinalSave() {
    try {
      if (!_canSaveProgress()) {
        Logger.i('Cannot perform final save - invalid state');
        return;
      }

      Logger.i('Performing enhanced final save');
      _saveTracking();
      _saveBookmarksAndAnnotations();
      _updateOnlineProgress();
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to perform final save',
      );
    }
  }

  void _saveAllData() {
    _saveTracking();
    _saveBookmarksAndAnnotations();
    _saveEnhancedSettings();
  }

  bool _canSaveProgress() {
    final chapter = currentChapter.value;
    return chapter != null &&
        _isValidPageNumber(currentPageIndex.value) &&
        pageList.isNotEmpty;
  }

  void _saveTracking() {
    final chapter = currentChapter.value;
    if (chapter == null) return;

    if (_isValidPageNumber(currentPageIndex.value)) {
      chapter.pageNumber = currentPageIndex.value;
    }

    offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    offlineStorageController.addOrUpdateReadChapter(media.id, chapter);
  }

  void _saveBookmarksAndAnnotations() {
    // Save bookmarks and annotations to storage
    // This would integrate with a storage system
  }

  void _updateOnlineProgress() {
    if (!shouldTrack) return;

    final chapter = currentChapter.value;
    if (chapter == null || chapter.pageNumber == null) return;

    serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
      listId: media.id,
      status: "CURRENT",
      progress: chapter.pageNumber!.toInt() + 1,
      syncIds: [media.idMal],
      isAnime: false));
  }

  bool _isValidPageNumber(int pageNumber) {
    return pageNumber > 0 && pageNumber <= pageList.length;
  }

  // Enhanced settings reset
  void resetSettings() {
    readingLayout.value = MangaPageViewMode.continuous;
    readingDirection.value = MangaPageViewDirection.down;
    autoDetectDirection.value = true;
    smartZoom.value = true;
    doubleTapToZoom.value = true;
    
    pageWidthMultiplier.value = 1.0;
    scrollSpeedMultiplier.value = 1.0;
    spacedPages.value = false;
    overscrollToChapter.value = true;
    preloadPages.value = 5;
    showPageIndicator.value = true;
    showProgress.value = true;
    
    imageQuality.value = 2;
    enableHardwareAcceleration.value = true;
    adaptiveQuality.value = true;
    
    _saveEnhancedSettings();
  }

  // Performance methods
  Map<String, dynamic> getPerformanceStats() {
    return {
      'pageLoadTime': pageLoadTime.value,
      'memoryUsage': memoryUsage.value,
      'fps': fps.value,
      'currentPage': currentPageIndex.value,
      'totalPages': pageList.length,
      'readingProgress': readingProgress.value,
      'estimatedReadingTime': estimatedReadingTime.value,
      'bookmarksCount': bookmarks.length,
      'annotationsCount': annotations.length,
      'highlightsCount': highlights.length,
    };
  }

  void clearCache() {
    // Clear image cache
    // This would integrate with the image loading system
  }
}