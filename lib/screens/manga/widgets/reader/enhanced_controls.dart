import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/utils/performance.dart';

/// Enhanced bookmark system for manga reader
class BookmarkManager {
  static BookmarkManager? _instance;
  static BookmarkManager get instance => _instance ??= BookmarkManager._();
  
  BookmarkManager._();
  
  final Map<String, List<Bookmark>> _bookmarks = {};
  
  void addBookmark({
    required String mediaId,
    required String chapterId,
    required int pageNumber,
    String? note,
    String? preview,
  }) {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mediaId: mediaId,
      chapterId: chapterId,
      pageNumber: pageNumber,
      note: note,
      preview: preview,
      createdAt: DateTime.now(),
    );
    
    final key = '${mediaId}_${chapterId}';
    _bookmarks.putIfAbsent(key, () => []).add(bookmark);
    
    // Keep only last 50 bookmarks per chapter
    final bookmarks = _bookmarks[key]!;
    if (bookmarks.length > 50) {
      bookmarks.removeRange(0, bookmarks.length - 50);
    }
  }
  
  List<Bookmark> getBookmarks(String mediaId, String chapterId) {
    final key = '${mediaId}_${chapterId}';
    return _bookmarks[key] ?? [];
  }
  
  void removeBookmark(String bookmarkId) {
    for (final entry in _bookmarks.entries) {
      entry.value.removeWhere((bookmark) => bookmark.id == bookmarkId);
    }
  }
  
  void clearBookmarks(String mediaId, String chapterId) {
    _bookmarks.remove('${mediaId}_${chapterId}');
  }
}

class Bookmark {
  final String id;
  final String mediaId;
  final String chapterId;
  final int pageNumber;
  final String? note;
  final String? preview;
  final DateTime createdAt;
  
  Bookmark({
    required this.id,
    required this.mediaId,
    required this.chapterId,
    required this.pageNumber,
    this.note,
    this.preview,
    required this.createdAt,
  });
}

/// Enhanced reader controls with bookmark functionality
class EnhancedReaderControls extends StatelessWidget {
  final ReaderController controller;
  final String mediaId;
  final String chapterId;
  
  const EnhancedReaderControls({
    Key? key,
    required this.controller,
    required this.mediaId,
    required this.chapterId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: controller.showControls.value ? 120 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: controller.showControls.value
          ? _buildControls(context)
          : const SizedBox.shrink(),
    ));
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTopControls(context),
          const Spacer(),
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPageIndicator(context),
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavigationButton(
          icon: Icons.skip_previous,
          onPressed: () => controller.goToPreviousPage(),
        ),
        _buildNavigationButton(
          icon: Icons.skip_next,
          onPressed: () => controller.goToNextPage(),
        ),
        _buildBookmarkButton(context),
        _buildSettingsButton(context),
      ],
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${controller.currentPageIndex.value} / ${controller.pageList.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildQuickActionButton(
          icon: Icons.bookmark_border,
          onPressed: () => _showBookmarkDialog(context),
        ),
        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon: Icons.share,
          onPressed: () => _sharePage(context),
        ),
        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon: Icons.fullscreen,
          onPressed: () => _toggleFullscreen(context),
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBookmarkButton(BuildContext context) {
    return Obx(() {
      final bookmarks = BookmarkManager.instance.getBookmarks(mediaId, chapterId);
      final isBookmarked = bookmarks.any((b) => b.pageNumber == controller.currentPageIndex.value);
      
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isBookmarked 
              ? Theme.of(context).primaryColor.withOpacity(0.8)
              : Colors.black.withOpacity(0.6),
          shape: const CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => _toggleBookmark(context, isBookmarked),
        ),
      );
    });
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white, size: 24),
        onPressed: () => _showSettings(context),
      ),
    );
  }

  void _showBookmarkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BookmarkDialog(
        mediaId: mediaId,
        chapterId: chapterId,
        currentPage: controller.currentPageIndex.value,
        totalPages: controller.pageList.length,
      ),
    );
  }

  void _toggleBookmark(BuildContext context, bool isBookmarked) {
    if (isBookmarked) {
      // Remove bookmark
      final bookmarks = BookmarkManager.instance.getBookmarks(mediaId, chapterId);
      final bookmark = bookmarks.firstWhereOrNull((b) => b.pageNumber == controller.currentPageIndex.value);
      if (bookmark != null) {
        BookmarkManager.instance.removeBookmark(bookmark.id);
      }
    } else {
      // Add bookmark
      BookmarkManager.instance.addBookmark(
        mediaId: mediaId,
        chapterId: chapterId,
        pageNumber: controller.currentPageIndex.value,
      );
    }
  }

  void _sharePage(BuildContext context) {
    // Implement page sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Share functionality coming soon'),
    );
  }

  void _toggleFullscreen(BuildContext context) {
    // Implement fullscreen toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Fullscreen toggle coming soon'),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EnhancedReaderSettings(
        controller: controller,
      ),
    );
  }
}

/// Bookmark dialog for adding/editing bookmarks
class BookmarkDialog extends StatefulWidget {
  final String mediaId;
  final String chapterId;
  final int currentPage;
  final int totalPages;
  
  const BookmarkDialog({
    Key? key,
    required this.mediaId,
    required this.chapterId,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _pageController.text = widget.currentPage.toString();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: Get.width * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Bookmark',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Page Number',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter page number',
                suffixText: '/ ${widget.totalPages}',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Note (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a note...',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _saveBookmark(),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveBookmark() {
    final pageNumber = int.tryParse(_pageController.text) ?? widget.currentPage;
    if (pageNumber < 1 || pageNumber > widget.totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: 'Invalid page number'),
      );
      return;
    }
    
    BookmarkManager.instance.addBookmark(
      mediaId: widget.mediaId,
      chapterId: widget.chapterId,
      pageNumber: pageNumber,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    
    Get.back();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Bookmark saved'),
    );
  }
}