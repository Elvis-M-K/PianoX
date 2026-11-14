
import 'package:flutter_test/flutter_test.dart';
import 'package:pianox/features/piano/piano_note.dart';

void main() {
  group('PianoNote tests', () {
    test('A0 should have the correct note name and frequency', () {
      const note = PianoNote(21);

      expect(note.fullName, 'A0');
      expect(note.frequencyHz, closeTo(27.50, 0.01));
    });

    test('Middle C should be C4', () {
      const note = PianoNote(60);

      expect(note.fullName, 'C4');
      expect(note.frequencyHz, closeTo(261.63, 0.01));
    });

    test('A4 should have a frequency of 440 Hz', () {
      const note = PianoNote(69);

      expect(note.fullName, 'A4');
      expect(note.frequencyHz, closeTo(440.0, 0.01));
    });

    test('C8 should be the highest note on a standard piano', () {
      const note = PianoNote(108);

      expect(note.fullName, 'C8');
      expect(note.frequencyHz, closeTo(4186.01, 0.1));
    });

    test('Sharp notes should be identified correctly', () {
      const note = PianoNote(61);

      expect(note.fullName, 'C#4');
      expect(note.isSharp, true);
    });
  });
}
