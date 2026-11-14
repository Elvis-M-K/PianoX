
import 'package:flutter/material.dart';

class PianoKeyboard extends StatefulWidget {
  final void Function(int pointerId, int midiNote)? onNoteOn;
  final void Function(int pointerId, int midiNote)? onNoteOff;

  const PianoKeyboard({
    super.key,
    this.onNoteOn,
    this.onNoteOff,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  // Tracks which musical note each pointer is pressing.
  final Map<int, int?> _pointerNotes = {};

  // MIDI numbers for the seven white keys.
  static const List<int> _whiteNotes = [
    60, 62, 64, 65, 67, 69, 71,
  ];

  // MIDI numbers for the five black keys.
  static const List<int> _blackNotes = [
    61, 63, 66, 68, 70,
  ];

  static const List<int> _blackKeyPositions = [
    0, 1, 3, 4, 5,
  ];

  Set<int> get _pressedNotes => _pointerNotes.values
      .whereType<int>()
      .toSet();

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
      final left = (_blackKeyPositions[i] + 1) *
              whiteKeyWidth -
          blackKeyWidth / 2;

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

    // If no black key was hit, identify the white key.
    final whiteKeyIndex =
        (position.dx / whiteKeyWidth).floor();

    return _whiteNotes[whiteKeyIndex];
  }

  // Update the note associated with a pointer.
  void _updatePointer(
  int pointer,
  Offset position,
  Size size,
) {
  final note = _getNoteAtPosition(position, size);

  final previousNote = _pointerNotes[pointer];

  if (previousNote == note) return;

  // Release the previous note if there was one.
  if (previousNote != null) {
    widget.onNoteOff?.call(pointer, previousNote);
  }

  setState(() {
    _pointerNotes[pointer] = note;
  });

  // Start the newly selected note.
  if (note != null) {
    widget.onNoteOn?.call(pointer, note);
  }
}
void _releasePointer(int pointer) {
  final note = _pointerNotes[pointer];

  if (note != null) {
    widget.onNoteOff?.call(pointer, note);
  }

  setState(() {
    _pointerNotes.remove(pointer);
  });
}

  @override
  Widget build(BuildContext context) {
    const keyboardHeight = 220.0;

    return SizedBox(
      height: keyboardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth,
            keyboardHeight,
          );

          return Listener(
            behavior: HitTestBehavior.opaque,

            onPointerDown: (event) {
              _updatePointer(
                event.pointer,
                event.localPosition,
                size,
              );
            },

            onPointerMove: (event) {
              if (_pointerNotes.containsKey(event.pointer)) {
                _updatePointer(
                  event.pointer,
                  event.localPosition,
                  size,
                );
              }
            },

           onPointerUp: (event) {
  _releasePointer(event.pointer);
},

onPointerCancel: (event) {
  _releasePointer(event.pointer);
},

            child: CustomPaint(
              painter: PianoKeyboardPainter(
                pressedNotes: _pressedNotes,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class PianoKeyboardPainter extends CustomPainter {
  final Set<int> pressedNotes;

  PianoKeyboardPainter({
    required this.pressedNotes,
  });

  static const List<int> whiteNotes = [
    60, 62, 64, 65, 67, 69, 71,
  ];

  static const List<int> blackNotes = [
    61, 63, 66, 68, 70,
  ];

  static const List<int> blackKeyPositions = [
    0, 1, 3, 4, 5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final whiteKeyWidth = size.width / 7;

    final whitePaint = Paint()
      ..color = const Color(0xFFF5F2E9);

    final pressedWhitePaint = Paint()
      ..color = const Color(0xFFD4AF37);

    final blackPaint = Paint()
      ..color = const Color(0xFF171717);

    final pressedBlackPaint = Paint()
      ..color = const Color(0xFFB38B22);

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

      canvas.drawRect(
        rect,
        isPressed ? pressedWhitePaint : whitePaint,
      );

      canvas.drawRect(rect, borderPaint);
    }

    // Draw black keys on top of the white keys.
    final blackKeyWidth = whiteKeyWidth * 0.58;
    final blackKeyHeight = size.height * 0.62;

    for (int i = 0; i < blackNotes.length; i++) {
      final left = (blackKeyPositions[i] + 1) *
              whiteKeyWidth -
          blackKeyWidth / 2;

      final rect = Rect.fromLTWH(
        left,
        0,
        blackKeyWidth,
        blackKeyHeight,
      );

      final isPressed = pressedNotes.contains(blackNotes[i]);

      final roundedRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      );

      canvas.drawRRect(
        roundedRect,
        isPressed ? pressedBlackPaint : blackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant PianoKeyboardPainter oldDelegate,
  ) {
    return pressedNotes.length != oldDelegate.pressedNotes.length ||
        !pressedNotes.containsAll(oldDelegate.pressedNotes);
  }
}
