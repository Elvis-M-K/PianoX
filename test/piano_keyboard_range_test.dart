import 'package:flutter_test/flutter_test.dart';
import 'package:pianox/features/piano/piano_keyboard_range.dart';

void main() {
  group('PianoKeyboardRange tests', () {
    test('all ranges cover the complete 88-key piano', () {
      final allNotes = [
        for (final range in PianoKeyboardRange.standardPiano) ...range.notes,
      ];

      expect(allNotes, List<int>.generate(88, (index) => index + 21));
    });

    test('there are eight selectable ranges', () {
      expect(PianoKeyboardRange.standardPiano.length, 8);
    });

    test('default range is C4 through B4', () {
      final range = PianoKeyboardRange.standardPiano[4];

      expect(range.firstMidiNote, 60);
      expect(range.lastMidiNote, 71);
      expect(range.label, 'C4 – B4');
      expect(range.noteCount, 12);
    });

    test('lowest range contains A0, A#0 and B0', () {
      final range = PianoKeyboardRange.standardPiano.first;

      expect(range.label, 'A0 – B0');
      expect(range.whiteNotes, [21, 23]);
      expect(range.blackNotes, [22]);
      expect(range.blackKeyPositions, [0]);
    });

    test('highest range includes the final C8 key', () {
      final range = PianoKeyboardRange.standardPiano.last;

      expect(range.label, 'C7 – C8');
      expect(range.firstMidiNote, 96);
      expect(range.lastMidiNote, 108);
      expect(range.noteCount, 13);
      expect(range.whiteNotes.length, 8);
      expect(range.blackNotes.length, 5);
    });

    test('C4 range has correct white and black keys', () {
      final range = PianoKeyboardRange.standardPiano[4];

      expect(range.whiteNotes, [60, 62, 64, 65, 67, 69, 71]);
      expect(range.blackNotes, [61, 63, 66, 68, 70]);
      expect(range.blackKeyPositions, [0, 1, 3, 4, 5]);
    });

    test('note offsets outside the range return null', () {
      final range = PianoKeyboardRange.standardPiano[4];

      expect(range.noteAtOffset(0), 60);
      expect(range.noteAtOffset(11), 71);
      expect(range.noteAtOffset(-1), isNull);
      expect(range.noteAtOffset(12), isNull);
    });

    test('C8 is the final note of the standard piano', () {
      final range = PianoKeyboardRange.standardPiano.last;

      expect(range.noteAtOffset(12), 108);
      expect(range.noteAtOffset(13), isNull);
    });
  });
}
