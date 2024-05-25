import 'dart:math';

import 'package:copy_with/copy_with.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/animation_util.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_collection/np_collection.dart';
import 'package:np_common/unique.dart';
import 'package:np_string/np_string.dart';
import 'package:to_string/to_string.dart';

part 'protected_page_pin_auth_dialog.g.dart';
part 'protected_page_pin_auth_dialog/bloc.dart';
part 'protected_page_pin_auth_dialog/state_event.dart';
part 'protected_page_pin_auth_dialog/view.dart';

class ProtectedPagePinAuthDialog extends StatelessWidget {
  const ProtectedPagePinAuthDialog({
    super.key,
    required this.pin,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(
        pin: pin,
        removeItemBuilder: (_, animation, value) => ScaleTransition(
          scale: animation.drive(CurveTween(curve: Curves.linear)),
          child: _ObsecuredDigitDisplay(randomInt: value),
        ),
      ),
      child: _WrappedProtectedPagePinAuthDialog(),
    );
  }

  final CiString pin;
}

class _WrappedProtectedPagePinAuthDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        _BlocListenerT(
          selector: (state) => state.isAuthorized,
          listener: (context, isAuthorized) {
            if (isAuthorized) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
      child: AlertDialog(
        title: Text(L10n.global().appLockUnlockHint),
        scrollable: true,
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 64,
                child: Align(
                  alignment: Alignment(0, -0.5),
                  child: _ObsecuredInputView(),
                ),
              ),
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [1, 2, 3]
                        .map(
                          (e) => _DigitButton(
                            child: Text(e.toString()),
                            onTap: () {
                              context.addEvent(_PushDigit(e));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  TableRow(
                    children: [4, 5, 6]
                        .map(
                          (e) => _DigitButton(
                            child: Text(e.toString()),
                            onTap: () {
                              context.addEvent(_PushDigit(e));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  TableRow(
                    children: [7, 8, 9]
                        .map(
                          (e) => _DigitButton(
                            child: Text(e.toString()),
                            onTap: () {
                              context.addEvent(_PushDigit(e));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      _DigitButton(
                        child: const Text("0"),
                        onTap: () {
                          context.addEvent(const _PushDigit(0));
                        },
                      ),
                      _BlocSelector(
                        selector: (state) => state.obsecuredInput.isEmpty,
                        builder: (context, isEmpty) => _BackspaceButton(
                          onTap: isEmpty
                              ? null
                              : () {
                                  context.addEvent(const _PopDigit());
                                },
                        ),
                      ),
                    ],
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

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
