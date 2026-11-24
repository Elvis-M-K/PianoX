import 'package:flutter_test/flutter_test.dart';
import 'package:pianox/core/audio/sustain_pedal.dart';

void main() {
  group('SustainPedal tests', () {
    test('releases a note immediately when the pedal is up', () async {
      final pedal = SustainPedal();
      var releaseCount = 0;

      await pedal.releaseNote(
        cycle: pedal.activeCycle,
        release: () async {
          releaseCount++;
        },
      );

      expect(releaseCount, 1);
      expect(pedal.isDown, false);
    });

    test('defers a note release while the pedal is down', () async {
      final pedal = SustainPedal();
      var released = false;

      pedal.press();
      final cycle = pedal.activeCycle;

      await pedal.releaseNote(
        cycle: cycle,
        release: () async {
          released = true;
        },
      );

      expect(released, false);
      expect(pedal.isDown, true);

      await pedal.release();

      expect(released, true);
      expect(pedal.isDown, false);
    });

    test('releases multiple deferred notes when the pedal lifts', () async {
      final pedal = SustainPedal();
      var releaseCount = 0;

      pedal.press();
      final cycle = pedal.activeCycle;

      for (var index = 0; index < 3; index++) {
        await pedal.releaseNote(
          cycle: cycle,
          release: () async {
            releaseCount++;
          },
        );
      }

      expect(releaseCount, 0);

      await pedal.release();

      expect(releaseCount, 3);
    });

    test('does not release a key that is still being held', () async {
      final pedal = SustainPedal();
      var released = false;

      pedal.press();

      // No key-release event has occurred yet.
      await pedal.release();

      expect(released, false);

      // Releasing the key after the pedal is up releases it normally.
      await pedal.releaseNote(
        cycle: pedal.activeCycle,
        release: () async {
          released = true;
        },
      );

      expect(released, true);
    });

    test('repeated pedal presses do not create new cycles', () {
      final pedal = SustainPedal();

      pedal.press();
      final firstCycle = pedal.activeCycle;

      pedal.press();

      expect(pedal.activeCycle, firstCycle);
    });

    test('an old release cannot enter a newer pedal cycle', () async {
      final pedal = SustainPedal();
      var released = false;

      pedal.press();
      final oldCycle = pedal.activeCycle;

      await pedal.release();

      pedal.press();

      await pedal.releaseNote(
        cycle: oldCycle,
        release: () async {
          released = true;
        },
      );

      expect(released, true);
      expect(pedal.isDown, true);

      await pedal.release();
    });
  });
}
