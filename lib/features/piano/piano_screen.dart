
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/soundfont_engine.dart';
import 'piano_keyboard.dart';
import 'piano_note.dart';

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  static const Color backgroundColor = Color(0xFF121212);
  static const Color panelColor = Color(0xFF1E1E1E);
  static const Color goldColor = Color(0xFFD4AF37);

  final AudioEngine _audioEngine = AudioEngine();
  final SoundFontEngine _soundFontEngine = SoundFontEngine();

static const int _soundFontTestPointerId = 9999;

bool _isSoundFontBusy = false;
bool _isSoundFontPlaying = false;

String _soundFontStatus = 'SoundFont test ready';

  SoundHandle? _testNoteHandle;
  bool _isBusy = false;
  String _audioStatus = 'Audio test ready';
// Start a note when a piano key is pressed.
Future<void> _startKeyboardNote(
  int pointerId,
  int midiNote,
) async {
  final note = PianoNote(midiNote);

  if (mounted) {
    setState(() {
      _audioStatus = 'Key pressed: ${note.fullName}';
    });
  }

  try {
  await _soundFontEngine.noteOn(
  pointerId,
  midiNote,
  velocity: 100,
);

    if (!mounted) return;

    setState(() {
      _audioStatus = 'Playing ${note.fullName}';
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _audioStatus = 'Audio error: $error';
    });
  }
}

// Stop a note when a piano key is released.
Future<void> _stopKeyboardNote(int pointerId) async {
  try {
    await _soundFontEngine.noteOff(pointerId);

    if (!mounted) return;

    setState(() {
      _audioStatus = 'Audio test ready';
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _audioStatus = 'Audio error: $error';
    });
  }
}
  Future<void> _playA4() async {
    setState(() {
      _isBusy = true;
      _audioStatus = 'Initializing audio...';
    });

    try {
      await _audioEngine.initialize();

      final handle = await _audioEngine.playTestNote(440);

      if (!mounted) {
        await _audioEngine.stopTestNote(handle);
        return;
      }

      setState(() {
        _testNoteHandle = handle;
        _audioStatus = 'Playing A4 — 440 Hz';
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _audioStatus = 'Audio error: $error';
        _isBusy = false;
      });
    }
  }

  Future<void> _stopA4() async {
    final handle = _testNoteHandle;
    if (handle == null) return;

    setState(() {
      _isBusy = true;
    });

    try {
      await _audioEngine.stopTestNote(handle);

      if (!mounted) return;

      setState(() {
        _testNoteHandle = null;
        _audioStatus = 'Audio test ready';
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _audioStatus = 'Audio error: $error';
        _isBusy = false;
      });
    }
  }
Future<void> _playSoundFontA4() async {
  setState(() {
    _isSoundFontBusy = true;
    _soundFontStatus = 'Loading grand piano samples...';
  });

  try {
    await _soundFontEngine.noteOn(
      _soundFontTestPointerId,
      69,
      velocity: 100,
    );

    if (!mounted) {
      await _soundFontEngine.noteOff(_soundFontTestPointerId);
      return;
    }

    setState(() {
      _isSoundFontPlaying = true;
      _isSoundFontBusy = false;
      _soundFontStatus = 'Playing A4 — YDP Grand Piano';
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _isSoundFontBusy = false;
      _soundFontStatus = 'SoundFont error: $error';
    });
  }
}

Future<void> _stopSoundFontA4() async {
  setState(() {
    _isSoundFontBusy = true;
  });

  try {
    await _soundFontEngine.noteOff(_soundFontTestPointerId);

    if (!mounted) return;

    setState(() {
      _isSoundFontPlaying = false;
      _isSoundFontBusy = false;
      _soundFontStatus = 'SoundFont test ready';
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _isSoundFontBusy = false;
      _soundFontStatus = 'SoundFont error: $error';
    });
  }
}
  @override
  void dispose() {
    final handle = _testNoteHandle;

    if (handle != null) {
      unawaited(_audioEngine.stopTestNote(handle));
    }

    unawaited(_soundFontEngine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: panelColor,
        foregroundColor: Colors.white,
        title: const Text('PianoX — Piano Workspace'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
  padding: const EdgeInsets.all(24),
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                const Text(
                  'PIANO WORKSPACE',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Make some music.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore the keyboard and discover your sound.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Temporary audio test controls.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUDIO ENGINE TEST',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _audioStatus,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isBusy || _testNoteHandle != null
                                ? null
                                : _playA4,
                            child: const Text('Play A4'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isBusy || _testNoteHandle == null
                                ? null
                                : _stopA4,
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOUNDFONT GRAND PIANO TEST',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _soundFontStatus,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSoundFontBusy ||
                                    _isSoundFontPlaying
                                ? null
                                : _playSoundFontA4,
                            child: const Text('Play Sampled A4'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isSoundFontBusy ||
                                    !_isSoundFontPlaying
                                ? null
                                : _stopSoundFontA4,
                            child: const Text('Release Note'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACOUSTIC GRAND PIANO',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PianoKeyboard(
  onNoteOn: (pointerId, midiNote) {
    unawaited(
      _startKeyboardNote(pointerId, midiNote),
    );
  },
  onNoteOff: (pointerId, midiNote) {
    unawaited(
      _stopKeyboardNote(pointerId),
    );
  },
),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
