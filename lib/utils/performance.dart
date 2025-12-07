import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/error_handler.dart';
import 'package:anymex/utils/resource_manager.dart';

/// Performance monitoring and optimization utilities
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();
  
  PerformanceMonitor._() {
    _initialize();
  }
  
  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _metrics = {};
  final RxInt _frameTime = 0.obs;
  final RxDouble _cpuUsage = 0.0.obs;
  final RxInt _memoryUsage = 0.obs;
  final RxInt _activeWidgets = 0.obs;
  
  int get frameTime => _frameTime.value;
  double get cpuUsage => _cpuUsage.value;
  int get memoryUsage => _memoryUsage.value;
  int get activeWidgets => _activeWidgets.value;
  
  void _initialize() {
    // Monitor frame rendering time
    WidgetsBinding.instance.addTimingsCallback(_onTimingsCallback);
    
    // Monitor memory usage
    Timer.periodic(const Duration(seconds: 5), (_) => _updateMemoryUsage());
    
    Logger.i('Performance monitor initialized', 'PerformanceMonitor');
  }
  
  void _onTimingsCallback(List<ui.FrameTiming> timings) {
    if (timings.isEmpty) return;
    
    final totalFrameTime = timings.fold<int>(
      0,
      (sum, timing) => sum + timing.totalSpan.inMicroseconds,
    );
    
    _frameTime.value = totalFrameTime ~/ timings.length;
    
    // Log performance warnings
    if (_frameTime.value > 16666) { // > 60fps (16.666ms)
      final fps = 1000000 / _frameTime.value;
      Logger.w('Low FPS detected: ${fps.toStringAsFixed(1)}', 'PerformanceMonitor');
    }
  }
  
  void _updateMemoryUsage() {
    // This is a simplified memory monitoring
    // In a real implementation, you'd use platform-specific APIs
    try {
      final info = ProcessInfo.currentRss;
      _memoryUsage.value = info;
    } catch (e) {
      // Memory monitoring not available on this platform
    }
  }
  
  /// Start timing an operation
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  /// End timing an operation and record the duration
  int endTimer(String name) {
    final timer = _timers[name];
    if (timer == null) return 0;
    
    timer.stop();
    final duration = timer.elapsedMicroseconds;
    
    // Record metric
    _metrics.putIfAbsent(name, () => []).add(duration);
    
    // Keep only last 100 measurements
    final metrics = _metrics[name]!;
    if (metrics.length > 100) {
      metrics.removeRange(0, metrics.length - 100);
    }
    
    _timers.remove(name);
    
    return duration;
  }
  
  /// Get average time for an operation
  double getAverageTime(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return 0.0;
    
    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }
  
  /// Get performance statistics
  PerformanceStats getStats() {
    return PerformanceStats(
      frameTime: _frameTime.value,
      fps: _frameTime.value > 0 ? 1000000 / _frameTime.value : 0.0,
      memoryUsage: _memoryUsage.value,
      activeTimers: _timers.length,
      recordedMetrics: _metrics.length,
    );
  }
  
  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _timers.clear();
    Logger.i('Performance metrics cleared', 'PerformanceMonitor');
  }
}

/// Performance statistics
class PerformanceStats {
  final int frameTime;
  final double fps;
  final int memoryUsage;
  final int activeTimers;
  final int recordedMetrics;
  
  const PerformanceStats({
    required this.frameTime,
    required this.fps,
    required this.memoryUsage,
    required this.activeTimers,
    required this.recordedMetrics,
  });
  
  @override
  String toString() {
    return 'PerformanceStats('
        'frameTime: ${frameTime}μs, '
        'fps: ${fps.toStringAsFixed(1)}, '
        'memory: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
        'timers: $activeTimers, '
        'metrics: $recordedMetrics'
        ')';
  }
}

/// Widget for monitoring widget rebuilds
class PerformanceWidget extends StatelessWidget {
  final Widget child;
  final String? name;
  
  const PerformanceWidget({
    Key? key,
    required this.child,
    this.name,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (name != null) {
      PerformanceMonitor.instance.startTimer('widget_$name');
    }
    
    return child;
  }
}

/// Performance-optimized list view
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double? itemExtent;
  
  const OptimizedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      itemCount: items.length,
      cacheExtent: 250.0, // Optimize cache extent
      addAutomaticKeepAlives: false, // Disable keep alives for better performance
      addRepaintBoundaries: false, // Disable repaint boundaries
      addSemanticIndexes: false, // Disable semantic indexes for better performance
      itemBuilder: (context, index) {
        return PerformanceWidget(
          name: 'list_item_$index',
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Performance-optimized grid view
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  
  const OptimizedGridView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      cacheExtent: 250.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        return PerformanceWidget(
          name: 'grid_item_$index',
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Image loading optimization
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const SizedBox();
      },
      errorBuilder: (context, error, stackTrace) {
        ErrorHandler.instance.handleError(
          error: error,
          stackTrace: stackTrace,
          type: ErrorType.network,
          severity: ErrorSeverity.low,
          customMessage: 'Failed to load image: $imageUrl',
          showToUser: false,
        );
        return errorWidget ?? const Icon(Icons.error_outline);
      },
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Memory-efficient page view
class OptimizedPageView extends StatelessWidget {
  final List<Widget> children;
  final PageController? controller;
  final void Function(int)? onPageChanged;
  final ScrollPhysics? physics;
  
  const OptimizedPageView({
    Key? key,
    required this.children,
    this.controller,
    this.onPageChanged,
    this.physics,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      physics: physics,
      itemCount: children.length,
      onPageChanged: onPageChanged,
      allowImplicitScrolling: false, // Optimize memory usage
      itemBuilder: (context, index) {
        return PerformanceWidget(
          name: 'page_$index',
          child: children[index],
        );
      },
    );
  }
}

/// Debouncer for preventing excessive API calls
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({required this.delay});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void cancel() {
    _timer?.cancel();
  }
  
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Throttler for limiting function calls
class Throttler {
  final Duration duration;
  DateTime? _lastRun;
  
  Throttler({required this.duration});
  
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      action();
      _lastRun = now;
    }
  }
}

/// Performance optimization utilities
class PerformanceUtils {
  static const Duration defaultDebounceDelay = Duration(milliseconds: 300);
  static const Duration defaultThrottleDuration = Duration(milliseconds: 100);
  
  static final Map<String, Debouncer> _debouncers = {};
  static final Map<String, Throttler> _throttlers = {};
  
  /// Get or create a debouncer
  static Debouncer debouncer(String name, {Duration? delay}) {
    return _debouncers.putIfAbsent(
      name,
      () => Debouncer(delay: delay ?? defaultDebounceDelay),
    );
  }
  
  /// Get or create a throttler
  static Throttler throttler(String name, {Duration? duration}) {
    return _throttlers.putIfAbsent(
      name,
      () => Throttler(duration: duration ?? defaultThrottleDuration),
    );
  }
  
  /// Dispose all performance utilities
  static void disposeAll() {
    for (final debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    _debouncers.clear();
    _throttlers.clear();
  }
  
  /// Measure execution time of a function
  static Future<T> measureTime<T>(
    String name,
    Future<T> Function() function,
  ) async {
    PerformanceMonitor.instance.startTimer(name);
    try {
      return await function();
    } finally {
      PerformanceMonitor.instance.endTimer(name);
    }
  }
  
  /// Check if device is low-end
  static bool isLowEndDevice() {
    // Simple heuristic based on screen size and memory
    final screenSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    
    // Consider devices with less than 2GB RAM or low resolution as low-end
    return screenSize.width * screenSize.height * pixelRatio * pixelRatio < 1920 * 1080;
  }
  
  /// Get optimal image cache size based on device
  static int getOptimalImageCacheSize() {
    if (isLowEndDevice()) {
      return 50 * 1024 * 1024; // 50MB for low-end devices
    }
    return 100 * 1024 * 1024; // 100MB for high-end devices
  }
  
  /// Get optimal list cache extent based on device
  static double getOptimalCacheExtent() {
    if (isLowEndDevice()) {
      return 200.0; // Smaller cache for low-end devices
    }
    return 500.0; // Larger cache for high-end devices
  }
}