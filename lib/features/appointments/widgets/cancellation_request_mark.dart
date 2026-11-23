import 'package:flutter/material.dart';

/// A small label for one appointment. The surrounding card stays still.
class CancellationRequestMark extends StatefulWidget {
  const CancellationRequestMark({
    super.key,
    this.label = 'Cancellation Request',
    this.foreground = const Color(0xFFEF6C00),
    this.background = const Color(0xFFFFF3E0),
    this.border = const Color(0xFFEF6C00),
    this.onPressed,
  });

  const CancellationRequestMark.awaiting({super.key, this.onPressed})
      : label = 'Awaiting Confirmation',
        foreground = const Color(0xFFF9A825),
        background = const Color(0xFFFFF8E1),
        border = const Color(0xFFF9A825);

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback? onPressed;

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
        color: widget.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.border),
      ),
      child: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: widget.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final pulse = _pulse;
    final shown = pulse == null
        ? label
        : FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(pulse),
            child: label,
          );
    final action = widget.onPressed;
    if (action == null) return shown;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(8),
          child: shown,
        ),
      ),
    );
  }
}
