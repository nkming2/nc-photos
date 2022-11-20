import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/activity.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/compat/v29.dart';
import 'package:nc_photos/use_case/compat/v46.dart';
import 'package:nc_photos/use_case/compat/v55.dart';
import 'package:nc_photos/widget/changelog.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/sign_in.dart';

class Splash extends StatefulWidget {
  static const routeName = "/splash";

  const Splash({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doWork();
    });
  }

  Future<void> _doWork() async {
    if (Pref().getFirstRunTime() == null) {
      await Pref().setFirstRunTime(DateTime.now().millisecondsSinceEpoch);
    }
    if (_shouldUpgrade()) {
      setState(() {
        _isUpgrading = true;
      });
      await _handleUpgrade();
      setState(() {
        _isUpgrading = false;
      });
    }
    unawaited(_exit());
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () => Future.value(false),
        child: Builder(builder: (context) => _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  L10n.global().appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          ),
          if (_isUpgrading)
            BlocBuilder<_UpgradeCubit, _UpgradeState>(
              bloc: _upgradeCubit,
              builder: (context, state) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(state.text),
                      const SizedBox(height: 8),
                      if (state.count == null)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      else
                        LinearProgressIndicator(
                          value: state.current / state.count!,
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _exit() async {
    _log.info("[_exit]");
    final account = Pref().getCurrentAccount();
    if (isNeedSetup()) {
      unawaited(Navigator.pushReplacementNamed(context, Setup.routeName));
    } else if (account == null) {
      unawaited(Navigator.pushReplacementNamed(context, SignIn.routeName));
    } else {
      unawaited(
        Navigator.pushReplacementNamed(context, Home.routeName,
            arguments: HomeArguments(account)),
      );
      if (platform_k.isAndroid) {
        final initialRoute = await Activity.consumeInitialRoute();
        if (initialRoute != null) {
          unawaited(Navigator.pushNamed(context, initialRoute));
        }
      }
    }
  }

  bool _shouldUpgrade() {
    final lastVersion = Pref().getLastVersionOr(k.version);
    return lastVersion < k.version;
  }

  Future<void> _handleUpgrade() async {
    try {
      final lastVersion = Pref().getLastVersionOr(k.version);
      unawaited(_showChangelogIfAvailable(lastVersion));
      // begin upgrade while showing the changelog
      try {
        _log.info("[_handleUpgrade] Upgrade: $lastVersion -> ${k.version}");
        await _upgrade(lastVersion);
        _log.info("[_handleUpgrade] Upgrade done");
      } finally {
        // ensure user has closed the changelog
        await _changelogCompleter.future;
      }
    } catch (e, stackTrace) {
      _log.shout("[_handleUpgrade] Failed while upgrade", e, stackTrace);
    } finally {
      await Pref().setLastVersion(k.version);
    }
  }

  Future<void> _upgrade(int lastVersion) async {
    if (lastVersion < 290) {
      await _upgrade29(lastVersion);
    }
    if (lastVersion < 460) {
      await _upgrade46(lastVersion);
    }
    if (lastVersion < 550) {
      await _upgrade55(lastVersion);
    }
  }

  Future<void> _upgrade29(int lastVersion) async {
    try {
      _log.info("[_upgrade29] clearDefaultCache");
      await CompatV29.clearDefaultCache();
    } catch (e, stackTrace) {
      _log.shout("[_upgrade29] Failed while clearDefaultCache", e, stackTrace);
      // just leave the cache then
    }
  }

  Future<void> _upgrade46(int lastVersion) async {
    try {
      _log.info("[_upgrade46] insertDbAccounts");
      final c = KiwiContainer().resolve<DiContainer>();
      await CompatV46.insertDbAccounts(Pref(), c.sqliteDb);
    } catch (e, stackTrace) {
      _log.shout("[_upgrade46] Failed while clearDefaultCache", e, stackTrace);
      unawaited(Pref().setAccounts3(null));
      unawaited(Pref().setCurrentAccountIndex(null));
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: const Text(
              "Failed upgrading app, please sign in to your servers again"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _upgrade55(int lastVersion) async {
    final c = KiwiContainer().resolve<DiContainer>();
    try {
      _log.info("[_upgrade55] migrate DB");
      await CompatV55.migrateDb(
        c.sqliteDb,
        onProgress: (current, count) {
          _upgradeCubit.setState(
            L10n.global().migrateDatabaseProcessingNotification,
            current,
            count,
          );
        },
      );
    } catch (e, stackTrace) {
      _log.shout("[_upgrade55] Failed while migrateDb", e, stackTrace);
      await c.sqliteDb.use((db) async {
        await db.truncate();
        final accounts = Pref().getAccounts3Or([]);
        for (final a in accounts) {
          await db.insertAccountOf(a);
        }
      });
    }
    _upgradeCubit.setIntermediate();
  }

  Future<void> _showChangelogIfAvailable(int lastVersion) async {
    if (Changelog.hasContent(lastVersion)) {
      try {
        await Navigator.of(context).pushNamed(Changelog.routeName,
            arguments: ChangelogArguments(lastVersion));
      } catch (e, stackTrace) {
        _log.severe(
            "[_showChangelogIfAvailable] Uncaught exception", e, stackTrace);
      } finally {
        _changelogCompleter.complete();
      }
    } else {
      _changelogCompleter.complete();
    }
  }

  final _changelogCompleter = Completer();
  var _isUpgrading = false;
  late final _upgradeCubit = _UpgradeCubit();

  static final _log = Logger("widget.splash._SplashState");
}

class _UpgradeState {
  const _UpgradeState(String text, int current, int count)
      : this._(text, current, count);

  const _UpgradeState.intermediate([String? text])
      : this._(text ?? "Updating", 0, null);

  const _UpgradeState._(this.text, this.current, this.count);

  @override
  String toString() => "_UpgradeState {"
      "current: $current, "
      "count: $count, "
      "}";

  final String text;
  final int current;
  final int? count;
}

class _UpgradeCubit extends Cubit<_UpgradeState> {
  _UpgradeCubit() : super(const _UpgradeState.intermediate());

  void setIntermediate() => emit(const _UpgradeState.intermediate());

  void setState(String text, int current, int count) =>
      emit(_UpgradeState(text, current, count));
}
