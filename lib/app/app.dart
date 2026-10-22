import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/brand_logo.dart';
import '../presentation/shell/home_shell.dart';
import 'dependencies.dart';
import 'shop_providers.dart';

class ShoeFactoryApp extends StatefulWidget {
  const ShoeFactoryApp(
      {super.key, required this.dependencies, this.showSplash = true});

  final AppDependencies dependencies;
  final bool showSplash;

  @override
  State<ShoeFactoryApp> createState() => _ShoeFactoryAppState();
}

class _ShoeFactoryAppState extends State<ShoeFactoryApp> {
  late bool _splash = widget.showSplash;

  @override
  void initState() {
    super.initState();
    if (!_splash) return;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShopProviders(
      dependencies: widget.dependencies,
      child: MaterialApp(
        title: 'Shoe Factory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _splash ? const SplashView() : const HomeShell(),
      ),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width - 48;
    final logoHeight = (logoWidth / BrandLogo.aspectRatio).clamp(120.0, 200.0);
    final fade = CurvedAnimation(
        parent: _intro, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    final scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    return Scaffold(
      backgroundColor: AppColors.green,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppDecor.headerGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: scale,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final ring = 0.92 + (_pulse.value * 0.08);
                        return Transform.scale(
                          scale: ring,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                  alpha: 0.10 + _pulse.value * 0.06),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: BrandLogo(size: logoHeight),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _intro,
                    curve: const Interval(0.45, 1, curve: Curves.easeOut),
                  ),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
