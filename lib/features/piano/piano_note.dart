
import 'dart:math' as math;

/// Represents one musical note in PianoX.
class PianoNote {
  final int midiNumber;

  const PianoNote(this.midiNumber)
      : assert(midiNumber >= 0 && midiNumber <= 127);

  /// The 12 notes in one musical octave.
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Gets the note name, such as C, F# or A.
  String get name => noteNames[midiNumber % 12];

  /// Gets the octave number.
  int get octave => (midiNumber ~/ 12) - 1;

  /// Gets the complete note name, such as C4 or A#5.
  String get fullName => '$name$octave';

  /// Determines whether this is a sharp (black) key.
  bool get isSharp => name.contains('#');

  /// Calculates the note's frequency in Hertz.
  double get frequencyHz {
   return (440 * math.pow(2, (midiNumber - 69) / 12)).toDouble();
  }
}
