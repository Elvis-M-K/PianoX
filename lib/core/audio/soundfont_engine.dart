import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:soundfont_kit/soundfont_kit.dart';

import 'sustain_pedal.dart';

/// Plays realistic piano samples from the YDP Grand Piano SoundFont.
class SoundFontEngine {
  final SoLoud _soloud = SoLoud.instance;

  SoundFontPlayer? _player;
  Preset? _pianoPreset;

  // Each pointer gets its own voice, even when two pointers play the same key.
  final Map<int, SoundFontVoice> _activeVoices = {};

  // Tracks sustain-pedal state and notes awaiting pedal release.
  final SustainPedal _sustainPedal = SustainPedal();

  // Keeps actions from each pointer in the correct order.
  final Map<int, Future<void>> _pointerActions = {};

  Future<void>? _initialization;

  bool get isInitialized => _player != null;

  /// Whether the sustain pedal is currently pressed.
  bool get isSustainPedalDown => _sustainPedal.isDown;

  /// Presses the sustain pedal.
  void sustainPedalDown() {
    _sustainPedal.press();
  }

  /// Releases the sustain pedal and releases all deferred notes.
  Future<void> sustainPedalUp() {
    return _sustainPedal.release();
  }

  /// Loads the audio engine and the Acoustic Grand Piano preset.
  Future<void> initialize() async {
    if (_player != null) return;

    // Prevent multiple simultaneous attempts to load the same SoundFont.
    final existingInitialization = _initialization;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    final initialization = _loadSoundFont();
    _initialization = initialization;

    try {
      await initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _loadSoundFont() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }

    _soloud.setMaxActiveVoiceCount(128);

    final soundFont = await SoundFontFile.fromAsset(
      'assets/soundfonts/YDP-GrandPiano-SF2-20160804/'
      'YDP-GrandPiano-20160804.sf2',
    );

    // General MIDI bank 0, program 0 = Acoustic Grand Piano.
    final pianoPreset = soundFont.findPreset(bank: 0, program: 0);

    if (pianoPreset == null) {
      throw StateError(
        'Acoustic Grand Piano preset (bank 0, program 0) '
        'was not found in the loaded SoundFont.',
      );
    }

    final player = soundFont.createPlayer(
      options: const SoundFontPlayerOptions(
        joinStereoChannels: true,
        cacheAudioSources: true,
        useScheduledPlayback: true,
        preloadAllSamples: false,
        sustain: 1.0,
        sustainTime: 0.20,
      ),
    );

    _pianoPreset = pianoPreset;
    _player = player;
  }

  /// Starts a piano note for a particular pointer.
  Future<void> noteOn(int pointerId, int midiNote, {int velocity = 100}) {
    if (midiNote < 0 || midiNote > 127) {
      throw RangeError.range(midiNote, 0, 127, 'midiNote');
    }

    if (velocity < 1 || velocity > 127) {
      throw RangeError.range(velocity, 1, 127, 'velocity');
    }

    return _queuePointerAction(pointerId, () async {
      await initialize();

      // Release this pointer's previous note, if it had one.
      final oldVoice = _activeVoices.remove(pointerId);
      if (oldVoice != null) {
        await oldVoice.release();
      }

      final voice = await _player!.noteOn(
        midiNote,
        preset: _pianoPreset!,
        velocity: velocity,
      );

      _activeVoices[pointerId] = voice;
    });
  }

  /// Releases the note belonging to a pointer.
  ///
  /// Captures the pedal cycle immediately, before queueing the action.
  /// This preserves the timing of the actual key-release event.
  Future<void> noteOff(int pointerId) {
    final pedalCycle = _sustainPedal.activeCycle;

    return _queuePointerAction(pointerId, () async {
      final voice = _activeVoices.remove(pointerId);

      if (voice != null) {
        await _sustainPedal.releaseNote(
          cycle: pedalCycle,
          release: () => voice.release(),
        );
      }
    });
  }

  /// Releases all currently playing notes.
  Future<void> allNotesOff() async {
    await _player?.allNotesOff();

    _activeVoices.clear();
    _sustainPedal.clearDeferredReleases();
  }

  /// Releases resources owned by this SoundFont player.
  Future<void> dispose() async {
    final pendingInitialization = _initialization;

    if (pendingInitialization != null) {
      try {
        await pendingInitialization;
      } catch (_) {
        // Allow cleanup even if SoundFont loading failed.
      }
    }

    final pendingActions = _pointerActions.values.toList();

    if (pendingActions.isNotEmpty) {
      await Future.wait(
        pendingActions.map((action) => action.catchError((Object _) {})),
      );
    }

    // Prevent deferred callbacks from surviving engine disposal.
    _sustainPedal.clearDeferredReleases();

    await _player?.dispose();

    _activeVoices.clear();
    _player = null;
    _pianoPreset = null;
    _initialization = null;
  }

  Future<void> _queuePointerAction(
    int pointerId,
    Future<void> Function() action,
  ) async {
    final previous = _pointerActions[pointerId] ?? Future<void>.value();

    // A failed earlier action must not block later actions.
    final next = previous.catchError((Object _) {}).then((_) => action());

    _pointerActions[pointerId] = next;

    try {
      await next;
    } finally {
      if (identical(_pointerActions[pointerId], next)) {
        _pointerActions.remove(pointerId);
      }
    }
  }
}
