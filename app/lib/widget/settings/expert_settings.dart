import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/settings/expert.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:np_codegen/np_codegen.dart';

part 'expert_settings.g.dart';

class ExpertSettings extends StatelessWidget {
  const ExpertSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpertSettingsBloc(KiwiContainer().resolve<DiContainer>()),
      child: const _WrappedExpertSettings(),
    );
  }
}

class _WrappedExpertSettings extends StatefulWidget {
  const _WrappedExpertSettings();

  @override
  State<StatefulWidget> createState() => _WrappedExpertSettingsState();
}

@npLog
class _WrappedExpertSettingsState extends State<_WrappedExpertSettings> {
  @override
  void initState() {
    super.initState();
    _errorSubscription =
        context.read<ExpertSettingsBloc>().errorStream().listen((error) {
      if (error.ev is ExpertSettingsClearCacheDatabase) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(error.error)),
          duration: k.snackBarDurationNormal,
        ));
      }
    });
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) =>
            BlocListener<ExpertSettingsBloc, ExpertSettingsState>(
          listenWhen: (previous, current) =>
              !identical(previous.lastSuccessful, current.lastSuccessful),
          listener: (context, state) {
            if (state.lastSuccessful is ExpertSettingsClearCacheDatabase) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  content: Text(L10n.global()
                      .settingsClearCacheDatabaseSuccessNotification),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel),
                    ),
                  ],
                ),
              );
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(L10n.global().settingsExpertTitle),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(L10n.global().settingsExpertWarningText),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    ListTile(
                      title:
                          Text(L10n.global().settingsClearCacheDatabaseTitle),
                      subtitle: Text(
                          L10n.global().settingsClearCacheDatabaseDescription),
                      onTap: () {
                        context
                            .read<ExpertSettingsBloc>()
                            .add(ExpertSettingsClearCacheDatabase());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  late final StreamSubscription _errorSubscription;
}
