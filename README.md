# PianoX

An interactive digital piano built with Flutter and Dart.

PianoX aims to make piano playing and music learning more accessible
through a responsive virtual keyboard, realistic instrument audio,
and multiple input methods.

## Project Status

Active development.

The Windows desktop application currently supports interactive piano
playing, velocity control, sustain, and the complete standard 88-key
piano range.

## Implemented Features

### Piano Keyboard
- Full standard 88-key piano range (A0–C8).
- Eight selectable keyboard ranges.
- Visual piano keyboard with black and white keys.
- Range navigation.

### Input Methods
- Touchscreen input with simultaneous multi-touch.
- Mouse input.
- Physical computer keyboard input.
- Simultaneous note playback.

### Sound and Expression
- YDP Grand Piano SoundFont instrument.
- Soft, Normal and Strong velocity presets.
- MIDI velocity values of 45, 80 and 115.
- On-screen sustain pedal.
- Spacebar sustain control.
- Independent note tracking.

### User Interface
- Dark interface with gold accents.
- Dedicated piano workspace.
- Scrollable help and keyboard instructions.
- Inline velocity selector.

## Computer Keyboard Controls

| Key | Function |
|---|---|
| A W S E D F T G Y H U J | Piano notes |
| K | Additional C8 note in the highest range |
| Spacebar | Sustain pedal |

The mapped notes follow the currently selected piano range.

## Technology Stack

- Flutter
- Dart
- flutter_soloud
- SoundFont audio
- Git and GitHub

## Getting Started

### Requirements

- Flutter SDK
- Git
- Windows desktop development environment

### Clone the repository

```powershell
git clone https://github.com/Elvis-M-K/PianoX.git
cd PianoX