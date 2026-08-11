import "package:flutter/material.dart";
import "../theme/app_theme.dart";

/// Infinite scrolling announcement strip — mirrors the reference site's
/// dark ticker band ("NEW DROP — FREE SHIPPING — ...").
class MarqueeTicker extends StatefulWidget {
  final String text;
  const MarqueeTicker({super.key, required this.text});

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = "  ✦  " + widget.text;
    return Container(
      color: AppColors.ink,
      height: 38,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-_controller.value * 900, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (i) => Text(
                        line,
                        style: eyebrowFont(color: AppColors.paper),
                      )),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
