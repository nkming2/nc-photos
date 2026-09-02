import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/widget/image_editor/markup_toolbar_util.dart';
import 'package:nc_photos/widget/image_editor/pixel_toolbar_util.dart';
import 'package:nc_photos/widget/image_editor/toolbar_button.dart';

class MarkupToolbar extends StatefulWidget {
  const MarkupToolbar({
    super.key,
    required this.initialMarkup,
    required this.strokes,
    required this.onColorChanged,
    required this.onRadiusChanged,
    required this.onClearPressed,
    required this.onUndoPressed,
  });

  @override
  State<StatefulWidget> createState() => _MarkupToolbarState();

  final MarkupArguments initialMarkup;
  final List<BrushStroke> strokes;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onClearPressed;
  final VoidCallback onUndoPressed;
}

class _MarkupToolbarState extends State<MarkupToolbar> {
  @override
  void initState() {
    super.initState();
    _color = widget.initialMarkup.color;
    _radius = widget.initialMarkup.radius;
    _strokes = widget.strokes;
  }

  @override
  void didUpdateWidget(covariant MarkupToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.strokes, oldWidget.strokes)) {
      _strokes = widget.strokes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          alignment: Alignment.bottomCenter,
          child: switch (_selectedOption) {
            _OptionType.radius => PixelToolSlider(
              key: Key(_OptionType.radius.name),
              min: .0025,
              max: .06,
              initialValue: _radius,
              isShowMinMax: false,
              onChangeEnd: _onRadiusChanged,
            ),
            null => null,
          },
        ),
        _buildMarkupBar(context),
      ],
    );
  }

  Widget _buildMarkupBar(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              ToolbarButton(
                icon: Icons.circle,
                label: L10n.global().imageEditToolbarColorLabel,
                foregroundColorBuilder: (isSelected, isActivated) => _color,
                onPressed: _onColorTapped,
              ),
              _RadiusButton(
                isSelected: _selectedOption == _OptionType.radius,
                onPressed: () {
                  setState(() {
                    _selectedOption = _selectedOption == _OptionType.radius
                        ? null
                        : _OptionType.radius;
                  });
                },
              ),
              ToolbarButton(
                icon: Icons.clear,
                label: L10n.global().clearTooltip,
                onPressed: _strokes.isNotEmpty
                    ? () {
                        setState(() {
                          _selectedOption = null;
                        });
                        widget.onClearPressed();
                      }
                    : null,
              ),
              ToolbarButton(
                icon: Icons.undo,
                label: L10n.global().imageEditMarkupUndo,
                onPressed: _strokes.isNotEmpty
                    ? () {
                        setState(() {
                          _selectedOption = null;
                        });
                        widget.onUndoPressed();
                      }
                    : null,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onColorTapped() async {
    setState(() {
      _selectedOption = null;
    });
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initialColor: _color),
    );
    if (result != null && context.mounted) {
      _onColorChanged(result);
    }
  }

  void _onColorChanged(Color color) {
    setState(() {
      _color = color;
    });
    widget.onColorChanged(color);
  }

  void _onRadiusChanged(double radius) {
    setState(() {
      _radius = radius;
    });
    widget.onRadiusChanged(radius);
  }

  late Color _color;
  late double _radius;
  late List<BrushStroke> _strokes;
  _OptionType? _selectedOption;
}

enum _OptionType { radius }

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<StatefulWidget> createState() => _ColorPickerDialogState();

  final Color initialColor;
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().imageEditEffectParamColor),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _color,
          onColorChanged: (value) {
            setState(() {
              _color = value;
            });
          },
          enableAlpha: false,
          displayThumbColor: true,
          labelTypes: const [],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: Text(L10n.global().applyButtonLabel),
        ),
      ],
    );
  }

  late Color _color;
}

class _RadiusButton extends StatelessWidget {
  const _RadiusButton({required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ToolbarButton(
      icon: Icons.circle,
      label: L10n.global().imageEditBrushRadius,
      isSelected: isSelected,
      onPressed: onPressed,
    );
  }

  final bool isSelected;
  final VoidCallback onPressed;
}
