import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/audio/soundfont_engine.dart';
import 'piano_keyboard.dart';
import 'piano_velocity.dart';

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  static const Color backgroundColor = Color(0xFF121212);
  static const Color panelColor = Color(0xFF1E1E1E);
  static const Color goldColor = Color(0xFFD4AF37);

  final SoundFontEngine _soundFontEngine = SoundFontEngine();
  PianoVelocityPreset _velocityPreset = PianoVelocityPreset.normal;
  final Set<String> _activeSustainInputs = {};
  String? _sustainError;

  bool get _isSustainActive => _activeSustainInputs.isNotEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareSoundFont());
  }

  Future<void> _prepareSoundFont() async {
    try {
      await _soundFontEngine.initialize();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Piano audio initialization failed: $error')),
      );
    }
  }

  // Start a note when a piano key is pressed.
  Future<void> _startKeyboardNote(
    int pointerId,
    int midiNote,
    int velocity,
  ) async {
    try {
      await _soundFontEngine.noteOn(pointerId, midiNote, velocity: velocity);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play piano note: $error')),
      );
    }
  }

  // Stop a note when a piano key is released.
  Future<void> _stopKeyboardNote(int pointerId) async {
    try {
      await _soundFontEngine.noteOff(pointerId);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not release piano note: $error')),
      );
    }
  }

  void _setSustainInput(String source, bool pressed) {
    final wasActive = _activeSustainInputs.isNotEmpty;

    if (pressed) {
      _activeSustainInputs.add(source);
    } else {
      _activeSustainInputs.remove(source);
    }

    final isNowActive = _activeSustainInputs.isNotEmpty;

    // Only notify the audio engine when the overall pedal state changes.
    if (wasActive == isNowActive) return;

    if (isNowActive) {
      _sustainError = null;
      _soundFontEngine.sustainPedalDown();
    } else {
      unawaited(_releaseSustainPedal());
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _releaseSustainPedal() async {
    try {
      await _soundFontEngine.sustainPedalUp();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _sustainError = error.toString();
      });
    }
  }

  @override
  void dispose() {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Workspace headings and audio test controls.
                        Column(
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
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
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
                                    'COMPUTER KEYBOARD',
                                    style: TextStyle(
                                      color: goldColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'A  W  S  E  D  F  T  G  Y  H  U  J  K',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Keys follow the selected range; K plays C8 in the highest range.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hold multiple keys together to play chords. '
                                    'Hold SPACEBAR to activate sustain.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Fixed piano workspace: deliberately outside the scroll view.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ACOUSTIC GRAND PIANO',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PLAYING VELOCITY',
                            style: TextStyle(
                              color: goldColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SegmentedButton<PianoVelocityPreset>(
                            showSelectedIcon: false,
                            segments: PianoVelocityPreset.values.map((preset) {
                              return ButtonSegment<PianoVelocityPreset>(
                                value: preset,
                                label: Text(
                                  '${preset.label} · ${preset.velocity}',
                                ),
                              );
                            }).toList(),
                            selected: {_velocityPreset},
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;

                              setState(() {
                                _velocityPreset = selection.first;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      PianoKeyboard(
                        defaultVelocity: _velocityPreset.velocity,
                        onNoteOn: (pointerId, midiNote, velocity) {
                          unawaited(
                            _startKeyboardNote(pointerId, midiNote, velocity),
                          );
                        },
                        onNoteOff: (pointerId, midiNote) {
                          unawaited(_stopKeyboardNote(pointerId));
                        },
                        onSustainDown: () {
                          _setSustainInput('spacebar', true);
                        },
                        onSustainUp: () {
                          _setSustainInput('spacebar', false);
                        },
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) {
                            _setSustainInput('pedal:${event.pointer}', true);
                          },
                          onPointerUp: (event) {
                            _setSustainInput('pedal:${event.pointer}', false);
                          },
                          onPointerCancel: (event) {
                            _setSustainInput('pedal:${event.pointer}', false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _isSustainActive
                                  ? const Color(0xFF3D3218)
                                  : panelColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isSustainActive
                                    ? goldColor
                                    : goldColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.music_note, color: goldColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SUSTAIN PEDAL',
                                        style: TextStyle(
                                          color: goldColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _sustainError ??
                                            (_isSustainActive
                                                ? 'ENGAGED — notes continue after key release'
                                                : 'RELEASED — press and hold to sustain'),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _isSustainActive
                                      ? Icons.check_circle
                                      : Icons.touch_app,
                                  color: _isSustainActive
                                      ? goldColor
                                      : Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
