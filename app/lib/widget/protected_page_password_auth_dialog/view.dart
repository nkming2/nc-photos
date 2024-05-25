part of '../protected_page_password_auth_dialog.dart';

class _ErrorNotice extends StatefulWidget {
  const _ErrorNotice();

  @override
  State<StatefulWidget> createState() => _ErrorNoticeState();
}

class _ErrorNoticeState extends State<_ErrorNotice>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BlocListenerT(
      selector: (state) => state.isAuthorized,
      listener: (context, isAuthorized) {
        if (isAuthorized.value == false) {
          _controller.forward(from: 0);
        }
      },
      child: SlideTransition(
        position: _controller.drive(Animatable<Offset>.fromCallback(
            (t) => Offset(tremblingTransform(3, t) * .05, 0))),
        child: Text(
          L10n.global().appLockUnlockWrongPassword,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }

  late final _controller = AnimationController(vsync: this)
    ..duration = k.animationDurationLong;
}
