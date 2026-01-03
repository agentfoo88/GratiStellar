import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/security/input_validator.dart';
import '../core/config/palette_preset_config.dart';
import '../font_scaling.dart';
import '../gratitude_stars.dart'; // For StarColors
import '../l10n/app_localizations.dart';
import '../storage.dart'; // For GratitudeStar
import 'color_grid.dart';
import 'scrollable_dialog_content.dart';

class ColorPickerDialog extends StatefulWidget {
  /// Initial color preset index (null if using custom color)
  final int? initialColorIndex;
  
  /// Initial custom color (null if using preset)
  final Color? initialCustomColor;
  
  /// Callback when color is selected
  final Function(int?, Color?) onColorSelected;

  /// Constructor for use with existing star
  ColorPickerDialog.fromStar({
    super.key,
    required GratitudeStar currentStar,
    required this.onColorSelected,
  }) : initialColorIndex = currentStar.customColor == null
          ? currentStar.colorPresetIndex
          : null,
       initialCustomColor = currentStar.customColor;

  /// Constructor for use with initial color values
  const ColorPickerDialog({
    super.key,
    this.initialColorIndex,
    this.initialCustomColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  // Color picker owns its state
  late Color _previewColor;
  int? _selectedColorIndex;
  (int?, Color?)? _defaultColor; // Store default color preference
  String _selectedPresetId = 'vibrant'; // Selected palette preset
  List<Color> _currentPaletteColors = StarColors.palette; // Current palette colors

  // Color picker owns its controllers
  late final TextEditingController _hexController;
  late final TextEditingController _redController;
  late final TextEditingController _greenController;
  late final TextEditingController _blueController;

  @override
  void initState() {
    super.initState();
    
    // Determine initial preview color
    if (widget.initialCustomColor != null) {
      _previewColor = widget.initialCustomColor!;
      _selectedColorIndex = null;
    } else if (widget.initialColorIndex != null) {
      _previewColor = StarColors.getColor(widget.initialColorIndex!);
      _selectedColorIndex = widget.initialColorIndex;
    } else {
      // Default to first preset color
      _previewColor = StarColors.getColor(0);
      _selectedColorIndex = 0;
    }

    _hexController = TextEditingController();
    _redController = TextEditingController();
    _greenController = TextEditingController();
    _blueController = TextEditingController();

    _updateColorControllers(_previewColor);
    _loadDefaultColor();
    _loadPalettePreset();
  }

  Future<void> _loadDefaultColor() async {
    final defaultColor = await StorageService.getDefaultColor();
    if (mounted) {
      setState(() {
        _defaultColor = defaultColor;
      });
    }
  }

  Future<void> _loadPalettePreset() async {
    final presetId = await StorageService.getSelectedPalettePreset();
    if (mounted) {
      setState(() {
        _selectedPresetId = presetId;
        _updatePaletteColors(presetId);
      });
    }
  }

  void _updatePaletteColors(String presetId) {
    final preset = PalettePresetConfig.getPresetById(presetId);
    if (preset != null) {
      _currentPaletteColors = preset.colors;
      
      // If current selected index is out of bounds for new palette, clear it
      if (_selectedColorIndex != null && _selectedColorIndex! >= _currentPaletteColors.length) {
        _selectedColorIndex = null;
        // Keep preview color as-is (might be custom)
      } else if (_selectedColorIndex != null) {
        // Update preview to match new palette color
        _previewColor = _currentPaletteColors[_selectedColorIndex!];
        _updateColorControllers(_previewColor);
      }
    }
  }

  Future<void> _onPresetChanged(String? newPresetId) async {
    if (newPresetId == null || newPresetId == _selectedPresetId) return;
    
    await StorageService.saveSelectedPalettePreset(newPresetId);
    if (mounted) {
      setState(() {
        _selectedPresetId = newPresetId;
        _updatePaletteColors(newPresetId);
      });
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  void _updateColorControllers(Color color) {
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    _hexController.text =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
    _redController.text = r.toString();
    _greenController.text = g.toString();
    _blueController.text = b.toString();
  }

  /// Helper to update preview from RGB values
  void _updateFromRGB({
    required TextEditingController redController,
    required TextEditingController greenController,
    required TextEditingController blueController,
    required TextEditingController hexController,
    required Function(Color) onUpdate,
  }) {
    try {
      final r = int.parse(redController.text).clamp(0, 255);
      final g = int.parse(greenController.text).clamp(0, 255);
      final b = int.parse(blueController.text).clamp(0, 255);

      final color = Color.fromARGB(255, r, g, b);
      setState(() {
        onUpdate(color);
        hexController.text =
            '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                .toUpperCase();
      });
    } catch (e) {
      // Invalid RGB input
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2238).withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFE135).withValues(alpha:0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ScrollableDialogContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live preview
              Text(
                AppLocalizations.of(context)!.colorPreviewTitle,
                style: FontScaling.getModalTitle(context),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              Container(
                padding:
                    EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/icon_star.svg',
                  width: FontScaling.getResponsiveIconSize(context, 64),
                  height: FontScaling.getResponsiveIconSize(context, 64),
                  colorFilter: ColorFilter.mode(_previewColor, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

              // Palette preset selector
              Text(
                'Color Palette', // TODO: Use l10n after regeneration
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
              Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: const Color(0xFF1A2238).withValues(alpha: 0.5),
                  splashColor: const Color(0xFF1A2238).withValues(alpha: 0.3),
                ),
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>('preset_$_selectedPresetId'), // Force rebuild when preset changes
                  initialValue: _selectedPresetId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFFFFE135).withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 16),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1A2238),
                  style: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  iconEnabledColor: Colors.white.withValues(alpha: 0.9),
                items: PalettePresetConfig.getPresets().map((preset) {
                  // Get localized name - use fallback until l10n is regenerated
                  String displayName;
                  switch (preset.l10nKey) {
                    case 'palettePresetWarmWhites':
                      displayName = 'Warm Whites';
                      break;
                    case 'palettePresetRealisticStars':
                      displayName = 'Realistic Stars';
                      break;
                    case 'palettePresetCoolBlues':
                      displayName = 'Cool Blues';
                      break;
                    case 'palettePresetVibrant':
                      displayName = 'Vibrant Colors';
                      break;
                    case 'palettePresetPastelDreams':
                      displayName = 'Pastel Dreams';
                      break;
                    default:
                      displayName = preset.id;
                  }
                  return DropdownMenuItem<String>(
                    value: preset.id,
                    child: Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                }).toList(),
                  onChanged: _onPresetChanged,
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // Preset colors grid
              Text(
                AppLocalizations.of(context)!.presetColorsTitle,
                style: FontScaling.getBodyMedium(context),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
              ColorGrid(
                selectedIndex: _selectedColorIndex ?? -1,
                onColorTap: (index) {
                  setState(() {
                    _selectedColorIndex = index;
                    _previewColor = _currentPaletteColors[index];
                    _updateColorControllers(_previewColor);
                  });
                },
                colors: _currentPaletteColors,
              ),

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

              // Custom color section
              Text(
                AppLocalizations.of(context)!.customColorTitle,
                style: FontScaling.getBodyMedium(context),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

              // Hex input
              TextField(
                controller: _hexController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.hexColorLabel,
                  hintText: AppLocalizations.of(context)!.hexColorHint,
                  hintStyle: FontScaling.getInputHint(context),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha:0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: FontScaling.getInputText(context),
                onChanged: (value) {
                  // Sanitize hex input
                  final sanitized = InputValidator.sanitizeHexColor(value);
                  if (sanitized == null) return; // Invalid format

                  String hexValue = sanitized;
                  if (!hexValue.startsWith('#') && hexValue.length >= 6) {
                    hexValue = '#$hexValue';
                    _hexController.value = TextEditingValue(
                      text: hexValue,
                      selection: TextSelection.collapsed(offset: hexValue.length),
                    );
                  }

                  if (hexValue.length == 7 && hexValue.startsWith('#')) {
                    try {
                      final color =
                          Color(int.parse(hexValue.substring(1), radix: 16) + 0xFF000000);
                      setState(() {
                        _previewColor = color;
                        _selectedColorIndex = null;
                        _updateColorControllers(color);
                      });
                    } catch (e) {
                      // Invalid hex
                    }
                  }
                },
              ),

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

              // RGB inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _redController,
                      decoration: InputDecoration(
                        labelText: 'R',
                        filled: true,
                        fillColor: Colors.red.withValues(alpha:0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: FontScaling.getInputText(context),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateFromRGB(
                        redController: _redController,
                        greenController: _greenController,
                        blueController: _blueController,
                        hexController: _hexController,
                        onUpdate: (color) {
                          _previewColor = color;
                          _selectedColorIndex = null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                  Expanded(
                    child: TextField(
                      controller: _greenController,
                      decoration: InputDecoration(
                        labelText: 'G',
                        filled: true,
                        fillColor: Colors.green.withValues(alpha:0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: FontScaling.getInputText(context),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateFromRGB(
                        redController: _redController,
                        greenController: _greenController,
                        blueController: _blueController,
                        hexController: _hexController,
                        onUpdate: (color) {
                          _previewColor = color;
                          _selectedColorIndex = null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                  Expanded(
                    child: TextField(
                      controller: _blueController,
                      decoration: InputDecoration(
                        labelText: 'B',
                        filled: true,
                        fillColor: Colors.blue.withValues(alpha:0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: FontScaling.getInputText(context),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateFromRGB(
                        redController: _redController,
                        greenController: _greenController,
                        blueController: _blueController,
                        hexController: _hexController,
                        onUpdate: (color) {
                          _previewColor = color;
                          _selectedColorIndex = null;
                        },
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

              // Action buttons
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_defaultColor != null)
                    TextButton.icon(
                      onPressed: () async {
                        await StorageService.clearDefaultColor();
                        if (mounted) {
                          setState(() {
                            _defaultColor = null;
                          });
                        }
                      },
                      icon: Icon(Icons.clear, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                      label: Text(
                        AppLocalizations.of(context)!.clearDefaultColor,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.cancelButton,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: Colors.white.withValues(alpha:0.6),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // If using preset color, need to map index to actual color
                      // since preset colors might differ from StarColors.palette
                      if (_selectedColorIndex != null && _selectedColorIndex! < _currentPaletteColors.length) {
                        // Using preset color - pass null for index (custom color)
                        // OR map to StarColors.palette if it exists there
                        final presetColor = _currentPaletteColors[_selectedColorIndex!];
                        // Check if this color exists in StarColors.palette
                        final starColorsIndex = StarColors.palette.indexOf(presetColor);
                        if (starColorsIndex >= 0) {
                          widget.onColorSelected(starColorsIndex, null);
                        } else {
                          // Color not in StarColors.palette, use as custom
                          widget.onColorSelected(null, presetColor);
                        }
                      } else {
                        // Custom color or no selection
                        widget.onColorSelected(
                            _selectedColorIndex,
                            _selectedColorIndex == null
                                ? _previewColor
                                : null);
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE135),
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 24),
                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.applyButton,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: const Color(0xFF1A2238),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
