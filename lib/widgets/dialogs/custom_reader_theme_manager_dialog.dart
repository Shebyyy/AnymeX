import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/custom_themes/custom_reader_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/services/custom_theme_loader.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomReaderThemeManagerDialog extends StatefulWidget {
  const CustomReaderThemeManagerDialog({super.key});

  @override
  State<CustomReaderThemeManagerDialog> createState() => _CustomReaderThemeManagerDialogState();
}

class _CustomReaderThemeManagerDialogState extends State<CustomReaderThemeManagerDialog> {
  late RxList<dynamic> allThemes;
  late RxList<CustomReaderTheme> customThemes;
  final RxString selectedThemeId = ''.obs;

  @override
  void initState() {
    super.initState();
    allThemes = ReaderControlThemeRegistry.builtinThemes.obs;
    customThemes = <CustomReaderTheme>[].obs;
    _loadCustomThemes();
  }

  Future<void> _loadCustomThemes() async {
    final loaded = await ReaderControlThemeRegistry.getAllThemes();
    final customOnly = loaded.whereType<CustomReaderTheme>().toList();
    customThemes.value = customOnly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: Obx(() => _buildThemeList(context)),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Reader Themes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create and manage your custom reader themes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList(BuildContext context) {
    final theme = Theme.of(context);
    final combinedThemes = [...ReaderControlThemeRegistry.builtinThemes, ...customThemes];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: combinedThemes.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final themeObj = combinedThemes[index];
        final isCustom = themeObj is CustomReaderTheme;
        final isSelected = selectedThemeId.value == themeObj.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isCustom
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          title: Text(
            themeObj.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: isCustom
              ? Text(
                  (themeObj as CustomReaderTheme).author,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustom) ...[
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _exportTheme(context, themeObj as CustomReaderTheme),
                  tooltip: 'Export',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTheme(context, themeObj as CustomReaderTheme),
                  tooltip: 'Delete',
                ),
              ],
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                )
              else
                const Icon(Icons.circle_outlined,
                  color: Colors.transparent,
                ),
            ],
          ),
          onTap: () {
            selectedThemeId.value = themeObj.id;
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _importTheme(context),
            icon: const Icon(Icons.file_upload_rounded),
            label: const Text('Import'),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _createNewTheme(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Theme'),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              final settings = Get.find<Settings>();
              if (selectedThemeId.value.isNotEmpty) {
                settings.readerControlTheme = selectedThemeId.value;
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewTheme(BuildContext context) async {
    final result = await Get.to(() => const CustomReaderThemeEditorDialog());

    if (result != null && result is CustomReaderTheme) {
      final success = await CustomThemeLoader.saveCustomReaderTheme(result);
      if (success) {
        snackBar('Theme created successfully!');
        await _loadCustomThemes();
      } else {
        snackBar('Failed to save theme');
      }
    }
  }

  Future<void> _exportTheme(BuildContext context, CustomReaderTheme theme) async {
    final path = await CustomThemeLoader.exportTheme(theme);
    if (path != null) {
      snackBar('Theme exported to Downloads');
    } else {
      snackBar('Failed to export theme');
    }
  }

  Future<void> _deleteTheme(BuildContext context, CustomReaderTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CustomThemeLoader.deleteCustomReaderTheme(theme.id);
      if (success) {
        snackBar('Theme deleted');
        await _loadCustomThemes();
      } else {
        snackBar('Failed to delete theme');
      }
    }
  }

  Future<void> _importTheme(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select Theme File',
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final success = await CustomThemeLoader.importTheme(file.path!);

      if (success) {
        snackBar('Theme imported successfully!');
        await _loadCustomThemes();
      } else {
        snackBar('Failed to import theme');
      }
    }
  }
}

class CustomReaderThemeEditorDialog extends StatefulWidget {
  const CustomReaderThemeEditorDialog({super.key});

  @override
  State<CustomReaderThemeEditorDialog> createState() => _CustomReaderThemeEditorDialogState();
}

class _CustomReaderThemeEditorDialogState extends State<CustomReaderThemeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _accentColorController = TextEditingController(text: '0xFF6366F1');

  bool _useCustomAccent = true;
  bool _showBackground = true;
  bool _showProgress = true;
  bool _showNavigation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _accentColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditorHeader(context, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Basic Info'),
                      _buildNameField(context, theme),
                      const SizedBox(height: 16),
                      _buildAuthorField(context, theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Appearance'),
                      _buildColorPicker(context, theme),
                      const SizedBox(height: 16),
                      _buildToggleRow(
                        context,
                        theme,
                        'Custom Accent Color',
                        _useCustomAccent,
                        (value) => setState(() => _useCustomAccent = value),
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        context,
                        theme,
                        'Show Background',
                        _showBackground,
                        (value) => setState(() => _showBackground = value),
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        context,
                        theme,
                        'Show Progress',
                        _showProgress,
                        (value) => setState(() => _showProgress = value),
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        context,
                        theme,
                        'Show Navigation',
                        _showNavigation,
                        (value) => setState(() => _showNavigation = value),
                      ),
                    ],
                  ),
                ),
              ),
              _buildEditorFooter(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Custom Reader Theme',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNameField(BuildContext context, ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Theme Name',
        hintText: 'My Awesome Theme',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a theme name';
        }
        return null;
      },
    );
  }

  Widget _buildAuthorField(BuildContext context, ThemeData theme) {
    return TextFormField(
      controller: _authorController,
      decoration: InputDecoration(
        labelText: 'Author',
        hintText: 'Your Name',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: _pickColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _accentColorController.text.isNotEmpty
              ? Color(int.parse(_accentColorController.text))
              : Colors.grey[400],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.palette_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Pick Accent Color',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    ThemeData theme,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildEditorFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saveTheme,
              child: const Text('Save Theme'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Color'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ColorPicker(
            pickerColor: _accentColorController.text.isNotEmpty
                ? Color(int.parse(_accentColorController.text))
                : Colors.blue,
          ),
        ),
      ),
    );

    if (result != null) {
      _accentColorController.text = '0x${result.value.toRadixString(16)}';
    }
  }

  void _saveTheme() {
    if (_formKey.currentState?.validate() ?? false) {
      final theme = CustomReaderTheme(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        author: _authorController.text.trim(),
        config: {
          'top_controls': {
            'show_background': _showBackground,
            'icon_color': _useCustomAccent ? _accentColorController.text : null,
          },
          'bottom_controls': {
            'show_background': _showBackground,
            'show_progress': _showProgress,
            'show_navigation': _showNavigation,
            'progress_color': _useCustomAccent ? _accentColorController.text : null,
            'icon_color': _useCustomAccent ? _accentColorController.text : null,
          },
        },
      );

      Navigator.pop(context, theme);
    }
  }
}

class ColorPicker extends StatefulWidget {
  final Color pickerColor;

  const ColorPicker({required this.pickerColor, super.key});

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: _selectedColor == color
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
