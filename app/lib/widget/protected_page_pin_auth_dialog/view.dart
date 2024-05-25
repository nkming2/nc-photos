part of '../protected_page_pin_auth_dialog.dart';

class _ObsecuredInputView extends StatefulWidget {
  const _ObsecuredInputView();

  @override
  State<StatefulWidget> createState() => _ObsecuredInputViewState();
}

class _ObsecuredInputViewState extends State<_ObsecuredInputView>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _BlocListenerT(
      selector: (state) => state.isPinError,
      listener: (context, isPinError) {
        if (isPinError.value == true) {
          _controller.forward(from: 0);
        }
      },
      child: SlideTransition(
        position: _controller.drive(Animatable<Offset>.fromCallback(
            (t) => Offset(tremblingTransform(3, t) * .05, 0))),
        child: AnimatedList(
          key: context.bloc.listKey,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          initialItemCount: context.state.obsecuredInput.length,
          itemBuilder: (context, index, animation) => ScaleTransition(
            scale: animation.drive(CurveTween(curve: Curves.elasticOut)),
            child: _ObsecuredDigitDisplay(
              randomInt: context.state.obsecuredInput[index],
            ),
          ),
        ),
      ),
    );
  }

  late final _controller = AnimationController(vsync: this)
    ..duration = k.animationDurationLong;
}

class _ObsecuredDigitDisplay extends StatelessWidget {
  _ObsecuredDigitDisplay({
    required int randomInt,
  }) : text = String.fromCharCode(0x1f600 + (randomInt % 0x30));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  final String text;
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              height: 56,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.headlineMedium!,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Widget child;
  final VoidCallback? onTap;
}

class _BackspaceButton extends StatelessWidget {
  const _BackspaceButton({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              height: 56,
              child: Icon(
                Icons.backspace_outlined,
                color: onTap == null ? Theme.of(context).disabledColor : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final VoidCallback? onTap;
}
