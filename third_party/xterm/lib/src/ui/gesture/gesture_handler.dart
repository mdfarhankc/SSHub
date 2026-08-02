import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/src/core/buffer/cell_offset.dart';
import 'package:xterm/src/core/mouse/button.dart';
import 'package:xterm/src/core/mouse/button_state.dart';
import 'package:xterm/src/terminal_view.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/gesture/gesture_detector.dart';
import 'package:xterm/src/ui/pointer_input.dart';
import 'package:xterm/src/ui/render.dart';

class TerminalGestureHandler extends StatefulWidget {
  const TerminalGestureHandler({
    super.key,
    required this.terminalView,
    required this.terminalController,
    this.child,
    this.onTapUp,
    this.onSingleTapUp,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.readOnly = false,
  });

  final TerminalViewState terminalView;

  final TerminalController terminalController;

  final Widget? child;

  final GestureTapUpCallback? onTapUp;

  final GestureTapUpCallback? onSingleTapUp;

  final GestureTapDownCallback? onTapDown;

  final GestureTapDownCallback? onSecondaryTapDown;

  final GestureTapUpCallback? onSecondaryTapUp;

  final GestureTapDownCallback? onTertiaryTapDown;

  final GestureTapUpCallback? onTertiaryTapUp;

  final bool readOnly;

  @override
  State<TerminalGestureHandler> createState() => _TerminalGestureHandlerState();
}

class _TerminalGestureHandlerState extends State<TerminalGestureHandler> {
  TerminalViewState get terminalView => widget.terminalView;

  RenderTerminal get renderTerminal => terminalView.renderTerminal;

  LongPressStartDetails? _lastLongPressStartDetails;

  // Drag-select state: the anchor cell is captured once so it stays put while
  // the view auto-scrolls, and the last pointer position lets each scroll tick
  // extend the selection into the newly revealed lines.
  EdgeDraggingAutoScroller? _autoScroller;
  CellOffset? _dragStartCell;
  Offset? _lastDragLocal;

  @override
  Widget build(BuildContext context) {
    return TerminalGestureDetector(
      child: widget.child,
      onTapUp: widget.onTapUp,
      onSingleTapUp: onSingleTapUp,
      onTapDown: onTapDown,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp,
      onTertiaryTapDown: onSecondaryTapDown,
      onTertiaryTapUp: onSecondaryTapUp,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      // onLongPressUp: onLongPressUp,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onDoubleTapDown: onDoubleTapDown,
    );
  }

  bool get _shouldSendTapEvent =>
      !widget.readOnly &&
      widget.terminalController.shouldSendPointerInput(PointerInput.tap);

  void _tapDown(
    GestureTapDownCallback? callback,
    TapDownDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap down event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.down,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void _tapUp(
    GestureTapUpCallback? callback,
    TapUpDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap up event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.up,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void onTapDown(TapDownDetails details) {
    // Shift+click extends the existing selection from its anchor to the click,
    // instead of clearing it.
    if (_canExtendSelection) {
      _lastDragLocal = details.localPosition;
      _updateSelection();
      return;
    }
    // onTapDown is special, as it will always call the supplied callback.
    // The TerminalView depends on it to bring the terminal into focus.
    _tapDown(
      widget.onTapDown,
      details,
      TerminalMouseButton.left,
      forceCallback: true,
    );
  }

  // True when Shift is held over a live selection whose anchor we still know,
  // so a click or drag should grow it rather than start over.
  bool get _canExtendSelection =>
      HardwareKeyboard.instance.isShiftPressed &&
      _dragStartCell != null &&
      widget.terminalController.selection != null;

  void onSingleTapUp(TapUpDetails details) {
    _tapUp(widget.onSingleTapUp, details, TerminalMouseButton.left);
  }

  void onSecondaryTapDown(TapDownDetails details) {
    _tapDown(widget.onSecondaryTapDown, details, TerminalMouseButton.right);
  }

  void onSecondaryTapUp(TapUpDetails details) {
    _tapUp(widget.onSecondaryTapUp, details, TerminalMouseButton.right);
  }

  void onTertiaryTapDown(TapDownDetails details) {
    _tapDown(widget.onTertiaryTapDown, details, TerminalMouseButton.middle);
  }

  void onTertiaryTapUp(TapUpDetails details) {
    _tapUp(widget.onTertiaryTapUp, details, TerminalMouseButton.right);
  }

  void onDoubleTapDown(TapDownDetails details) {
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressStart(LongPressStartDetails details) {
    _lastLongPressStartDetails = details;
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    renderTerminal.selectWord(
      _lastLongPressStartDetails!.localPosition,
      details.localPosition,
    );
  }

  // void onLongPressUp() {}

  void onDragStart(DragStartDetails details) {
    // Shift keeps the current anchor so the drag extends the selection; without
    // it the anchor is the absolute cell where the drag began. Either way the
    // anchor must not move when the view scrolls, so it is captured once.
    final extend = _canExtendSelection;
    if (!extend) {
      _dragStartCell = renderTerminal.getCellOffset(details.localPosition);
    }
    _lastDragLocal = details.localPosition;

    final scrollable = terminalView.scrollableState;
    _autoScroller = scrollable == null
        ? null
        : EdgeDraggingAutoScroller(
            scrollable,
            velocityScalar: 30,
            onScrollViewScrolled: _updateSelection,
          );

    extend
        ? _updateSelection()
        : renderTerminal.selectCharacters(details.localPosition);
  }

  void onDragUpdate(DragUpdateDetails details) {
    _lastDragLocal = details.localPosition;
    _updateSelection();
    // A point rect at the pointer; the scroller starts once it nears an edge.
    _autoScroller?.startAutoScrollIfNecessary(
      Rect.fromCenter(center: details.globalPosition, width: 1, height: 1),
    );
  }

  void onDragEnd(DragEndDetails details) {
    _autoScroller?.stopAutoScroll();
    // Drop the scroller so it stops holding the old ScrollableState.
    _autoScroller = null;
  }

  @override
  void dispose() {
    // A drag can still be auto-scrolling when the tab is torn down.
    _autoScroller?.stopAutoScroll();
    _autoScroller = null;
    super.dispose();
  }

  // Re-extends the selection from the fixed anchor to the last pointer row,
  // called on every drag move and on every auto-scroll tick.
  void _updateSelection() {
    final base = _dragStartCell;
    final local = _lastDragLocal;
    if (base == null || local == null) return;
    renderTerminal.selectCharactersTo(base, local);
  }
}
