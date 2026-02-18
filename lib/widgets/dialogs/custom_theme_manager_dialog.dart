import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/custom_themes/custom_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme_registry.dart';
import 'package:anymex/services/custom_theme_loader.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomThemeManagerDialog extends StatefulWidget {
  const CustomThemeManagerDialog({super.key});

  @override
  State<CustomThemeManagerDialog> createState() => _CustomThemeManagerDialogState();
}

class _CustomThemeManagerDialogState extends State<CustomThemeManagerDialog> {
  late RxList<MediaIndicatorTheme> allThemes;
  late RxList<CustomMediaIndicatorTheme> customThemes;
  final RxString selectedThemeId = ''.obs;

  @override
  void initState() {
    super.initState();
    allThemes = MediaIndicatorThemeRegistry.builtinThemes.obs;
    customThemes = <CustomMediaIndicatorTheme>[].obs;
    _loadCustomThemes();
  }

  Future<void> _loadCustomThemes() async {
    final loaded = await MediaIndicatorThemeRegistry.getAllThemes();
    final customOnly = loaded.where((theme) => theme is CustomMediaIndicatorTheme).toList();
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
                  'Custom Themes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create and manage your custom media indicator themes',
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
    final combinedThemes = [...MediaIndicatorThemeRegistry.builtinThemes, ...customThemes];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: combinedThemes.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final themeObj = combinedThemes[index];
        final isCustom = themeObj is CustomMediaIndicatorTheme;
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
              Icons.palette_outlined,
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
                  (themeObj as CustomMediaIndicatorTheme).author,
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
                  onPressed: () => _exportTheme(context, themeObj as CustomMediaIndicatorTheme),
                  tooltip: 'Export',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTheme(context, themeObj as CustomMediaIndicatorTheme),
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
                settings.mediaIndicatorTheme = selectedThemeId.value;
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
    final result = await Get.to(() => const CustomThemeEditorDialog());
    
    if (result != null && result is CustomMediaIndicatorTheme) {
      final success = await CustomThemeLoader.saveCustomMediaIndicatorTheme(result);
      if (success) {
        snackBar('Theme created successfully!');
        await _loadCustomThemes();
      } else {
        snackBar('Failed to save theme');
      }
    }
  }

  Future<void> _exportTheme(BuildContext context, CustomMediaIndicatorTheme theme) async {
    final path = await CustomThemeLoader.exportTheme(theme);
    if (path != null) {
      snackBar('Theme exported to Downloads');
    } else {
      snackBar('Failed to export theme');
    }
  }

  Future<void> _deleteTheme(BuildContext context, CustomMediaIndicatorTheme theme) async {
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
      final success = await CustomThemeLoader.deleteCustomMediaIndicatorTheme(theme.id);
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
      final success = await CustomThemeLoader.importTheme(file.path);
      
      if (success) {
        snackBar('Theme imported successfully!');
        await _loadCustomThemes();
      } else {
        snackBar('Failed to import theme');
      }
    }
  }
}

class CustomThemeEditorDialog extends StatefulWidget {
  const CustomThemeEditorDialog({super.key});

  @override
  State<CustomThemeEditorDialog> createState() => _CustomThemeEditorDialogState();
}

class _CustomThemeEditorDialogState extends State<CustomThemeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _accentColorController = TextEditingController(text: '0xFF6366F1');
  
  String _selectedStyle = 'bar';
  bool _useCustomAccent = true;
  bool _showBorder = true;
  bool _showShadow = false;

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
                      _buildStyleSelector(context, theme),
                      const SizedBox(height: 16),
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
                        'Show Border',
                        _showBorder,
                        (value) => setState(() => _showBorder = value),
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        context,
                        theme,
                        'Enable Shadow',
                        _showShadow,
                        (value) => setState(() => _showShadow = value),
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
                  'Create Custom Theme',
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

  Widget _buildStyleSelector(BuildContext context, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedStyle,
      decoration: InputDecoration(
        labelText: 'Style',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'bar', child: Text('Bar')),
        DropdownMenuItem(value: 'circular', child: Text('Circular')),
        DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
      ],
      onChanged: (value) => setState(() => _selectedStyle = value!),
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
      final theme = CustomMediaIndicatorTheme(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        author: _authorController.text.trim(),
        config: {
          'theme': {
            'style': _selectedStyle,
            'accent_color': _accentColorController.text,
            'use_custom_accent': _useCustomAccent,
            'show_border': _showBorder,
            'show_icon': true,
            'show_percentage': true,
            'text_size': 14,
            'icon_size': 24,
            'width': 60,
            'height': 220,
          },
          'layout': {
            'position': 'auto',
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
