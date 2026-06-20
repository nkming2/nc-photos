part of 'image_enhancer.dart';

class _MethodShowcase extends StatefulWidget {
  const _MethodShowcase();

  @override
  State<StatefulWidget> createState() => _MethodShowcaseState();
}

class _MethodShowcaseState extends State<_MethodShowcase> {
  @override
  Widget build(BuildContext context) {
    return _BlocListenerT(
      selector: (state) => state.selectedMethod,
      listener: (context, selectedMethod) {
        final i = _Method.values.indexOf(selectedMethod);
        _pageController.animateToPage(
          i,
          duration: k.animationDurationNormal,
          curve: Curves.easeInOut,
        );
      },
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _Method.values.length,
        itemBuilder: (context, i) {
          final m = _Method.values[i];
          return Padding(
            padding: const EdgeInsets.all(48),
            child: switch (m) {
              _Method.retouch => const _RetouchShowcase(),
              _Method.superResolution => const _SuperResolutionShowcase(),
              _Method.derain => const _DerainShowcase(),
            },
          );
        },
      ),
    );
  }

  late final _pageController = PageController(keepPage: false);
}

class _RetouchShowcase extends StatelessWidget {
  const _RetouchShowcase();

  @override
  Widget build(BuildContext context) {
    return _SampleShowcase(
      from: Image.asset(
        "assets/retouch0.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      to: Image.asset(
        "assets/retouch1.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

class _SuperResolutionShowcase extends StatelessWidget {
  const _SuperResolutionShowcase();

  @override
  Widget build(BuildContext context) {
    return _SampleShowcase(
      from: Image.asset(
        "assets/super-resolution0.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      to: Image.asset(
        "assets/super-resolution1.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

class _DerainShowcase extends StatelessWidget {
  const _DerainShowcase();

  @override
  Widget build(BuildContext context) {
    return _SampleShowcase(
      from: Image.asset(
        "assets/derain0.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      to: Image.asset(
        "assets/derain1.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

class _SampleShowcase extends StatefulWidget {
  const _SampleShowcase({required this.from, required this.to});

  @override
  State<_SampleShowcase> createState() => _SampleShowcaseState();

  final Widget from;
  final Widget to;
}

class _SampleShowcaseState extends State<_SampleShowcase>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250)).then((_) {
      if (mounted) {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.from,
        CircularRevealAnimation(
          animation: CurvedAnimation(
            parent: _animController,
            curve: Curves.easeIn,
          ),
          centerAlignment: Alignment.bottomCenter,
          child: widget.to,
        ),
      ],
    );
  }

  late final _animController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
}
