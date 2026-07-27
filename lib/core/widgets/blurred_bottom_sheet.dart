import 'dart:ui';

import 'package:flutter/material.dart';

// A modal bottom sheet with an iOS-style blurred, dimmed backdrop. The blur is
// wrapped around the sheet's own barrier, so it sits behind the sheet and fades
// in and out with it, driven by the route's animation.
Future<T?> showBlurredBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
}) {
  final navigator = Navigator.of(context);
  return navigator.push(
    _BlurredBottomSheetRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      shape: shape,
      constraints: constraints,
    ),
  );
}

class _BlurredBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _BlurredBottomSheetRoute({
    required super.builder,
    super.capturedThemes,
    super.barrierLabel,
    super.modalBarrierColor,
    super.backgroundColor,
    super.shape,
    super.constraints,
    super.isDismissible,
    super.enableDrag,
    super.showDragHandle,
    required super.isScrollControlled,
    super.useSafeArea,
  });

  // The barrier already dims and fades with the route; this adds the blur on
  // top of it so both track the sheet's motion.
  @override
  Widget buildModalBarrier() {
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) {
        final t = animation!.value.clamp(0.0, 1.0);
        if (t == 0) return child!;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
          child: child,
        );
      },
      child: super.buildModalBarrier(),
    );
  }
}
