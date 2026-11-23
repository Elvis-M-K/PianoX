import 'piano_note.dart';

/// Defines a selectable range of notes on the PianoX keyboard.
class PianoKeyboardRange {
  const PianoKeyboardRange({
    required this.firstMidiNote,
    required this.lastMidiNote,
  }) : assert(firstMidiNote >= 0),
       assert(lastMidiNote <= 127),
       assert(firstMidiNote <= lastMidiNote);

  /// All selectable sections of a standard 88-key piano.
  ///
  /// The ranges are contiguous and cover MIDI notes 21 (A0)
  /// through 108 (C8), without gaps or overlaps.
  static const List<PianoKeyboardRange> standardPiano = [
    PianoKeyboardRange(firstMidiNote: 21, lastMidiNote: 23),
    PianoKeyboardRange(firstMidiNote: 24, lastMidiNote: 35),
    PianoKeyboardRange(firstMidiNote: 36, lastMidiNote: 47),
    PianoKeyboardRange(firstMidiNote: 48, lastMidiNote: 59),
    PianoKeyboardRange(firstMidiNote: 60, lastMidiNote: 71),
    PianoKeyboardRange(firstMidiNote: 72, lastMidiNote: 83),
    PianoKeyboardRange(firstMidiNote: 84, lastMidiNote: 95),
    PianoKeyboardRange(firstMidiNote: 96, lastMidiNote: 108),
  ];

  final int firstMidiNote;
  final int lastMidiNote;

  int get noteCount => lastMidiNote - firstMidiNote + 1;

  /// All MIDI notes in this range, in ascending order.
  List<int> get notes => List<int>.generate(
    noteCount,
    (index) => firstMidiNote + index,
    growable: false,
  );

  /// Natural piano keys: C, D, E, F, G, A and B.
  List<int> get whiteNotes =>
      notes.where((note) => !PianoNote(note).isSharp).toList(growable: false);

  /// Sharp piano keys: C#, D#, F#, G# and A#.
  List<int> get blackNotes =>
      notes.where((note) => PianoNote(note).isSharp).toList(growable: false);

  /// Position of each black key relative to the white keys.
  List<int> get blackKeyPositions {
    final positions = <int>[];
    var whiteKeysBefore = 0;

    for (final note in notes) {
      if (PianoNote(note).isSharp) {
        positions.add(whiteKeysBefore - 1);
      } else {
        whiteKeysBefore++;
      }
    }

    return positions;
  }

  /// Human-readable range, such as C4 – B4.
  String get label =>
      '${PianoNote(firstMidiNote).fullName} – '
      '${PianoNote(lastMidiNote).fullName}';

  /// Returns the MIDI note at a zero-based keyboard position.
  ///
  /// Returns null when the requested position is outside this range.
  int? noteAtOffset(int offset) {
    if (offset < 0 || offset >= noteCount) {
      return null;
    }

    return firstMidiNote + offset;
  }
}
