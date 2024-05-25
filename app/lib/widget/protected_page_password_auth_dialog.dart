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
import 'package:np_common/unique.dart';
import 'package:np_string/np_string.dart';
import 'package:to_string/to_string.dart';

part 'protected_page_password_auth_dialog.g.dart';
part 'protected_page_password_auth_dialog/bloc.dart';
part 'protected_page_password_auth_dialog/state_event.dart';
part 'protected_page_password_auth_dialog/view.dart';

class ProtectedPagePasswordAuthDialog extends StatelessWidget {
  const ProtectedPagePasswordAuthDialog({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(
        password: password,
      ),
      child: _WrappedProtectedPagePasswordAuthDialog(),
    );
  }

  final CiString password;
}

class _WrappedProtectedPagePasswordAuthDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        _BlocListenerT(
          selector: (state) => state.isAuthorized,
          listener: (context, isAuthorized) {
            if (isAuthorized.value == true) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
      child: AlertDialog(
        title: Text(L10n.global().appLockUnlockHint),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              keyboardType: TextInputType.text,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: L10n.global().passwordInputHint,
              ),
              onSubmitted: (value) {
                context.addEvent(_Submit(value));
              },
            ),
            _BlocSelector(
              selector: (state) => state.isAuthorized,
              builder: (context, isAuthorized) {
                if (isAuthorized.value == false) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 4),
                    child: _ErrorNotice(),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
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
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
