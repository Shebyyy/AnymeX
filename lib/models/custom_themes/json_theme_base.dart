/// Base class for all JSON-based themes
abstract class JsonThemeBase {
  String get id;
  String get name;
  String get version;
  String get author;
  
  /// Convert theme to JSON
  Map<String, dynamic> toJson();
  
  /// Get validation errors (empty if valid)
  List<String> get validationErrors;
  
  /// Check if theme is valid
  bool get isValid => validationErrors.isEmpty;
}
