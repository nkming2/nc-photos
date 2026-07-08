part of 'image_enhancer.dart';

class _SaveDialog extends StatelessWidget {
  const _SaveDialog();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black38)),
        _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.saveState != current.saveState,
          builder: (context, state) => switch (state.saveState) {
            _ApplyState.init => const _ProcessSaveDialog(),
            _ApplyState.prepareModel => const _PrepareModelSaveDialog(),
            _ApplyState.download => const _DownloadSaveDialog(),
            _ApplyState.background => const _ProcessBackgroundDialog(),
            null => const _ProcessSaveDialog(),
          },
        ),
      ],
    );
  }
}

class _PrepareModelSaveDialog extends StatelessWidget {
  const _PrepareModelSaveDialog();

  @override
  Widget build(BuildContext context) {
    return _DownloadProgressDialog(
      title: Text(L10n.global().imageEnhancerModelDownloadDialogText),
    );
  }
}

class _DownloadSaveDialog extends StatelessWidget {
  const _DownloadSaveDialog();

  @override
  Widget build(BuildContext context) {
    return _DownloadProgressDialog(
      title: Text(L10n.global().imageEditDownloadDialogTitle),
    );
  }
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.downloadProgress != current.downloadProgress ||
          previous.downloadSize != current.downloadSize,
      builder: (context, state) => AlertDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: state.downloadProgress),
            if (state.downloadSize != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  _getSizeText(state.downloadSize!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSizeText(int size) {
    if (size < 1024) {
      return "${size}B";
    } else if (size < 1024 * 1024) {
      return "${(size / 1024).toStringAsFixed(1)}KB";
    } else {
      return "${(size / 1024 / 1024).toStringAsFixed(1)}MB";
    }
  }

  final Widget title;
}

class _ProcessBackgroundDialog extends StatelessWidget {
  const _ProcessBackgroundDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().imageEnhancerProcessDialogTitle),
      content: Text(L10n.global().imageEnhancerProcessDialogText),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

class _ProcessSaveDialog extends StatelessWidget {
  const _ProcessSaveDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().imageEditProcessDialogTitle),
      content: const LinearProgressIndicator(),
    );
  }
}
