import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

enum ErrorType {
  network,
  api,
  storage,
  player,
  extension,
  validation,
  unknown,
}

enum ErrorSeverity {
  low,    // Minor issues, doesn't affect core functionality
  medium, // Affects some features but app remains usable
  high,   // Critical issues affecting core functionality
  critical, // App crashes or becomes unusable
}

class AnymeXException implements Exception {
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AnymeXException({
    required this.message,
    required this.type,
    required this.severity,
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    return 'AnymeXException: $message (Type: $type, Severity: $severity, Code: $code)';
  }
}

class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  
  ErrorHandler._();

  final Map<ErrorType, String> _defaultMessages = {
    ErrorType.network: 'Network connection error. Please check your internet connection.',
    ErrorType.api: 'Service temporarily unavailable. Please try again later.',
    ErrorType.storage: 'Storage error. Please check your device storage.',
    ErrorType.player: 'Playback error. Please try a different source.',
    ErrorType.extension: 'Extension error. Please check your extension settings.',
    ErrorType.validation: 'Invalid input. Please check your data and try again.',
    ErrorType.unknown: 'An unexpected error occurred. Please try again.',
  };

  void handleError({
    required dynamic error,
    StackTrace? stackTrace,
    ErrorType? type,
    ErrorSeverity? severity,
    String? customMessage,
    String? code,
    Map<String, dynamic>? context,
    bool showToUser = true,
  }) {
    final errorType = _determineErrorType(error, type);
    final errorSeverity = severity ?? _determineErrorSeverity(error, errorType);
    
    final exception = AnymeXException(
      message: customMessage ?? _getDefaultMessage(errorType, error),
      type: errorType,
      severity: errorSeverity,
      code: code,
      originalError: error,
      stackTrace: stackTrace,
      context: context,
    );

    _logError(exception);
    
    if (showToUser && errorSeverity != ErrorSeverity.low) {
      _showUserError(exception);
    }

    _reportError(exception);
  }

  ErrorType _determineErrorType(dynamic error, ErrorType? fallback) {
    if (fallback != null) return fallback;

    if (error is SocketException || error is HttpException) {
      return ErrorType.network;
    }
    
    if (error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('connection')) {
      return ErrorType.network;
    }
    
    if (error.toString().toLowerCase().contains('player') ||
        error.toString().toLowerCase().contains('video')) {
      return ErrorType.player;
    }
    
    if (error.toString().toLowerCase().contains('extension') ||
        error.toString().toLowerCase().contains('source')) {
      return ErrorType.extension;
    }
    
    if (error.toString().toLowerCase().contains('storage') ||
        error.toString().toLowerCase().contains('hive')) {
      return ErrorType.storage;
    }

    return ErrorType.unknown;
  }

  ErrorSeverity _determineErrorSeverity(dynamic error, ErrorType type) {
    // Critical errors that make app unusable
    if (error is OutOfMemoryError ||
        error is StackOverflowError ||
        type == ErrorType.storage) {
      return ErrorSeverity.critical;
    }

    // High severity errors
    if (type == ErrorType.player || 
        error.toString().toLowerCase().contains('failed to open')) {
      return ErrorSeverity.high;
    }

    // Medium severity errors
    if (type == ErrorType.network || type == ErrorType.api) {
      return ErrorSeverity.medium;
    }

    return ErrorSeverity.low;
  }

  String _getDefaultMessage(ErrorType type, dynamic error) {
    if (error.toString().isNotEmpty) {
      return error.toString();
    }
    return _defaultMessages[type] ?? _defaultMessages[ErrorType.unknown]!;
  }

  void _logError(AnymeXException exception) {
    final logLevel = _getLogLevel(exception.severity);
    
    switch (logLevel) {
      case LogLevel.error:
        Logger.e(
          exception.message,
          error: exception.originalError,
          stackTrace: exception.stackTrace,
          loggerName: 'ErrorHandler',
        );
        break;
      case LogLevel.warning:
        Logger.w(
          '${exception.type.name}: ${exception.message}',
          'ErrorHandler',
        );
        break;
      case LogLevel.info:
        Logger.i(
          '${exception.type.name}: ${exception.message}',
          'ErrorHandler',
        );
        break;
    }
  }

  LogLevel _getLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
      case ErrorSeverity.high:
        return LogLevel.error;
      case ErrorSeverity.medium:
        return LogLevel.warning;
      case ErrorSeverity.low:
        return LogLevel.info;
    }
  }

  void _showUserError(AnymeXException exception) {
    switch (exception.severity) {
      case ErrorSeverity.critical:
        _showCriticalError(exception);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.medium:
        _showStandardError(exception);
        break;
      case ErrorSeverity.low:
        // Don't show low severity errors to user
        break;
    }
  }

  void _showCriticalError(AnymeXException exception) {
    // For critical errors, show a dialog that can't be dismissed
    Get.dialog(
      AlertDialog(
        title: const Text('Critical Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(exception.message),
            if (exception.code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${exception.code}',
                style: Get.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.reset(),
            child: const Text('Restart App'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showStandardError(AnymeXException exception) {
    snackBar(exception.message);
  }

  void _reportError(AnymeXException exception) {
    if (exception.severity == ErrorSeverity.critical || 
        exception.severity == ErrorSeverity.high) {
      // In a real app, you might send this to a crash reporting service
      if (kDebugMode) {
        debugPrint('Error Report: ${exception.toString()}');
        debugPrint('Context: ${exception.context}');
        debugPrint('Original Error: ${exception.originalError}');
        if (exception.stackTrace != null) {
          debugPrint('Stack Trace: ${exception.stackTrace}');
        }
      }
    }
  }

  // Convenience methods for common error scenarios
  void handleNetworkError(dynamic error, {StackTrace? stackTrace}) {
    handleError(
      error: error,
      stackTrace: stackTrace,
      type: ErrorType.network,
      severity: ErrorSeverity.medium,
    );
  }

  void handlePlayerError(dynamic error, {StackTrace? stackTrace}) {
    handleError(
      error: error,
      stackTrace: stackTrace,
      type: ErrorType.player,
      severity: ErrorSeverity.high,
    );
  }

  void handleStorageError(dynamic error, {StackTrace? stackTrace}) {
    handleError(
      error: error,
      stackTrace: stackTrace,
      type: ErrorType.storage,
      severity: ErrorSeverity.critical,
    );
  }

  void handleExtensionError(dynamic error, {StackTrace? stackTrace}) {
    handleError(
      error: error,
      stackTrace: stackTrace,
      type: ErrorType.extension,
      severity: ErrorSeverity.medium,
    );
  }
}

enum LogLevel {
  error,
  warning,
  info,
}

// Extension for easy error handling
extension ErrorHandling on Future {
  Future<T> handleError<T>({
    ErrorType? type,
    ErrorSeverity? severity,
    String? customMessage,
    bool showToUser = true,
  }) {
    return catchError((error, stackTrace) {
      ErrorHandler.instance.handleError(
        error: error,
        stackTrace: stackTrace,
        type: type,
        severity: severity,
        customMessage: customMessage,
        showToUser: showToUser,
      );
      throw error; // Re-throw to maintain existing behavior
    });
  }
}