part of '../file_content_view.dart';

class _LivePhotoPageContentView extends StatelessWidget {
  const _LivePhotoPageContentView({
    required this.livePhotoType,
  });

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.file != current.file || previous.canPlay != current.canPlay,
      builder: (context, state) => state.file == null
          ? Container()
          : LivePhotoViewer(
              account: context.bloc.account,
              file: state.file!,
              livePhotoType: livePhotoType,
              canPlay: state.canPlay,
              onLoaded: () {
                context.addEvent(const _SetLoaded());
              },
              onHeightChanged: (height) {
                context.addEvent(_SetContentHeight(height));
              },
              onLoadFailure: () {
                context.addEvent(const _SetLivePhotoLoadFailed());
              },
            ),
    );
  }

  final LivePhotoType livePhotoType;
}

class _PhotoPageContentView extends StatelessWidget {
  const _PhotoPageContentView();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.file != current.file || previous.canZoom != current.canZoom,
      builder: (context, state) => state.file == null
          ? Container()
          : RemoteImageViewer(
              account: context.bloc.account,
              file: state.file!,
              canZoom: state.canZoom,
              onLoaded: () {
                context.addEvent(const _SetLoaded());
              },
              onHeightChanged: (height) {
                context.addEvent(_SetContentHeight(height));
              },
              onZoomStarted: () {
                context.addEvent(const _SetIsZoomed(true));
              },
              onZoomEnded: () {
                context.addEvent(const _SetIsZoomed(false));
              },
            ),
    );
  }
}

class _VideoPageContentView extends StatelessWidget {
  const _VideoPageContentView();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.file != current.file ||
          previous.canZoom != current.canZoom ||
          previous.isPlayControlVisible != current.isPlayControlVisible ||
          previous.canPlay != current.canPlay,
      builder: (context, state) => state.file == null
          ? Container()
          : VideoViewer(
              account: context.bloc.account,
              file: state.file!,
              canZoom: state.canZoom,
              canPlay: state.canPlay,
              isControlVisible: state.isPlayControlVisible,
              onLoaded: () {
                context.addEvent(const _SetLoaded());
              },
              onHeightChanged: (height) {
                context.addEvent(_SetContentHeight(height));
              },
              onZoomStarted: () {
                context.addEvent(const _SetIsZoomed(true));
              },
              onZoomEnded: () {
                context.addEvent(const _SetIsZoomed(false));
              },
              onPlay: () {
                context.addEvent(const _SetPlaying());
              },
              onPause: () {
                context.addEvent(const _SetPause());
              },
            ),
    );
  }
}
