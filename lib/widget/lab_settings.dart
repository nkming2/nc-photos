import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';

class LabSettings extends StatefulWidget {
  static const routeName = "/lab-settings";

  const LabSettings({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _LabSettingsState();
}

class _LabSettingsState extends State<LabSettings> {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Warning"),
          content: const Text(
              "Features listed here may be untested, unfinished, or even completely broken. They may break the app and corrupt your data. No help/support will be provided.\n\nDO NOT proceed unless you understand the risk"),
          actions: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("I UNDERSTAND"),
              ),
            ),
          ],
        ),
      ).then((value) {
        if (value != true) {
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(builder: (context) => _buildContent(context)),
        appBar: AppBar(
          title: const Text("Lab Settings"),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: [
        _LabBoolItem(
          title: const Text("enableSharedAlbum"),
          isSelected: Pref.inst().isLabEnableSharedAlbumOr(false),
          onChanged: (value) {
            Pref.inst().setLabEnableSharedAlbum(value);
          },
        ),
        _LabBoolItem(
          title: const Text("enablePeople"),
          isSelected: Pref.inst().isLabEnablePeopleOr(false),
          onChanged: (value) {
            Pref.inst().setLabEnablePeople(value);
          },
        ),
      ],
    );
  }
}

class _LabBoolItem extends StatefulWidget {
  const _LabBoolItem({
    Key? key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.onChanged,
  }) : super(key: key);

  @override
  createState() => _LabBoolItemState();

  final Widget title;
  final Widget? subtitle;
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
}

class _LabBoolItemState extends State<_LabBoolItem> {
  @override
  initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  @override
  build(BuildContext context) {
    return CheckboxListTile(
      title: widget.title,
      subtitle: widget.subtitle,
      value: _isSelected,
      onChanged: (value) {
        setState(() {
          _isSelected = value!;
        });
        widget.onChanged?.call(value!);
      },
    );
  }

  late bool _isSelected;
}
