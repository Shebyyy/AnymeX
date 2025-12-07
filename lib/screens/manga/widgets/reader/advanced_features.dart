import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/utils/performance.dart';

/// Advanced reader features including annotations, highlights, and more
class AdvancedReaderFeatures {
  static AdvancedReaderFeatures? _instance;
  static AdvancedReaderFeatures get instance => _instance ??= AdvancedReaderFeatures._();
  
  AdvancedReaderFeatures._();
  
  final Map<String, List<Annotation>> _annotations = {};
  final Map<String, List<Highlight>> _highlights = {};
  
  void addAnnotation({
    required String mediaId,
    required String chapterId,
    required int pageNumber,
    required Annotation annotation,
  }) {
    final key = '${mediaId}_${chapterId}';
    _annotations.putIfAbsent(key, () => []).add(annotation);
  }
  
  List<Annotation> getAnnotations(String mediaId, String chapterId) {
    final key = '${mediaId}_${chapterId}';
    return _annotations[key] ?? [];
  }
  
  void addHighlight({
    required String mediaId,
    required String chapterId,
    required int pageNumber,
    required Highlight highlight,
  }) {
    final key = '${mediaId}_${chapterId}';
    _highlights.putIfAbsent(key, () => []).add(highlight);
  }
  
  List<Highlight> getHighlights(String mediaId, String chapterId) {
    final key = '${mediaId}_${chapterId}';
    return _highlights[key] ?? [];
  }
}

class Annotation {
  final String id;
  final int pageNumber;
  final String text;
  final String note;
  final Color color;
  final DateTime createdAt;
  
  Annotation({
    required this.id,
    required this.pageNumber,
    required this.text,
    required this.note,
    required this.color,
    required this.createdAt,
  });
}

class Highlight {
  final String id;
  final int pageNumber;
  final String text;
  final Color color;
  final DateTime createdAt;
  
  Highlight({
    required this.id,
    required this.pageNumber,
    required this.text,
    required this.color,
    required this.createdAt,
  });
}

/// Annotation and highlight toolbar for manga reader
class AnnotationToolbar extends StatelessWidget {
  final ReaderController controller;
  final String mediaId;
  final String chapterId;
  
  const AnnotationToolbar({
    Key? key,
    required this.controller,
    required this.mediaId,
    required this.chapterId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.edit,
            label: 'Annotate',
            onPressed: () => _showAnnotationDialog(context),
          ),
          _buildToolButton(
            icon: Icons.format_color_fill,
            label: 'Highlight',
            onPressed: () => _showHighlightDialog(context),
          ),
          _buildToolButton(
            icon: Icons.translate,
            label: 'Translate',
            onPressed: () => _showTranslateDialog(context),
          ),
          _buildToolButton(
            icon: Icons.text_fields,
            label: 'OCR',
            onPressed: () => _showOCRDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnotationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AnnotationDialog(
        mediaId: mediaId,
        chapterId: chapterId,
        currentPage: controller.currentPageIndex.value,
      ),
    );
  }

  void _showHighlightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HighlightDialog(
        mediaId: mediaId,
        chapterId: chapterId,
        currentPage: controller.currentPageIndex.value,
      ),
    );
  }

  void _showTranslateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TranslateDialog(),
    );
  }

  void _showOCRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OCRDialog(),
    );
  }
}

/// Annotation dialog for adding text annotations
class AnnotationDialog extends StatefulWidget {
  final String mediaId;
  final String chapterId;
  final int currentPage;
  
  const AnnotationDialog({
    Key? key,
    required this.mediaId,
    required this.chapterId,
    required this.currentPage,
  }) : super(key: key);

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  Color _selectedColor = Colors.yellow;
  
  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
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
              'Add Annotation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Text',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter annotation text...',
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a note...',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
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
                  onPressed: () => _saveAnnotation(),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    
    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: _selectedColor == color
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveAnnotation() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: 'Please enter annotation text'),
      );
      return;
    }
    
    final annotation = Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageNumber: widget.currentPage,
      text: _textController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      color: _selectedColor,
      createdAt: DateTime.now(),
    );
    
    AdvancedReaderFeatures.instance.addAnnotation(
      mediaId: widget.mediaId,
      chapterId: widget.chapterId,
      pageNumber: widget.currentPage,
      annotation: annotation,
    );
    
    Get.back();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Annotation saved'),
    );
  }
}

/// Highlight dialog for adding text highlights
class HighlightDialog extends StatefulWidget {
  final String mediaId;
  final String chapterId;
  final int currentPage;
  
  const HighlightDialog({
    Key? key,
    required this.mediaId,
    required this.chapterId,
    required this.currentPage,
  }) : super(key: key);

  @override
  State<HighlightDialog> createState() => _HighlightDialogState();
}

class _HighlightDialogState extends State<HighlightDialog> {
  final TextEditingController _textController = TextEditingController();
  Color _selectedColor = Colors.yellow;
  
  @override
  void dispose() {
    _textController.dispose();
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
              'Add Highlight',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Text',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text to highlight...',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
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
                  onPressed: () => _saveHighlight(),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.pink,
      Colors.red,
    ];
    
    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: _selectedColor == color
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveHighlight() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: 'Please enter text to highlight'),
      );
      return;
    }
    
    final highlight = Highlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageNumber: widget.currentPage,
      text: _textController.text.trim(),
      color: _selectedColor,
      createdAt: DateTime.now(),
    );
    
    AdvancedReaderFeatures.instance.addHighlight(
      mediaId: widget.mediaId,
      chapterId: widget.chapterId,
      pageNumber: widget.currentPage,
      highlight: highlight,
    );
    
    Get.back();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: 'Highlight saved'),
    );
  }
}

/// Placeholder translate dialog
class TranslateDialog extends StatelessWidget {
  const TranslateDialog({Key? key}) : super(key: key);

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
          children: [
            const Icon(Icons.translate, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Translate functionality coming soon',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder OCR dialog
class OCRDialog extends StatelessWidget {
  const OCRDialog({Key? key}) : super(key: key);

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
          children: [
            const Icon(Icons.text_fields, size: 48),
            const SizedBox(height: 16),
            const Text(
              'OCR functionality coming soon',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}