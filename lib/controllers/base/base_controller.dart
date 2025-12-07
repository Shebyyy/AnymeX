import 'package:get/get.dart';
import 'package:anymex/utils/resource_manager.dart';

/// Base controller class with common functionality
abstract class BaseController extends GetxController with ResourceMixin {
  /// Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  /// Error state
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;
  
  /// Success state
  final RxBool _isSuccess = false.obs;
  bool get isSuccess => _isSuccess.value;
  
  /// Set loading state
  void setLoading(bool loading) {
    _isLoading.value = loading;
    if (loading) {
      _errorMessage.value = '';
      _isSuccess.value = false;
    }
  }
  
  /// Set error state
  void setError(String error) {
    _errorMessage.value = error;
    _isLoading.value = false;
    _isSuccess.value = false;
  }
  
  /// Set success state
  void setSuccess() {
    _isSuccess.value = true;
    _isLoading.value = false;
    _errorMessage.value = '';
  }
  
  /// Clear all states
  void clearStates() {
    _isLoading.value = false;
    _errorMessage.value = '';
    _isSuccess.value = false;
  }
  
  /// Execute async operation with state management
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? errorMessage,
  }) async {
    try {
      setLoading(true);
      final result = await operation();
      setSuccess();
      return result;
    } catch (e, stackTrace) {
      setError(errorMessage ?? e.toString());
      return null;
    }
  }
}

/// Data controller for managing data state
abstract class DataController<T> extends BaseController {
  final Rx<T> _data = Rx<T>(null as T);
  final RxList<T> _listData = RxList<T>();
  
  T? get data => _data.value;
  List<T> get listData => _listData;
  
  bool get hasData => _data.value != null;
  bool get hasListData => _listData.isNotEmpty;
  
  /// Set single data item
  void setData(T data) {
    _data.value = data;
    setSuccess();
  }
  
  /// Set list data
  void setListData(List<T> data) {
    _listData.assignAll(data);
    setSuccess();
  }
  
  /// Add item to list
  void addToList(T item) {
    _listData.add(item);
  }
  
  /// Remove item from list
  void removeFromList(T item) {
    _listData.remove(item);
  }
  
  /// Update item in list
  void updateInList(int index, T item) {
    if (index >= 0 && index < _listData.length) {
      _listData[index] = item;
    }
  }
  
  /// Clear data
  void clearData() {
    _data.value = null as T;
    _listData.clear();
    clearStates();
  }
}

/// Paginated data controller for handling paginated data
abstract class PaginatedDataController<T> extends DataController<T> {
  final RxInt _currentPage = 1.obs;
  final RxInt _totalPages = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxBool _hasNextPage = false.obs;
  final RxBool _hasPreviousPage = false.obs;
  final RxBool _isLoadingMore = false.obs;
  
  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;
  bool get isLoadingMore => _isLoadingMore.value;
  
  /// Set pagination info
  void setPaginationInfo({
    required int currentPage,
    required int totalPages,
    required int totalItems,
  }) {
    _currentPage.value = currentPage;
    _totalPages.value = totalPages;
    _totalItems.value = totalItems;
    _hasNextPage.value = currentPage < totalPages;
    _hasPreviousPage.value = currentPage > 1;
  }
  
  /// Load next page
  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoadingMore) return;
    
    _isLoadingMore.value = true;
    try {
      await fetchPage(currentPage + 1);
    } finally {
      _isLoadingMore.value = false;
    }
  }
  
  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (!hasPreviousPage || isLoadingMore) return;
    
    _isLoadingMore.value = true;
    try {
      await fetchPage(currentPage - 1);
    } finally {
      _isLoadingMore.value = false;
    }
  }
  
  /// Refresh current page
  Future<void> refresh() async {
    await fetchPage(currentPage);
  }
  
  /// Abstract method to fetch a specific page
  Future<void> fetchPage(int page);
  
  /// Reset pagination
  void resetPagination() {
    _currentPage.value = 1;
    _totalPages.value = 1;
    _totalItems.value = 0;
    _hasNextPage.value = false;
    _hasPreviousPage.value = false;
    _isLoadingMore.value = false;
    clearData();
  }
}

/// Search controller for handling search functionality
abstract class SearchController<T> extends BaseController {
  final RxString _searchQuery = ''.obs;
  final RxList<T> _searchResults = RxList<T>();
  final RxList<T> _searchHistory = RxList<T>();
  final RxBool _isSearching = false.obs;
  
  String get searchQuery => _searchQuery.value;
  List<T> get searchResults => _searchResults;
  List<T> get searchHistory => _searchHistory;
  bool get isSearching => _isSearching.value;
  bool get hasSearchQuery => _searchQuery.value.isNotEmpty;
  
  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      clearSearchResults();
    }
  }
  
  /// Set search results
  void setSearchResults(List<T> results) {
    _searchResults.assignAll(results);
    _isSearching.value = false;
    setSuccess();
  }
  
  /// Add to search history
  void addToHistory(T item) {
    if (!_searchHistory.contains(item)) {
      _searchHistory.insert(0, item);
      // Keep only last 20 items
      if (_searchHistory.length > 20) {
        _searchHistory.removeRange(20, _searchHistory.length);
      }
    }
  }
  
  /// Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    _isSearching.value = false;
  }
  
  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
  }
  
  /// Perform search
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearSearchResults();
      return;
    }
    
    setSearchQuery(query);
    _isSearching.value = true;
    
    try {
      final results = await searchItems(query);
      setSearchResults(results);
    } catch (e) {
      setError('Search failed: ${e.toString()}');
      _isSearching.value = false;
    }
  }
  
  /// Abstract method to search items
  Future<List<T>> searchItems(String query);
}

/// Form controller for handling form state
abstract class FormController extends BaseController {
  final RxMap<String, dynamic> _formData = RxMap<String, dynamic>();
  final RxMap<String, String> _errors = RxMap<String, String>();
  final RxBool _isFormValid = false.obs;
  
  Map<String, dynamic> get formData => _formData;
  Map<String, String> get errors => _errors;
  bool get isFormValid => _isFormValid.value;
  
  /// Set form field value
  void setFieldValue(String field, dynamic value) {
    _formData[field] = value;
    _validateField(field, value);
    _validateForm();
  }
  
  /// Get form field value
  T? getFieldValue<T>(String field) {
    return _formData[field] as T?;
  }
  
  /// Set field error
  void setFieldError(String field, String error) {
    _errors[field] = error;
  }
  
  /// Clear field error
  void clearFieldError(String field) {
    _errors.remove(field);
  }
  
  /// Clear all errors
  void clearAllErrors() {
    _errors.clear();
  }
  
  /// Validate form (abstract)
  bool validateForm();
  
  /// Validate individual field (abstract)
  String? validateField(String field, dynamic value);
  
  /// Update form validity
  void _validateForm() {
    _isFormValid.value = validateForm() && _errors.isEmpty;
  }
  
  /// Reset form
  void resetForm() {
    _formData.clear();
    _errors.clear();
    _isFormValid.value = false;
    clearStates();
  }
  
  /// Submit form
  Future<bool> submitForm() async {
    if (!validateForm()) {
      setError('Please fix form errors');
      return false;
    }
    
    return await executeWithErrorHandling(() async {
      await onSubmit();
      return true;
    });
  }
  
  /// Abstract submit method
  Future<void> onSubmit();
}