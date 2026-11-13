import 'package:flutter/material.dart';
import 'dart:ui';
import '../consts/colors.dart';

enum ToastType { success, error, warning, info }

class ToastNotification {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    // Remove existing toast if any
    _removeCurrentOverlay();

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        title: title,
        onDismiss: _removeCurrentOverlay,
      ),
    );

    _isShowing = true;
    overlay.insert(_currentOverlay!);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      _removeCurrentOverlay();
    });
  }

  static void _removeCurrentOverlay() {
    if (_currentOverlay != null && _isShowing) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }

  // Convenience methods
  static void success(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.success, title: title ?? 'Succès');
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.error, title: title ?? 'Erreur');
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.warning, title: title ?? 'Attention');
  }

  static void info(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.info, title: title);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final String? title;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.title,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case ToastType.success:
        return blueColor; // Couleur du projet
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return const Color(0xFFFF9500);
      case ToastType.info:
        return blueColor;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: topPadding + 10 + _slideAnimation.value,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onDismiss,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            widget.onDismiss();
          }
        },
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _backgroundColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null)
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          if (widget.title != null) const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: widget.title != null ? 0.9 : 1.0),
                              fontSize: widget.title != null ? 14 : 15,
                              fontWeight: widget.title != null ? FontWeight.w400 : FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
