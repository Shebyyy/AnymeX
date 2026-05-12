import 'dart:io';

import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:share_plus/share_plus.dart';

class GifPreviewDialog extends StatefulWidget {
  final String gifFilePath;

  const GifPreviewDialog({
    super.key,
    required this.gifFilePath,
  });

  @override
  State<GifPreviewDialog> createState() => _GifPreviewDialogState();
}

class _GifPreviewDialogState extends State<GifPreviewDialog>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _isSharing = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final file = File(widget.gifFilePath);

    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? cs.surface : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outline.opaque(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.opaque(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.opaque(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Symbols.gif_rounded,
                        size: 24,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GIF Ready!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Preview your recording',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.opaque(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.opaque(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: cs.onSurface.opaque(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outline.opaque(0.1),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: cs.onSurface.opaque(0.3),
                              size: 48,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: cs.onSurface.opaque(0.3),
                            size: 48,
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                FutureBuilder<int?>(
                  future: _getFileSize(file),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }
                    final sizeKB = snapshot.data! / 1024;
                    final sizeStr = sizeKB < 1024
                        ? '${sizeKB.toStringAsFixed(0)} KB'
                        : '${(sizeKB / 1024).toStringAsFixed(1)} MB';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.tertiary.opaque(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: cs.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            sizeStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveGif,
                        icon: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              )
                            : Icon(Symbols.save_rounded, size: 18),
                        label: Text(_isSaving ? 'Saving...' : 'Save'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                              color: cs.outline.opaque(0.3), width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSharing ? null : _shareGif,
                        icon: _isSharing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Icon(Symbols.share_rounded, size: 18),
                        label: Text(_isSharing ? 'Sharing...' : 'Share'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int?> _getFileSize(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveGif() async {
    setState(() => _isSaving = true);
    try {
      final sourceFile = File(widget.gifFilePath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GIF file not found')),
          );
        }
        return;
      }

      final fileName =
          'anymex_gif_${DateTime.now().millisecondsSinceEpoch}.gif';

      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = null;
        }
      }

      String savedPath;
      if (saveDir != null && await saveDir.exists()) {
        savedPath = '${saveDir.path}/$fileName';
      } else {
        final tempDir = Directory.systemTemp;
        savedPath = '${tempDir.path}/$fileName';
      }

      await sourceFile.copy(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GIF saved to ${savedPath.split('/').last}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareGif() async {
    setState(() => _isSharing = true);
    try {
      await Share.shareXFiles(
        [XFile(widget.gifFilePath)],
        text: 'Made with AnymeX 🎬',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

Future<void> showGifPreviewDialog(
  BuildContext context, {
  required String gifFilePath,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => GifPreviewDialog(gifFilePath: gifFilePath),
  );
}
