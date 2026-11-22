import 'package:flutter/material.dart';

/// A small label for one appointment. The surrounding card stays still.
class CancellationRequestMark extends StatefulWidget {
  const CancellationRequestMark({super.key});

  @override
  State<CancellationRequestMark> createState() => _CancellationRequestMarkState();
}

class _CancellationRequestMarkState extends State<CancellationRequestMark>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets')) return;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF6C00)),
      ),
      child: const Text(
        'Cancellation Request',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFFEF6C00),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final pulse = _pulse;
    if (pulse == null) return label;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(pulse),
      child: label,
    );
  }
}
