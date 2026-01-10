/// Logo Animation Preview Dialog

import 'package:flutter/material.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoAnimationPreviewDialog extends StatefulWidget {
  final LogoAnimationType initialAnimation;
  final Function(LogoAnimationType, Color?, Gradient?) onConfirm;
  final Color? initialColor;
  final Gradient? initialGradient;
  final double? initialSpeed;

  const LogoAnimationPreviewDialog({
    Key? key,
    required this.initialAnimation,
    required this.onConfirm,
    this.initialColor,
    this.initialGradient,
    this.initialSpeed,
  }) : super(key: key);

  @override
  State<LogoAnimationPreviewDialog> createState() => _LogoAnimationPreviewDialogState();
}

class _LogoAnimationPreviewDialogState extends State<LogoAnimationPreviewDialog> {
  late LogoAnimationType _selectedAnimation;
  late Color _selectedColor;
  late Gradient? _selectedGradient;
  bool _useCustomColor = false;
  late double _animationSpeed;
  Key _logoKey = UniqueKey();
  final _presetColorsBox = Hive.box('logoPresets');
  final _speedBox = Hive.box('animationSpeed');

  // Theme colors for fallback
  final List<Color> _themeColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
    Colors.green,
  ];

  // Preset gradients
  final List<Gradient> _presetGradients = [
    const LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.pink, Colors.orange],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.teal, Colors.cyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.red, Colors.yellow],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // Animation speeds
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _selectedAnimation = widget.initialAnimation;
    _selectedColor = widget.initialColor ?? Theme.of(context).colorScheme.primary;
    _selectedGradient = widget.initialGradient;
    _useCustomColor = widget.initialColor != null || widget.initialGradient != null;
    _animationSpeed = widget.initialSpeed ?? _speedBox.get('logoSpeed', defaultValue: 1.0);
  }

  void _replayAnimation() {
    setState(() {
      _logoKey = UniqueKey();
    });
  }

  void _selectThemeColor(Color color) {
    setState(() {
      _selectedColor = color;
      _selectedGradient = null;
      _useCustomColor = true;
      _logoKey = UniqueKey();
    });
  }

  void _selectGradient(Gradient gradient) {
    setState(() {
      _selectedGradient = gradient;
      _selectedColor = Colors.transparent;
      _useCustomColor = true;
      _logoKey = UniqueKey();
    });
  }

  void _clearCustomColor() {
    setState(() {
      _selectedColor = Theme.of(context).colorScheme.primary;
      _selectedGradient = null;
      _useCustomColor = false;
      _logoKey = UniqueKey();
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Custom Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _selectedGradient = null;
                _useCustomColor = true;
                _logoKey = UniqueKey();
              });
            },
            showLabel: true,
            paletteType: PaletteType.hsv,
            pickerAreaHeightPercent: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _savePreset() {
    final presetName = 'Preset ${_presetColorsBox.length + 1}';
    final preset = {
      'color': _selectedColor.value,
      'gradient': _selectedGradient != null ? _serializeGradient(_selectedGradient!) : null,
      'animation': _selectedAnimation.index,
      'speed': _animationSpeed,
    };
    _presetColorsBox.put(presetName, preset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preset "$presetName" saved!')),
    );
  }

  void _loadPreset(String name) {
    final preset = _presetColorsBox.get(name) as Map?;
    if (preset != null) {
      setState(() {
        _selectedColor = Color(preset['color'] as int);
        _selectedGradient = preset['gradient'] != null 
            ? _deserializeGradient(preset['gradient'] as Map)
            : null;
        _selectedAnimation = LogoAnimationType.fromIndex(preset['animation'] as int);
        _animationSpeed = preset['speed'] as double;
        _useCustomColor = true;
        _logoKey = UniqueKey();
      });
    }
  }

  void _showPresets() {
    final presetNames = _presetColorsBox.keys.cast<String>().toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Presets'),
        content: presetNames.isEmpty
            ? const Text('No presets saved yet.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: presetNames.length,
                  itemBuilder: (context, index) {
                    final name = presetNames[index];
                    final preset = _presetColorsBox.get(name) as Map?;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('Animation: ${LogoAnimationType.fromIndex(preset?['animation'] as int).displayName}'),
                      leading: preset?['color'] != null
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(preset!['color'] as int),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => _loadPreset(name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _presetColorsBox.delete(name);
                          Navigator.of(context).pop();
                          _showPresets();
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSpeedSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Animation Speed'),
        content: SizedBox(
          width: 200,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _speedOptions.length,
            itemBuilder: (context, index) {
              final speed = _speedOptions[index];
              final isSelected = _animationSpeed == speed;
              return ListTile(
                title: Text('${speed}x'),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _animationSpeed = speed;
                    _speedBox.put('logoSpeed', speed);
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _previewAllAnimations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview All Animations'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: LogoAnimationType.values.length,
            itemBuilder: (context, index) {
              final animationType = LogoAnimationType.values[index];
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: AnymeXAnimatedLogo(
                          key: UniqueKey(),
                          size: 50,
                          autoPlay: true,
                          forceAnimationType: animationType,
                          color: _useCustomColor ? _selectedColor : null,
                          gradient: _selectedGradient,
                          onAnimationComplete: () => Future.delayed(const Duration(milliseconds: 500)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animationType.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _serializeGradient(Gradient gradient) {
    if (gradient is LinearGradient) {
      return {
        'type': 'linear',
        'colors': gradient.colors.map((c) => c.value).toList(),
        'begin': {
          'dx': gradient.begin.dx,
          'dy': gradient.begin.dy,
        },
        'end': {
          'dx': gradient.end.dx,
          'dy': gradient.end.dy,
        },
      };
    }
    return {};
  }

  Gradient _deserializeGradient(Map data) {
    if (data['type'] == 'linear') {
      return LinearGradient(
        colors: (data['colors'] as List).map((v) => Color(v as int)).toList(),
        begin: Alignment(
          data['begin']['dx'] as double,
          data['begin']['dy'] as double,
        ),
        end: Alignment(
          data['end']['dx'] as double,
          data['end']['dy'] as double,
        ),
      );
    }
    return const LinearGradient(colors: [Colors.blue]);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;
    
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 800 : 600,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logo Animation & Colors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
            ),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(_selectedAnimation, 
                            _useCustomColor ? _selectedColor : null, 
                            _selectedGradient);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primaryFixed,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "LexendDeca",
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AnymeXAnimatedLogo(
                    key: _logoKey,
                    size: 120,
                    autoPlay: true,
                    forceAnimationType: _selectedAnimation,
                    color: _useCustomColor ? _selectedColor : null,
                    gradient: _selectedGradient,
                    duration: Duration(milliseconds: (2000 / _animationSpeed).round()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Replay'),
                onPressed: _replayAnimation,
              ),
              const SizedBox(height: 16),
              
              // Color Selection Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Color Scheme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Theme Colors Row
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _themeColors.length + 2, // +2 for custom and clear
                  itemBuilder: (context, index) {
                    if (index == _themeColors.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _showColorPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useCustomColor 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.colorize,
                                size: 20,
                                color: _useCustomColor 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _useCustomColor 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (index == _themeColors.length + 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _clearCustomColor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useCustomColor 
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restore,
                                size: 20,
                                color: _useCustomColor 
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _useCustomColor 
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final color = _themeColors[index];
                    final isSelected = _useCustomColor && _selectedColor == color;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _selectThemeColor(color),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Gradient Selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gradient Presets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetGradients.length + 2, // +2 for save and presets
                  itemBuilder: (context, index) {
                    if (index == _presetGradients.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _savePreset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.save,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Save Preset',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (index == _presetGradients.length + 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _showPresets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.collections,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Presets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final gradient = _presetGradients[index];
                    final isSelected = _useCustomColor && _selectedGradient == gradient;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _selectGradient(gradient),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Speed Control
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Animation Speed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _speedOptions.length,
                  itemBuilder: (context, index) {
                    final speed = _speedOptions[index];
                    final isSelected = _animationSpeed == speed;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () => _showSpeedSelector(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Preview All Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _previewAllAnimations,
                  icon: const Icon(Icons.grid_view, size: 18),
                  label: const Text('Preview All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Animation List
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Animation Style',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        
        // Animation List (Scrollable)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAnimationList(),
          ),
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Preview
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AnymeXAnimatedLogo(
                      key: _logoKey,
                      size: 140,
                      autoPlay: true,
                      forceAnimationType: _selectedAnimation,
                      color: _useCustomColor ? _selectedColor : null,
                      gradient: _selectedGradient,
                      duration: Duration(milliseconds: (2000 / _animationSpeed).round()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay'),
                  onPressed: _replayAnimation,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Right side - Controls
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color Selection
                const Text(
                  'Color Scheme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Theme Colors Grid
                SizedBox(
                  height: 80,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _themeColors.length + 2,
                    itemBuilder: (context, index) {
                      if (index == _themeColors.length) {
                        return ElevatedButton(
                          onPressed: _showColorPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useCustomColor 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.colorize,
                                size: 16,
                                color: _useCustomColor 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _useCustomColor 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (index == _themeColors.length + 1) {
                        return ElevatedButton(
                          onPressed: _clearCustomColor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useCustomColor 
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restore,
                                size: 16,
                                color: _useCustomColor 
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _useCustomColor 
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final color = _themeColors[index];
                      final isSelected = _useCustomColor && _selectedColor == color;
                      
                      return GestureDetector(
                        onTap: () => _selectThemeColor(color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Gradient Selection
                const Text(
                  'Gradient Presets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  height: 80,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _presetGradients.length + 2,
                    itemBuilder: (context, index) {
                      if (index == _presetGradients.length) {
                        return ElevatedButton(
                          onPressed: _savePreset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (index == _presetGradients.length + 1) {
                        return ElevatedButton(
                          onPressed: _showPresets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Presets',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final gradient = _presetGradients[index];
                      final isSelected = _useCustomColor && _selectedGradient == gradient;
                      
                      return GestureDetector(
                        onTap: () => _selectGradient(gradient),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Speed Control
                const Text(
                  'Animation Speed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _speedOptions.length,
                    itemBuilder: (context, index) {
                      final speed = _speedOptions[index];
                      final isSelected = _animationSpeed == speed;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => _showSpeedSelector(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Preview All Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _previewAllAnimations,
                    icon: const Icon(Icons.grid_view, size: 16),
                    label: const Text('Preview All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Animation List
                const Text(
                  'Select Animation Style',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildAnimationList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationList() {
    return ListView.builder(
      itemCount: LogoAnimationType.values.length,
      itemBuilder: (context, index) {
        final animationType = LogoAnimationType.values[index];
        final isSelected = _selectedAnimation == animationType;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedAnimation = animationType;
                  _logoKey = UniqueKey();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animationType.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            animationType.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
