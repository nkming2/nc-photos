import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/image_editor/toolbar_button.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

enum TransformToolType {
  orientation,
}

abstract class TransformArguments {
  ImageFilter toImageFilter();

  TransformToolType _getToolType();
}

class TransformToolbar extends StatefulWidget {
  const TransformToolbar({
    Key? key,
    required this.initialState,
    required this.onActiveFiltersChanged,
  }) : super(key: key);

  @override
  createState() => _TransformToolbarState();

  final List<TransformArguments> initialState;
  final ValueChanged<Iterable<TransformArguments>> onActiveFiltersChanged;
}

class _TransformToolbarState extends State<TransformToolbar> {
  @override
  initState() {
    super.initState();
    for (final s in widget.initialState) {
      _filters[s._getToolType()] = s;
    }
  }

  @override
  build(BuildContext context) => Column(
        children: [
          _buildFilterOption(context),
          _buildFilterBar(context),
        ],
      );

  Widget _buildFilterOption(BuildContext context) {
    Widget? child;
    switch (_selectedFilter) {
      case TransformToolType.orientation:
        child = _buildOrientationOption(context);
        break;

      case null:
        child = null;
        break;
    }
    return Container(
      height: 80,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

  Widget _buildFilterBar(BuildContext context) {
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
                icon: Icons.rotate_90_degrees_ccw_outlined,
                label: L10n.global().imageEditTransformOrientation,
                onPressed: _onOrientationPressed,
                isSelected: _selectedFilter == TransformToolType.orientation,
                activationOrder:
                    _filters.containsKey(TransformToolType.orientation)
                        ? -1
                        : null,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrientationOption(BuildContext context) {
    final value =
        (_filters[TransformToolType.orientation] as _OrientationArguments)
            .value;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: _OrientationButton(
                  label:
                      "180\n${L10n.global().imageEditTransformOrientationCounterclockwise}",
                  isSelected: value == 180,
                  onPressed: () => _onOrientationOptionPressed(180),
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: _OrientationButton(
                  label:
                      "90\n${L10n.global().imageEditTransformOrientationCounterclockwise}",
                  isSelected: value == 90,
                  onPressed: () => _onOrientationOptionPressed(90),
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: _OrientationButton(
                  label: "0\n ",
                  isSelected: value == 0,
                  onPressed: () => _onOrientationOptionPressed(0),
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: _OrientationButton(
                  label:
                      "90\n${L10n.global().imageEditTransformOrientationClockwise}",
                  isSelected: value == -90,
                  onPressed: () => _onOrientationOptionPressed(-90),
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: _OrientationButton(
                  label:
                      "180\n${L10n.global().imageEditTransformOrientationClockwise}",
                  isSelected: value == -180,
                  onPressed: () => _onOrientationOptionPressed(-180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onFilterPressed(TransformToolType type, TransformArguments defArgs) {
    if (_selectedFilter == type) {
      // deactivate filter
      setState(() {
        _selectedFilter = null;
        _filters.remove(type);
      });
    } else {
      setState(() {
        _selectedFilter = type;
        _filters[type] ??= defArgs;
      });
    }
    _notifyFiltersChanged();
  }

  void _onOrientationPressed() => _onFilterPressed(
      TransformToolType.orientation, const _OrientationArguments(0));

  void _onOrientationOptionPressed(int value) {
    setState(() {
      _filters[TransformToolType.orientation] = _OrientationArguments(value);
    });
    _notifyFiltersChanged();
  }

  void _notifyFiltersChanged() {
    widget.onActiveFiltersChanged.call(_filters.values);
  }

  final _filters = <TransformToolType, TransformArguments>{};
  TransformToolType? _selectedFilter;
}

class _OrientationArguments implements TransformArguments {
  const _OrientationArguments(this.value);

  @override
  toImageFilter() => TransformOrientationFilter(value);

  @override
  _getToolType() => TransformToolType.orientation;

  final int value;
}

class _OrientationButton extends StatelessWidget {
  const _OrientationButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primarySwatchDark[500]!.withOpacity(0.7)
                    : null,
                // borderRadius: const BorderRadius.all(Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.unfocusedIconColorDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
}
