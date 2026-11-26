import 'package:flutter_test/flutter_test.dart';
import 'package:pianox/features/piano/piano_velocity.dart';

void main() {
  group('PianoVelocity tests', () {
    test('minimum pressure produces minimum velocity', () {
      final velocity = PianoVelocity.fromPressure(
        pressure: 0.0,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      expect(velocity, 1);
    });

    test('maximum pressure produces maximum velocity', () {
      final velocity = PianoVelocity.fromPressure(
        pressure: 1.0,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      expect(velocity, 127);
    });

    test('midpoint pressure produces midpoint velocity', () {
      final velocity = PianoVelocity.fromPressure(
        pressure: 0.5,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      expect(velocity, 64);
    });

    test('pressure outside supported limits is clamped', () {
      final belowMinimum = PianoVelocity.fromPressure(
        pressure: -0.5,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      final aboveMaximum = PianoVelocity.fromPressure(
        pressure: 1.5,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      expect(belowMinimum, 1);
      expect(aboveMaximum, 127);
    });

    test('unsupported pressure uses the selected fallback', () {
      final velocity = PianoVelocity.fromPressure(
        pressure: 1.0,
        pressureMin: 1.0,
        pressureMax: 1.0,
        fallbackVelocity: 80,
      );

      expect(velocity, 80);
    });

    test('invalid pressure values use the selected fallback', () {
      final velocity = PianoVelocity.fromPressure(
        pressure: double.nan,
        pressureMin: 0.0,
        pressureMax: 1.0,
        fallbackVelocity: 45,
      );

      expect(velocity, 45);
    });

    test('fallback velocity is constrained to MIDI limits', () {
      final low = PianoVelocity.fromPressure(
        pressure: 1.0,
        pressureMin: 1.0,
        pressureMax: 1.0,
        fallbackVelocity: 0,
      );

      final high = PianoVelocity.fromPressure(
        pressure: 1.0,
        pressureMin: 1.0,
        pressureMax: 1.0,
        fallbackVelocity: 200,
      );

      expect(low, 1);
      expect(high, 127);
    });

    test('velocity presets have the intended values', () {
      expect(PianoVelocityPreset.soft.velocity, 45);
      expect(PianoVelocityPreset.normal.velocity, 80);
      expect(PianoVelocityPreset.strong.velocity, 115);
    });
  });
}
