import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'piano_keyboard_range.dart';
import 'piano_velocity.dart';

import 'dart:ui' show PointerDeviceKind;

class PianoKeyboard extends StatefulWidget {
  final void Function(int pointerId, int midiNote, int velocity)? onNoteOn;
  final int defaultVelocity;
  final void Function(int pointerId, int midiNote)? onNoteOff;
  final VoidCallback? onSustainDown;
  final VoidCallback? onSustainUp;

  const PianoKeyboard({
    super.key,
    this.onNoteOn,
    this.onNoteOff,
    this.onSustainDown,
    this.onSustainUp,
    this.defaultVelocity = 80,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  static const double _keyboardHeight = 220.0;

  final FocusNode _focusNode = FocusNode(debugLabel: 'PianoX keyboard input');

  // Tracks the note currently associated with each mouse/touch pointer.
  final Map<int, int?> _pointerNotes = {};

  // Tracks computer keys independently.
  final Map<LogicalKeyboardKey, int> _keyboardPointerIds = {};

  // Negative IDs distinguish computer keys from mouse/touch pointers.
  int _nextKeyboardPointerId = -1;
  bool _isSustainKeyDown = false;

  // C4-B4 remains the default range (index 4).
  int _selectedRangeIndex = 4;

  // Chromatic physical-key layout. K supplies the extra C8 key
  // in the highest range, which contains thirteen notes.
  static const List<LogicalKeyboardKey> _computerKeyLayout = [
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyE,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyF,
    LogicalKeyboardKey.keyT,
    LogicalKeyboardKey.keyG,
    LogicalKeyboardKey.keyY,
    LogicalKeyboardKey.keyH,
    LogicalKeyboardKey.keyU,
    LogicalKeyboardKey.keyJ,
    LogicalKeyboardKey.keyK,
  ];

  PianoKeyboardRange get _selectedRange =>
      PianoKeyboardRange.standardPiano[_selectedRangeIndex];

  Map<LogicalKeyboardKey, int> get _computerKeyNotes {
    final mapping = <LogicalKeyboardKey, int>{};
    final notes = _selectedRange.notes;

    for (
      var index = 0;
      index < notes.length && index < _computerKeyLayout.length;
      index++
    ) {
      mapping[_computerKeyLayout[index]] = notes[index];
    }

    return mapping;
  }

  Set<int> get _pressedNotes {
    return {
      ..._pointerNotes.values.whereType<int>(),
      ..._keyboardPointerIds.keys.map((key) => _computerKeyNotes[key]!),
    };
  }

  bool get _hasActiveNotes =>
      _pointerNotes.values.any((note) => note != null) ||
      _keyboardPointerIds.isNotEmpty;

  void _changeRange(int offset) {
    // Never change the mapping while a note is being held.
    if (_hasActiveNotes) return;

    final nextIndex = _selectedRangeIndex + offset;
    if (nextIndex < 0 || nextIndex >= PianoKeyboardRange.standardPiano.length) {
      return;
    }

    setState(() {
      _selectedRangeIndex = nextIndex;
    });

    // Keep computer-key playing ready after using the range controls.
    _focusNode.requestFocus();
  }

  // Identify the musical note at a pointer position.
  int? _getNoteAtPosition(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dx >= size.width ||
        position.dy < 0 ||
        position.dy >= size.height ||
        size.width <= 0 ||
        size.height <= 0) {
      return null;
    }

    final whiteNotes = _selectedRange.whiteNotes;
    final blackNotes = _selectedRange.blackNotes;
    final blackKeyPositions = _selectedRange.blackKeyPositions;

    final whiteKeyWidth = size.width / whiteNotes.length;
    final blackKeyWidth = whiteKeyWidth * 0.58;
    final blackKeyHeight = size.height * 0.62;

    // Check black keys first because they overlap white keys.
    for (var index = 0; index < blackNotes.length; index++) {
      final left =
          (blackKeyPositions[index] + 1) * whiteKeyWidth - blackKeyWidth / 2;

      final blackKeyRect = Rect.fromLTWH(
        left,
        0,
        blackKeyWidth,
        blackKeyHeight,
      );

      if (blackKeyRect.contains(position)) {
        return blackNotes[index];
      }
    }

    final whiteKeyIndex = (position.dx / whiteKeyWidth).floor();
    return whiteNotes[whiteKeyIndex];
  }

  @override
  void initState() {
    super.initState();

    // Listen for physical keyboard events at application level.
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    // Spacebar operates the sustain pedal independently of piano notes.
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        if (!_isSustainKeyDown) {
          _isSustainKeyDown = true;
          widget.onSustainDown?.call();
        }
      } else if (event is KeyUpEvent) {
        if (_isSustainKeyDown) {
          _isSustainKeyDown = false;
          widget.onSustainUp?.call();
        }
      }

      return true;
    }

    final midiNote = _computerKeyNotes[event.logicalKey];
    if (midiNote == null) return false;

    if (event is KeyDownEvent) {
      if (!_keyboardPointerIds.containsKey(event.logicalKey)) {
        final pointerId = _nextKeyboardPointerId--;
        _keyboardPointerIds[event.logicalKey] = pointerId;

        widget.onNoteOn?.call(
          pointerId,
          midiNote,
          widget.defaultVelocity.clamp(1, 127).toInt(),
        );

        if (mounted) setState(() {});
      }

      return true;
    }

    if (event is KeyUpEvent) {
      final pointerId = _keyboardPointerIds.remove(event.logicalKey);

      if (pointerId != null) {
        widget.onNoteOff?.call(pointerId, midiNote);

        if (mounted) setState(() {});
      }

      return true;
    }

    // Consume repeated events without retriggering notes.
    return true;
  }

  // Release every computer key if PianoX loses keyboard focus.
  void _releaseAllComputerKeys({bool rebuild = true}) {
    final activeKeys = _keyboardPointerIds.entries.toList();
    _keyboardPointerIds.clear();

    for (final entry in activeKeys) {
      final midiNote = _computerKeyNotes[entry.key];

      if (midiNote != null) {
        widget.onNoteOff?.call(entry.value, midiNote);
      }
    }

    // Never leave sustain active when PianoX loses keyboard focus.
    if (_isSustainKeyDown) {
      _isSustainKeyDown = false;
      widget.onSustainUp?.call();
    }

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  // Calculate velocity from available pointer pressure.
  int _velocityFromEvent(PointerEvent event) {
    final supportsPressure =
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    if (!supportsPressure) {
      return widget.defaultVelocity.clamp(1, 127).toInt();
    }

    return PianoVelocity.fromPressure(
      pressure: event.pressure,
      pressureMin: event.pressureMin,
      pressureMax: event.pressureMax,
      fallbackVelocity: widget.defaultVelocity,
    );
  }

  // Update the note associated with a mouse/touch pointer.
  void _updatePointer(int pointer, Offset position, Size size, int velocity) {
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
      widget.onNoteOn?.call(pointer, note, velocity);
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
    final range = _selectedRange;
    final lastRangeIndex = PianoKeyboardRange.standardPiano.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous piano range',
              onPressed: _selectedRangeIndex == 0 || _hasActiveNotes
                  ? null
                  : () => _changeRange(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    range.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Range ${_selectedRangeIndex + 1} of '
                    '${PianoKeyboardRange.standardPiano.length} · '
                    '${range.noteCount} notes',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Next piano range',
              onPressed:
                  _selectedRangeIndex == lastRangeIndex || _hasActiveNotes
                  ? null
                  : () => _changeRange(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _keyboardHeight,
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
                final size = Size(constraints.maxWidth, _keyboardHeight);

                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    // Touching the piano returns computer-key focus to it.
                    _focusNode.requestFocus();
                    _updatePointer(
                      event.pointer,
                      event.localPosition,
                      size,
                      _velocityFromEvent(event),
                    );
                  },
                  onPointerMove: (event) {
                    if (_pointerNotes.containsKey(event.pointer)) {
                      _updatePointer(
                        event.pointer,
                        event.localPosition,
                        size,
                        _velocityFromEvent(event),
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
                      range: range,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class PianoKeyboardPainter extends CustomPainter {
  final Set<int> pressedNotes;
  final PianoKeyboardRange range;
  final List<int> _whiteNotes;
  final List<int> _blackNotes;
  final List<int> _blackKeyPositions;

  PianoKeyboardPainter({required this.pressedNotes, required this.range})
    : _whiteNotes = range.whiteNotes,
      _blackNotes = range.blackNotes,
      _blackKeyPositions = range.blackKeyPositions;

  @override
  void paint(Canvas canvas, Size size) {
    if (_whiteNotes.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final whiteKeyWidth = size.width / _whiteNotes.length;

    final whitePaint = Paint()..color = const Color(0xFFF5F2E9);
    final pressedWhitePaint = Paint()..color = const Color(0xFFD4AF37);
    final blackPaint = Paint()..color = const Color(0xFF171717);
    final pressedBlackPaint = Paint()..color = const Color(0xFFB38B22);
    final borderPaint = Paint()
      ..color = const Color(0xFFB8B3A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw white keys first.
    for (var index = 0; index < _whiteNotes.length; index++) {
      final rect = Rect.fromLTWH(
        index * whiteKeyWidth,
        0,
        whiteKeyWidth,
        size.height,
      );

      final isPressed = pressedNotes.contains(_whiteNotes[index]);
      canvas.drawRect(rect, isPressed ? pressedWhitePaint : whitePaint);
      canvas.drawRect(rect, borderPaint);
    }

    // Draw black keys over the white keys.
    final blackKeyWidth = whiteKeyWidth * 0.58;
    final blackKeyHeight = size.height * 0.62;

    for (var index = 0; index < _blackNotes.length; index++) {
      final left =
          (_blackKeyPositions[index] + 1) * whiteKeyWidth - blackKeyWidth / 2;
      final rect = Rect.fromLTWH(left, 0, blackKeyWidth, blackKeyHeight);

      final isPressed = pressedNotes.contains(_blackNotes[index]);
      final roundedRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      );

      canvas.drawRRect(roundedRect, isPressed ? pressedBlackPaint : blackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PianoKeyboardPainter oldDelegate) {
    return range.firstMidiNote != oldDelegate.range.firstMidiNote ||
        range.lastMidiNote != oldDelegate.range.lastMidiNote ||
        pressedNotes.length != oldDelegate.pressedNotes.length ||
        !pressedNotes.containsAll(oldDelegate.pressedNotes);
  }
}
