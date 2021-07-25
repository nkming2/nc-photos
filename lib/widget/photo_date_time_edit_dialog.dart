import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/num_extension.dart';

class PhotoDateTimeEditDialog extends StatefulWidget {
  PhotoDateTimeEditDialog({
    Key? key,
    required this.initialDateTime,
  }) : super(key: key);

  @override
  createState() => _PhotoDateTimeEditDialogState();

  final DateTime initialDateTime;
}

class _PhotoDateTimeEditDialogState extends State<PhotoDateTimeEditDialog> {
  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).updateDateTimeDialogTitle),
      content: Form(
        key: _formKey,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.of(context).dateSubtitle,
                style: Theme.of(context).textTheme.subtitle2,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: L10n.of(context).dateYearInputHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        try {
                          int.parse(value!);
                          return null;
                        } catch (_) {
                          return L10n.of(context).dateTimeInputInvalid;
                        }
                      },
                      onSaved: (value) {
                        _formValue.year = int.parse(value!);
                      },
                      initialValue: "${widget.initialDateTime.year}",
                    ),
                    flex: 1,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: L10n.of(context).dateMonthInputHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (int.tryParse(value!)?.inRange(1, 12) == true) {
                          return null;
                        }
                        return L10n.of(context).dateTimeInputInvalid;
                      },
                      onSaved: (value) {
                        _formValue.month = int.parse(value!);
                      },
                      initialValue: widget.initialDateTime.month
                          .toString()
                          .padLeft(2, "0"),
                    ),
                    flex: 1,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: L10n.of(context).dateDayInputHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (int.tryParse(value!)?.inRange(1, 31) == true) {
                          return null;
                        }
                        return L10n.of(context).dateTimeInputInvalid;
                      },
                      onSaved: (value) {
                        _formValue.day = int.parse(value!);
                      },
                      initialValue:
                          widget.initialDateTime.day.toString().padLeft(2, "0"),
                    ),
                    flex: 1,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                L10n.of(context).timeSubtitle,
                style: Theme.of(context).textTheme.subtitle2,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: L10n.of(context).timeHourInputHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (int.tryParse(value!)?.inRange(0, 23) == true) {
                          return null;
                        }
                        return L10n.of(context).dateTimeInputInvalid;
                      },
                      onSaved: (value) {
                        _formValue.hour = int.parse(value!);
                      },
                      initialValue: widget.initialDateTime.hour
                          .toString()
                          .padLeft(2, "0"),
                    ),
                    flex: 1,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: L10n.of(context).timeMinuteInputHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (int.tryParse(value!)?.inRange(0, 59) == true) {
                          return null;
                        }
                        return L10n.of(context).dateTimeInputInvalid;
                      },
                      onSaved: (value) {
                        _formValue.minute = int.parse(value!);
                      },
                      initialValue: widget.initialDateTime.minute
                          .toString()
                          .padLeft(2, "0"),
                    ),
                    flex: 1,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: const SizedBox(),
                    flex: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _onSavePressed(context),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }

  void _onSavePressed(BuildContext context) {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState!.save();
      final d = DateTime(_formValue.year, _formValue.month, _formValue.day,
          _formValue.hour, _formValue.minute);
      _log.info("[_onSavePressed] Set date time: $d");
      Navigator.of(context).pop(d);
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _formValue = _FormValue();

  static final _log = Logger(
      "widget.photo_date_time_edit_dialog._PhotoDateTimeEditDialogState");
}

class _FormValue {
  late int year;
  late int month;
  late int day;
  late int hour;
  late int minute;
}
