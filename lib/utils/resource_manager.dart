import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/error_handler.dart';

/// A utility class to manage resources and prevent memory leaks
class ResourceManager {
  static final Map<String, List<DisposableResource>> _resources = {};
  static final Map<String, Timer> _timers = {};
  static final Map<String, StreamSubscription> _subscriptions = {};
  
  /// Register a disposable resource with automatic cleanup
  static String registerResource(DisposableResource resource, {String? key}) {
    final resourceKey = key ?? 'resource_${_resources.length}';
    _resources.putIfAbsent(resourceKey, () => []).add(resource);
    return resourceKey;
  }
  
  /// Register a timer with automatic cleanup
  static String registerTimer(Timer timer, {String? key}) {
    final timerKey = key ?? 'timer_${_timers.length}';
    _timers[timerKey] = timer;
    return timerKey;
  }
  
  /// Register a stream subscription with automatic cleanup
  static String registerSubscription(StreamSubscription subscription, {String? key}) {
    final subKey = key ?? 'sub_${_subscriptions.length}';
    _subscriptions[subKey] = subscription;
    return subKey;
  }
  
  /// Cancel and remove a specific timer
  static void cancelTimer(String key) {
    final timer = _timers.remove(key);
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }
  
  /// Cancel and remove a specific subscription
  static void cancelSubscription(String key) {
    final subscription = _subscriptions.remove(key);
    if (subscription != null) {
      subscription.cancel();
    }
  }
  
  /// Dispose a specific resource
  static void disposeResource(String key) {
    final resources = _resources.remove(key);
    if (resources != null) {
      for (final resource in resources) {
        try {
          resource.dispose();
        } catch (e, stackTrace) {
          ErrorHandler.instance.handleError(
            error: e,
            stackTrace: stackTrace,
            type: ErrorType.unknown,
            severity: ErrorSeverity.low,
            customMessage: 'Error disposing resource',
            showToUser: false,
          );
        }
      }
    }
  }
  
  /// Clean up all resources for a specific key or all resources
  static void cleanup({String? key}) {
    if (key != null) {
      _cleanupByKey(key);
    } else {
      _cleanupAll();
    }
  }
  
  static void _cleanupByKey(String key) {
    // Clean up resources
    disposeResource(key);
    
    // Clean up timers
    cancelTimer(key);
    
    // Clean up subscriptions
    cancelSubscription(key);
  }
  
  static void _cleanupAll() {
    // Dispose all resources
    for (final entry in _resources.entries) {
      for (final resource in entry.value) {
        try {
          resource.dispose();
        } catch (e, stackTrace) {
          ErrorHandler.instance.handleError(
            error: e,
            stackTrace: stackTrace,
            type: ErrorType.unknown,
            severity: ErrorSeverity.low,
            customMessage: 'Error disposing resource during cleanup',
            showToUser: false,
          );
        }
      }
    }
    _resources.clear();
    
    // Cancel all timers
    for (final timer in _timers.values) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    _timers.clear();
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    Logger.i('All resources cleaned up', 'ResourceManager');
  }
  
  /// Get statistics about managed resources
  static ResourceStats getStats() {
    return ResourceStats(
      resourceCount: _resources.length,
      timerCount: _timers.values.where((t) => t.isActive).length,
      subscriptionCount: _subscriptions.length,
    );
  }
}

/// Abstract class for disposable resources
abstract class DisposableResource {
  void dispose();
}

/// Statistics about managed resources
class ResourceStats {
  final int resourceCount;
  final int timerCount;
  final int subscriptionCount;
  
  const ResourceStats({
    required this.resourceCount,
    required this.timerCount,
    required this.subscriptionCount,
  });
  
  @override
  String toString() {
    return 'ResourceStats(resources: $resourceCount, timers: $timerCount, subscriptions: $subscriptionCount)';
  }
}

/// Mixin to help controllers manage resources automatically
mixin ResourceMixin on GetxController {
  final String _controllerKey = 'controller_${DateTime.now().millisecondsSinceEpoch}';
  
  /// Register a resource for automatic cleanup when controller is disposed
  String registerResource(DisposableResource resource, {String? key}) {
    return ResourceManager.registerResource(resource, key: '${_controllerKey}_${key ?? ''}');
  }
  
  /// Register a timer for automatic cleanup when controller is disposed
  String registerTimer(Timer timer, {String? key}) {
    return ResourceManager.registerTimer(timer, key: '${_controllerKey}_${key ?? ''}');
  }
  
  /// Register a subscription for automatic cleanup when controller is disposed
  String registerSubscription(StreamSubscription subscription, {String? key}) {
    return ResourceManager.registerSubscription(subscription, key: '${_controllerKey}_${key ?? ''}');
  }
  
  /// Create a debounced timer with automatic cleanup
  Timer? createDebouncedTimer(Duration duration, VoidCallback callback, {String? key}) {
    final timerKey = '${_controllerKey}_debounce_${key ?? ''}';
    
    // Cancel existing timer if any
    ResourceManager.cancelTimer(timerKey);
    
    final timer = Timer(duration, callback);
    ResourceManager.registerTimer(timer, key: timerKey);
    return timer;
  }
  
  @override
  void onClose() {
    ResourceManager.cleanup(key: _controllerKey);
    super.onClose();
  }
}

/// Extension to add common resource management patterns
extension TimerExtensions on Timer {
  /// Cancel timer safely with error handling
  void cancelSafely() {
    try {
      if (isActive) {
        cancel();
      }
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        customMessage: 'Error cancelling timer',
        showToUser: false,
      );
    }
  }
}

extension StreamSubscriptionExtensions on StreamSubscription {
  /// Cancel subscription safely with error handling
  void cancelSafely() {
    try {
      if (!isPaused) {
        cancel();
      }
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        customMessage: 'Error cancelling stream subscription',
        showToUser: false,
      );
    }
  }
}
