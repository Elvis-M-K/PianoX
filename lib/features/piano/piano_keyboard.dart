import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PianoKeyboard extends StatefulWidget {
  final void Function(int pointerId, int midiNote)? onNoteOn;
  final void Function(int pointerId, int midiNote)? onNoteOff;

  const PianoKeyboard({super.key, this.onNoteOn, this.onNoteOff});

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'PianoX keyboard input');

  // Tracks the note currently associated with each mouse/touch pointer.
  final Map<int, int?> _pointerNotes = {};

  // Tracks computer keys independently.
  final Map<LogicalKeyboardKey, int> _keyboardPointerIds = {};

  // Negative IDs distinguish computer keys from mouse/touch pointers.
  int _nextKeyboardPointerId = -1;

  // One octave: C4 through B4.
  static const List<int> _whiteNotes = [60, 62, 64, 65, 67, 69, 71];

  static const List<int> _blackNotes = [61, 63, 66, 68, 70];

  static const List<int> _blackKeyPositions = [0, 1, 3, 4, 5];

  // PC keyboard mapping, ascending chromatically from C4 to B4.
  //
  // A = C4       W = C#4
  // S = D4       E = D#4
  // D = E4       F = F4
  // T = F#4      G = G4
  // Y = G#4      H = A4
  // U = A#4      J = B4
  static final Map<LogicalKeyboardKey, int> _computerKeyNotes = {
    LogicalKeyboardKey.keyA: 60,
    LogicalKeyboardKey.keyW: 61,
    LogicalKeyboardKey.keyS: 62,
    LogicalKeyboardKey.keyE: 63,
    LogicalKeyboardKey.keyD: 64,
    LogicalKeyboardKey.keyF: 65,
    LogicalKeyboardKey.keyT: 66,
    LogicalKeyboardKey.keyG: 67,
    LogicalKeyboardKey.keyY: 68,
    LogicalKeyboardKey.keyH: 69,
    LogicalKeyboardKey.keyU: 70,
    LogicalKeyboardKey.keyJ: 71,
  };

  Set<int> get _pressedNotes {
    return {
      ..._pointerNotes.values.whereType<int>(),
      ..._keyboardPointerIds.keys.map((key) => _computerKeyNotes[key]!),
    };
  }

  // Identify the musical note at a pointer position.
  int? _getNoteAtPosition(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dx >= size.width ||
        position.dy < 0 ||
        position.dy >= size.height) {
      return null;
    }

    final whiteKeyWidth = size.width / 7;
    final blackKeyWidth = whiteKeyWidth * 0.58;
    final blackKeyHeight = size.height * 0.62;

    // Check black keys first because they overlap white keys.
    for (int i = 0; i < _blackKeyPositions.length; i++) {
      final left =
          (_blackKeyPositions[i] + 1) * whiteKeyWidth - blackKeyWidth / 2;

      final blackKeyRect = Rect.fromLTWH(
        left,
        0,
        blackKeyWidth,
        blackKeyHeight,
      );

      if (blackKeyRect.contains(position)) {
        return _blackNotes[i];
      }
    }

    // Identify the white key.
    final whiteKeyIndex = (position.dx / whiteKeyWidth).floor();
    return _whiteNotes[whiteKeyIndex];
  }

  @override
  void initState() {
    super.initState();

    // Listen for physical keyboard events at application level.
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    final midiNote = _computerKeyNotes[event.logicalKey];

    // Diagnostic: show physical keyboard events in Terminal 1.
    if (event is KeyDownEvent || event is KeyUpEvent) {}

    if (midiNote == null) return false;

    // Start the note on the first key-down event.
    if (event is KeyDownEvent) {
      if (!_keyboardPointerIds.containsKey(event.logicalKey)) {
        final pointerId = _nextKeyboardPointerId--;
        _keyboardPointerIds[event.logicalKey] = pointerId;

        widget.onNoteOn?.call(pointerId, midiNote);

        if (mounted) setState(() {});
      }

      return true;
    }

    // Release only the corresponding note.
    if (event is KeyUpEvent) {
      final pointerId = _keyboardPointerIds.remove(event.logicalKey);

      if (pointerId != null) {
        widget.onNoteOff?.call(pointerId, midiNote);

        if (mounted) setState(() {});
      }

      return true;
    }

    // Consume repeat events without retriggering notes.
    return true;
  }

  // Release every computer key if PianoX loses keyboard focus.
  void _releaseAllComputerKeys({bool rebuild = true}) {
    if (_keyboardPointerIds.isEmpty) return;

    final activeKeys = _keyboardPointerIds.entries.toList();
    _keyboardPointerIds.clear();

    for (final entry in activeKeys) {
      final midiNote = _computerKeyNotes[entry.key];

      if (midiNote != null) {
        widget.onNoteOff?.call(entry.value, midiNote);
      }
    }

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  // Update the note associated with a mouse/touch pointer.
  void _updatePointer(int pointer, Offset position, Size size) {
    final note = _getNoteAtPosition(position, size);
    final alreadyTracked = _pointerNotes.containsKey(pointer);
    final previousNote = _pointerNotes[pointer];

    if (alreadyTracked && previousNote == note) return;

    // Release the previous note when sliding to another key.
    if (previousNote != null) {
      widget.onNoteOff?.call(pointer, previousNote);
    }

    setState(() {
      _pointerNotes[pointer] = note;
    });

    if (note != null) {
      widget.onNoteOn?.call(pointer, note);
    }
  }

  void _releasePointer(int pointer) {
    if (!_pointerNotes.containsKey(pointer)) return;

    final note = _pointerNotes.remove(pointer);

    if (note != null) {
      widget.onNoteOff?.call(pointer, note);
    }

    setState(() {});
  }

  @override
  void dispose() {
    // Stop receiving global keyboard events before cleaning up state.
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);

    // Prevent mouse/touch notes from remaining active after disposal.
    for (final entry in _pointerNotes.entries) {
      final note = entry.value;

      if (note != null) {
        widget.onNoteOff?.call(entry.key, note);
      }
    }

    _pointerNotes.clear();

    // Also release any computer keys still being held.
    _releaseAllComputerKeys(rebuild: false);

    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const keyboardHeight = 220.0;

    return SizedBox(
      height: keyboardHeight,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _releaseAllComputerKeys();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, keyboardHeight);

            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                // Clicking the piano returns keyboard focus to it.
                _focusNode.requestFocus();

                _updatePointer(event.pointer, event.localPosition, size);
              },
              onPointerMove: (event) {
                if (_pointerNotes.containsKey(event.pointer)) {
                  _updatePointer(event.pointer, event.localPosition, size);
                }
              },
              onPointerUp: (event) {
                _releasePointer(event.pointer);
              },
              onPointerCancel: (event) {
                _releasePointer(event.pointer);
              },
              child: CustomPaint(
                painter: PianoKeyboardPainter(pressedNotes: _pressedNotes),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PianoKeyboardPainter extends CustomPainter {
  final Set<int> pressedNotes;

  PianoKeyboardPainter({required this.pressedNotes});

  static const List<int> whiteNotes = [60, 62, 64, 65, 67, 69, 71];

  static const List<int> blackNotes = [61, 63, 66, 68, 70];

  static const List<int> blackKeyPositions = [0, 1, 3, 4, 5];

  @override
  void paint(Canvas canvas, Size size) {
    final whiteKeyWidth = size.width / 7;

    final whitePaint = Paint()..color = const Color(0xFFF5F2E9);

    final pressedWhitePaint = Paint()..color = const Color(0xFFD4AF37);

    final blackPaint = Paint()..color = const Color(0xFF171717);

    final pressedBlackPaint = Paint()..color = const Color(0xFFB38B22);

    final borderPaint = Paint()
      ..color = const Color(0xFFB8B3A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw white keys.
    for (int i = 0; i < whiteNotes.length; i++) {
      final rect = Rect.fromLTWH(
        i * whiteKeyWidth,
        0,
        whiteKeyWidth,
        size.height,
      );

      final isPressed = pressedNotes.contains(whiteNotes[i]);

      canvas.drawRect(rect, isPressed ? pressedWhitePaint : whitePaint);

      canvas.drawRect(rect, borderPaint);
    }

    // Draw black keys.
    final blackKeyWidth = whiteKeyWidth * 0.58;
    final blackKeyHeight = size.height * 0.62;

    for (int i = 0; i < blackNotes.length; i++) {
      final left =
          (blackKeyPositions[i] + 1) * whiteKeyWidth - blackKeyWidth / 2;

      final rect = Rect.fromLTWH(left, 0, blackKeyWidth, blackKeyHeight);

      final isPressed = pressedNotes.contains(blackNotes[i]);

      final roundedRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      );

      canvas.drawRRect(roundedRect, isPressed ? pressedBlackPaint : blackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PianoKeyboardPainter oldDelegate) {
    return pressedNotes.length != oldDelegate.pressedNotes.length ||
        !pressedNotes.containsAll(oldDelegate.pressedNotes);
  }
}
