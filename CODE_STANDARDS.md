# AnymeX Code Standards

This document outlines the coding standards and conventions for the AnymeX project.

## Table of Contents

1. [General Principles](#general-principles)
2. [Dart/Flutter Conventions](#dartflutter-conventions)
3. [File Organization](#file-organization)
4. [Naming Conventions](#naming-conventions)
5. [Error Handling](#error-handling)
6. [Performance Guidelines](#performance-guidelines)
7. [Documentation](#documentation)
8. [Testing](#testing)

## General Principles

- **Readability First**: Code should be readable and self-documenting
- **Consistency**: Follow established patterns throughout the codebase
- **Performance**: Write efficient code that doesn't compromise user experience
- **Maintainability**: Code should be easy to modify and extend
- **Error Handling**: Handle errors gracefully with proper user feedback

## Dart/Flutter Conventions

### Import Organization

```dart
// Dart core imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Third-party packages
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports - organize by feature
import 'package:anymex/controllers/base/base_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/buttons.dart';
```

### Class Structure

```dart
class ExampleController extends BaseController {
  // Public properties
  final RxBool isLoading = false.obs;
  
  // Private properties
  final RxString _errorMessage = ''.obs;
  Timer? _debounceTimer;
  
  // Getters
  bool get hasError => _errorMessage.value.isNotEmpty;
  
  // Public methods
  void loadData() async {
    // Implementation
  }
  
  // Private methods
  void _validateInput() {
    // Implementation
  }
  
  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}
```

### Widget Structure

```dart
class ExampleWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  
  const ExampleWidget({
    Key? key,
    required this.title,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    // Build widget content
  }
}
```

## File Organization

### Directory Structure

```
lib/
├── controllers/
│   ├── base/
│   │   ├── base_controller.dart
│   │   └── ...
│   ├── services/
│   └── ...
├── models/
│   ├── Media/
│   ├── Service/
│   └── ...
├── screens/
│   ├── anime/
│   ├── manga/
│   └── ...
├── utils/
│   ├── error_handler.dart
│   ├── logger.dart
│   └── ...
├── widgets/
│   ├── common/
│   ├── custom_widgets/
│   └── ...
└── main.dart
```

### File Naming

- Use `snake_case` for file names
- Be descriptive but concise
- Group related files in directories
- Use `index.dart` for barrel exports when appropriate

## Naming Conventions

### Variables and Properties

```dart
// Use camelCase for variables
String userName = 'john_doe';
final RxList<Media> animeList = RxList();

// Private properties start with underscore
final RxString _errorMessage = ''.obs;
Timer? _debounceTimer;
```

### Classes and Types

```dart
// Use PascalCase for classes
class MediaController extends BaseController {}

// Use PascalCase for enums
enum MediaType { anime, manga, novel }

// Use PascalCase for typedefs
typedef MediaCallback = void Function(Media media);
```

### Constants

```dart
// Use SCREAMING_SNAKE_CASE for constants
const int MAX_RETRY_ATTEMPTS = 3;
const Duration DEFAULT_TIMEOUT = Duration(seconds: 30);

// For class-level constants, use camelCase with leading underscore
class ApiEndpoints {
  static const String _baseUrl = 'https://api.example.com';
  static const String usersEndpoint = '$_baseUrl/users';
}
```

### Methods and Functions

```dart
// Use camelCase for methods
void loadUserData() async {
  // Implementation
}

bool _isValidEmail(String email) {
  // Implementation
}

// For callbacks, use descriptive names
Future<void> onMediaSelected(Media media) async {
  // Implementation
}
```

## Error Handling

### Always Handle Errors

```dart
// Good: Handle errors properly
Future<void> loadData() async {
  try {
    setLoading(true);
    final data = await apiService.fetchData();
    setData(data);
  } catch (e, stackTrace) {
    ErrorHandler.instance.handleError(
      error: e,
      stackTrace: stackTrace,
      type: ErrorType.api,
      severity: ErrorSeverity.medium,
      customMessage: 'Failed to load data',
    );
  } finally {
    setLoading(false);
  }
}

// Bad: Silent failures
Future<void> loadData() async {
  try {
    final data = await apiService.fetchData();
    setData(data);
  } catch (e) {
    // Do nothing
  }
}
```

### Use Custom Error Types

```dart
// Create specific exception types
class ApiException extends AnymeXException {
  ApiException({
    required String message,
    required int statusCode,
  }) : super(
    message: message,
    type: ErrorType.api,
    severity: ErrorSeverity.medium,
    context: {'statusCode': statusCode},
  );
}
```

## Performance Guidelines

### Use Efficient Widgets

```dart
// Good: Use optimized widgets
OptimizedListView<Media>(
  items: mediaList,
  itemBuilder: (context, media, index) {
    return MediaCard(media: media);
  },
)

// Bad: Inefficient list implementation
Column(
  children: mediaList.map((media) => MediaCard(media: media)).toList(),
)
```

### Avoid Unnecessary Rebuilds

```dart
// Good: Use const widgets where possible
const Icon(Icons.play_arrow)

// Good: Use GetX reactive widgets efficiently
Obx(() => Text(controller.title.value))

// Bad: Rebuilding entire widget tree
GetBuilder<Controller>(
  builder: (controller) => Column(
    children: [
      Text(controller.title.value),
      // ... many other widgets that don't need rebuilding
    ],
  ),
)
```

### Use Proper Memory Management

```dart
// Good: Use ResourceMixin for automatic cleanup
class MyController extends GetxController with ResourceMixin {
  void startTimer() {
    registerTimer(Timer.periodic(Duration(seconds: 1), (timer) {
      // Timer logic
    }));
  }
}

// Bad: Manual resource management
class MyController extends GetxController {
  Timer? _timer;
  
  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Timer logic
    });
  }
  
  @override
  void onClose() {
    _timer?.cancel(); // Easy to forget
    super.onClose();
  }
}
```

## Documentation

### Class Documentation

```dart
/// Controller for managing anime media data and operations.
/// 
/// This controller handles fetching, caching, and updating anime information
/// from various sources including AniList, MAL, and extensions.
/// 
/// Example:
/// ```dart
/// final controller = Get.put(AnimeController());
/// await controller.loadAnimeList();
/// ```
class AnimeController extends BaseController {
  // Implementation
}
```

### Method Documentation

```dart
/// Loads anime data from the specified source.
/// 
/// Parameters:
/// - [sourceId]: The ID of the source to load from
/// - [page]: The page number to load (optional, defaults to 1)
/// - [forceRefresh]: Whether to force a refresh from the network
/// 
/// Returns a [Future<bool>] indicating success or failure.
/// 
/// Throws:
/// - [ApiException] When the API request fails
/// - [NetworkException] When there's no internet connection
/// 
/// Example:
/// ```dart
/// final success = await controller.loadAnimeData(
///   sourceId: 'anilist',
///   page: 1,
///   forceRefresh: true,
/// );
/// ```
Future<bool> loadAnimeData({
  required String sourceId,
  int page = 1,
  bool forceRefresh = false,
}) async {
  // Implementation
}
```

## Testing

### Write Testable Code

```dart
// Good: Dependency injection
class MediaService {
  final HttpClient _client;
  
  MediaService({HttpClient? client}) 
    : _client = client ?? HttpClient();
  
  Future<List<Media>> fetchMedia() async {
    // Use _client for HTTP requests
  }
}

// Bad: Hard dependencies
class MediaService {
  Future<List<Media>> fetchMedia() async {
    final client = HttpClient(); // Hard to test
    // Use client for HTTP requests
  }
}
```

### Test Structure

```dart
// test/controllers/media_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/media_controller.dart';

void main() {
  group('MediaController', () {
    late MediaController controller;
    
    setUp(() {
      Get.testMode = true;
      controller = MediaController();
    });
    
    tearDown(() {
      Get.reset();
    });
    
    test('should load media data successfully', () async {
      // Test implementation
    });
    
    test('should handle network errors gracefully', () async {
      // Test implementation
    });
  });
}
```

## Code Quality Tools

### Linting Rules

Enable and configure these linting rules in `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Error rules
    - avoid_print
    - avoid_unnecessary_containers
    - avoid_web_libraries_in_flutter
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - prefer_relative_imports
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_statements
    - unsafe_html
    
    # Style rules
    - always_declare_return_types
    - always_put_control_body_on_new_line
    - always_put_required_named_parameters_first
    - always_specify_types
    - annotate_overrides
    - avoid_annotating_with_dynamic
    - avoid_bool_literals_in_conditional_expressions
    - avoid_catches_without_on_clauses
    - avoid_catching_errors
    - avoid_double_and_int_checks
    - avoid_field_initializers_in_const_classes
    - avoid_function_literals_in_foreach_calls
    - avoid_implementing_value_types
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_positional_boolean_parameters
    - avoid_private_typedef_functions
    - avoid_redundant_argument_values
    - avoid_renaming_method_parameters
    - avoid_return_types_on_setters
    - avoid_returning_null_for_void
    - avoid_setters_without_getters
    - avoid_shadowing_type_parameters
    - avoid_single_cascade_in_expression_statements
    - avoid_slow_async_io
    - avoid_types_as_parameter_names
    - avoid_unnecessary_this
    - avoid_unused_constructor_parameters
    - avoid_void_async
    - await_only_futures
    - camel_case_extensions
    - camel_case_types
    - cascade_invocations
    - cast_nullable_to_non_nullable
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - directives_ordering
    - empty_catches
    - empty_constructor_bodies
    - empty_statements
    - exhaustive_cases
    - file_names
    - flutter_style_todos
    - implementation_imports
    - join_return_with_assignment
    - leading_newlines_in_multiline_strings
    - library_names
    - library_prefixes
    - lines_longer_than_80_chars
    - missing_whitespace_between_adjacent_strings
    - no_default_cases
    - non_constant_identifier_names
    - null_closures
    - omit_local_variable_types
    - one_member_abstracts
    - only_throw_errors
    - overridden_fields
    - package_api_docs
    - package_prefixed_library_names
    - parameter_assignments
    - prefer_adjacent_string_concatenation
    - prefer_asserts_in_initializer_lists
    - prefer_asserts_with_message
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_constructors_over_static_methods
    - prefer_contains
    - prefer_equal_for_default_values
    - prefer_expression_function_bodies
    - prefer_final_fields
    - prefer_final_in_for_each
    - prefer_final_locals
    - prefer_for_elements_to_map_fromIterable
    - prefer_function_declarations_over_variables
    - prefer_generic_function_type_aliases
    - prefer_if_elements_to_conditional_expressions
    - prefer_if_null_operators
    - prefer_initializing_formals
    - prefer_inlined_adds
    - prefer_int_literals
    - prefer_interpolation_to_compose_strings
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_is_not_operator
    - prefer_iterable_whereType
    - prefer_null_aware_operators
    - prefer_relative_imports
    - prefer_single_quotes
    - prefer_spread_collections
    - prefer_typing_uninitialized_variables
    - prefer_void_to_null
    - provide_deprecation_message
    - public_member_api_docs
    - recursive_getters
    - slash_for_doc_comments
    - sort_child_properties_last
    - sort_constructors_first
    - sort_pub_dependencies
    - sort_unnamed_constructors_first
    - type_annotate_public_apis
    - type_init_formals
    - unawaited_futures
    - unnecessary_await_in_return
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_getters_setters
    - unnecessary_lambdas
    - unnecessary_new
    - unnecessary_null_aware_assignments
    - unnecessary_null_checks
    - unnecessary_null_in_if_null_operators
    - unnecessary_nullable_for_final_variable_declarations
    - unnecessary_overrides
    - unnecessary_parenthesis
    - unnecessary_raw_strings
    - unnecessary_string_escapes
    - unnecessary_string_interpolations
    - unnecessary_this
    - unrelated_type_equality_checks
    - unsafe_html
    - use_full_hex_values_for_flutter_colors
    - use_function_type_syntax_for_parameters
    - use_if_null_to_convert_nulls_to_bools
    - use_is_even_rather_than_modulo
    - use_key_in_widget_constructors
    - use_late_for_private_fields_and_variables
    - use_named_constants
    - use_raw_strings
    - use_rethrow_when_possible
    - use_setters_to_change_properties
    - use_string_buffers
    - use_test_throws_matchers
    - use_to_and_as_if_applicable
    - valid_regexps
    - void_checks
```

## Git Conventions

### Commit Messages

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(player): add subtitle customization options

fix(auth): resolve login timeout issue

refactor(source): improve extension loading performance
```

### Branch Naming

- `feature/feature-name`: New features
- `bugfix/bug-description`: Bug fixes
- `hotfix/critical-fix`: Critical fixes
- `refactor/refactor-description`: Refactoring

## Review Checklist

Before submitting code, ensure:

- [ ] Code follows all naming conventions
- [ ] Error handling is implemented
- [ ] Performance considerations are addressed
- [ ] Documentation is provided for public APIs
- [ ] Tests are written for new functionality
- [ ] No console.log or print statements
- [ ] No commented-out code
- [ ] Code is properly formatted
- [ ] Dependencies are up to date
- [ ] Security considerations are addressed