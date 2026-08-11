import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../../core/theme/app_theme.dart";

/// Brand entry point — warms up the first frame with a short animated mark
/// before routing into the storefront. Guest browsing is supported app-wide
/// (see PRD §4.1), so this always lands on Home rather than gating on login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
  late final Animation<double> _scale = Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go("/");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SEVENTH", style: displayFont(fontSize: 40, color: AppColors.paper, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text("VOLUME 07 — CLOUD SERIES", style: eyebrowFont(color: AppColors.paper.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
