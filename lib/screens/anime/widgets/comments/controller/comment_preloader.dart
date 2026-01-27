import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:get/get.dart';

class CommentPreloader extends GetxService {
  static CommentPreloader get to => Get.find();
  
  // Map to store preloaded controllers by mediaId
  final RxMap<String, CommentSectionController> _preloadedControllers = <String, CommentSectionController>{}.obs;
  
  // Preload comments for a media when it opens
  Future<void> preloadComments(String mediaId, {String? currentTag}) async {
    if (mediaId.isEmpty || _preloadedControllers.containsKey(mediaId)) {
      return;
    }
    
    print('Preloading comments for media: $mediaId');
    
    try {
      // Create controller and start loading immediately
      final controller = CommentSectionController(
        mediaId: mediaId,
        currentTag: currentTag,
      );
      
      // Store the controller
      _preloadedControllers[mediaId] = controller;
      
      // Start loading comments in background
      controller.loadComments();
      
      print('Started preloading comments for media: $mediaId');
    } catch (e) {
      print('Error preloading comments for media $mediaId: $e');
    }
  }
  
  // Get preloaded controller for a media
  CommentSectionController? getPreloadedController(String mediaId) {
    return _preloadedControllers[mediaId];
  }
  
  // Remove preloaded controller when media is closed
  void removePreloadedController(String mediaId) {
    final controller = _preloadedControllers.remove(mediaId);
    if (controller != null) {
      controller.onClose();
      print('Removed preloaded controller for media: $mediaId');
    }
  }
  
  // Clear all preloaded controllers
  void clearAll() {
    for (final controller in _preloadedControllers.values) {
      controller.onClose();
    }
    _preloadedControllers.clear();
    print('Cleared all preloaded comment controllers');
  }
  
  // Check if comments are preloaded for a media
  bool isPreloaded(String mediaId) {
    return _preloadedControllers.containsKey(mediaId);
  }
  
  // Get all preloaded media IDs
  List<String> get preloadedMediaIds => _preloadedControllers.keys.toList();
}