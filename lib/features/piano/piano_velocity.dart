enum PianoVelocityPreset {
  soft('Soft', 45),
  normal('Normal', 80),
  strong('Strong', 115);

  const PianoVelocityPreset(this.label, this.velocity);

  final String label;
  final int velocity;
}

/// Converts available pointer pressure into valid MIDI note velocity.
class PianoVelocity {
  static const int minimum = 1;
  static const int maximum = 127;

  /// Uses measured pressure where supported, otherwise uses the selected
  /// fallback velocity.
  static int fromPressure({
    required double pressure,
    required double pressureMin,
    required double pressureMax,
    required int fallbackVelocity,
  }) {
    final fallback = fallbackVelocity.clamp(minimum, maximum).toInt();

    // Equal or invalid limits mean pressure is not reliably available.
    if (!pressure.isFinite ||
        !pressureMin.isFinite ||
        !pressureMax.isFinite ||
        pressureMax <= pressureMin) {
      return fallback;
    }

    final normalized = ((pressure - pressureMin) / (pressureMax - pressureMin))
        .clamp(0.0, 1.0);

    final velocity = minimum + normalized * (maximum - minimum);

    return velocity.round().clamp(minimum, maximum).toInt();
  }
}
