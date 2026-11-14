
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioEngine {
  final SoLoud _soloud = SoLoud.instance;

  // Reusable sound sources, indexed by MIDI note.
  final Map<int, AudioSource> _noteSources = {};

  // Individual playing sounds, indexed by pointer ID.
  final Map<int, SoundHandle> _activeNotes = {};

  // Keeps actions from the same pointer in the correct order.
  final Map<int, Future<void>> _pointerActions = {};

  // Temporary A4 test source.
  AudioSource? _toneSource;

  Future<void> initialize() async {
    if (_soloud.isInitialized) return;

    await _soloud.init();
  }

  // Load or retrieve a sound source for a musical note.
  Future<AudioSource> _getNoteSource(
    int midiNote,
    double frequencyHz,
  ) async {
    final existingSource = _noteSources[midiNote];

    if (existingSource != null) {
      return existingSource;
    }

    final source = await _soloud.loadWaveform(
      WaveForm.sin,
      false,
      1.0,
      0.0,
    );

    _soloud.setWaveformFreq(source, frequencyHz);

    _noteSources[midiNote] = source;

    return source;
  }

  // Execute actions for each pointer in the correct order.
  Future<void> _queuePointerAction(
    int pointerId,
    Future<void> Function() action,
  ) async {
    final previous = _pointerActions[pointerId] ??
        Future<void>.value();

    final next = previous.then((_) => action());

    _pointerActions[pointerId] = next;

    try {
      await next;
    } finally {
      if (identical(_pointerActions[pointerId], next)) {
        _pointerActions.remove(pointerId);
      }
    }
  }

  // Start a musical note.
  Future<void> noteOn(
    int pointerId,
    int midiNote,
    double frequencyHz,
  ) {
    return _queuePointerAction(pointerId, () async {
      await initialize();

      final oldHandle = _activeNotes.remove(pointerId);

      if (oldHandle != null) {
        await _soloud.stop(oldHandle);
      }

      final source = await _getNoteSource(
        midiNote,
        frequencyHz,
      );

      final handle = _soloud.play(
        source,
        looping: true,
        volume: 0.2,
      );

      _activeNotes[pointerId] = handle;
    });
  }

  // Stop the note belonging to a pointer.
  Future<void> noteOff(int pointerId) {
    return _queuePointerAction(pointerId, () async {
      final handle = _activeNotes.remove(pointerId);

      if (handle != null) {
        await _soloud.stop(handle);
      }
    });
  }

  // Temporary A4 test.
  Future<SoundHandle> playTestNote(double frequencyHz) async {
    await initialize();

    _toneSource ??= await _soloud.loadWaveform(
      WaveForm.sin,
      false,
      1.0,
      0.0,
    );

    _soloud.setWaveformFreq(_toneSource!, frequencyHz);

    return _soloud.play(
      _toneSource!,
      looping: true,
      volume: 0.2,
    );
  }

  Future<void> stopTestNote(SoundHandle handle) async {
    await _soloud.stop(handle);
  }
}
