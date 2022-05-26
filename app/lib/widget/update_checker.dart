import 'package:flutter/material.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/update_checker.dart' as checker;
import 'package:nc_photos/url_launcher_util.dart';

class UpdateChecker extends StatefulWidget {
  static const routeName = "/update-checker";

  static Route buildRoute() => MaterialPageRoute(
        builder: (context) => const UpdateChecker(),
      );

  const UpdateChecker({Key? key}) : super(key: key);

  @override
  createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  initState() {
    super.initState();
    _work();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        body: Builder(
          builder: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Photos ${k.versionStr}",
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.center,
              child: _getStatusWidget(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: Text(
                _getStatusText(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            if (_result == checker.UpdateCheckerResult.updateAvailable)
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    launch("https://bit.ly/3wNLHFo");
                  },
                  child: const Text("GET UPDATE"),
                ),
              )
            else
              const SizedBox(height: 48),
            const SizedBox(height: 32),
            const Text(
              "Photos is a personal project with a lack of funding. "
              "I need your help for this project to be sustainable. "
              "Please consider making a donation if you like this app.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your donations will ensure this project to both remain under development and stay open source.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  launch("https://bit.ly/3wQOHPZ");
                },
                child: const Text("DONATE"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _work() async {
    await Future.delayed(const Duration(seconds: 3));
    final result = await const checker.UpdateChecker()();
    if (mounted) {
      setState(() {
        _result = result;
      });
    }
  }

  Widget _getStatusWidget() {
    if (_result == null) {
      return const SizedBox(
        width: _statusIconSize,
        height: _statusIconSize,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      switch (_result!) {
        case checker.UpdateCheckerResult.updateAvailable:
          return Icon(
            Icons.upload,
            color: Colors.orange[700],
            size: _statusIconSize,
          );

        case checker.UpdateCheckerResult.alreadyLatest:
          return Icon(
            Icons.done,
            color: Colors.green[600],
            size: _statusIconSize,
          );

        case checker.UpdateCheckerResult.error:
          return Icon(
            Icons.warning,
            color: Colors.red[700],
            size: _statusIconSize,
          );
      }
    }
  }

  String _getStatusText() {
    if (_result == null) {
      return "Checking...";
    } else {
      switch (_result!) {
        case checker.UpdateCheckerResult.updateAvailable:
          return "Update available";

        case checker.UpdateCheckerResult.alreadyLatest:
          return "You are running the latest version";

        case checker.UpdateCheckerResult.error:
          return "Failed checking for updates";
      }
    }
  }

  checker.UpdateCheckerResult? _result;

  static const _statusIconSize = 72.0;
}
