import 'package:flutter/material.dart';
import './app_error_message.dart';
import './AppSuccessMessage.dart';

void showBottomMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _BottomMessageOverlay(
      message: message,
      isError: isError,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(duration, () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class _BottomMessageOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _BottomMessageOverlay({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_BottomMessageOverlay> createState() => _BottomMessageOverlayState();
}

class _BottomMessageOverlayState extends State<_BottomMessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slide = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: widget.isError
              ? AppErrorMessage(widget.message)
              : AppSuccessMessage(widget.message),
        ),
      ),
    );
  }
}
