part of '../viewer.dart';

class _OpenDetailPaneRequest {
  const _OpenDetailPaneRequest(this.shouldAnimate);

  final bool shouldAnimate;
}

class _ShareRequest {
  const _ShareRequest(this.file);

  final FileDescriptor file;
}

class _SlideshowRequest {
  const _SlideshowRequest({
    required this.account,
    required this.files,
    required this.startIndex,
  });

  final Account account;
  final List<FileDescriptor> files;
  final int startIndex;
}

class _SetAsRequest {
  const _SetAsRequest({
    required this.account,
    required this.file,
  });

  final Account account;
  final FileDescriptor file;
}
