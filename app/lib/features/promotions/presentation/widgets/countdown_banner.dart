import "dart:async";
import "package:flutter/material.dart";

class CountdownBanner extends StatefulWidget {
  final Duration remaining;
  const CountdownBanner({super.key, required this.remaining});

  @override
  State<CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<CountdownBanner> {
  late Duration _remaining = widget.remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, "0");

  @override
  Widget build(BuildContext context) {
    final h = _two(_remaining.inHours);
    final m = _two(_remaining.inMinutes.remainder(60));
    final s = _two(_remaining.inSeconds.remainder(60));
    return Row(
      children: [h, m, s].expand((v) => [_box(v), const SizedBox(width: 4)]).toList()..removeLast(),
    );
  }

  Widget _box(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
        child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
}
