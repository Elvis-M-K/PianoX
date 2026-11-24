typedef NoteRelease = Future<void> Function();

/// Manages sustain-pedal state and deferred piano-note releases.
class SustainPedal {
  bool _isDown = false;
  int _cycle = 0;

  // Notes released during each pedal-down cycle.
  final Map<int, List<NoteRelease>> _deferredReleases = {};

  bool get isDown => _isDown;

  /// Identifies the current pedal press, or null when the pedal is up.
  int? get activeCycle => _isDown ? _cycle : null;

  /// Presses the pedal. Repeated press events do not create new cycles.
  void press() {
    if (_isDown) return;

    _isDown = true;
    _cycle++;
  }

  /// Releases notes deferred during the current pedal-down cycle.
  Future<void> release() {
    if (!_isDown) return Future<void>.value();

    final cycle = _cycle;
    _isDown = false;

    final releases = _deferredReleases.remove(cycle) ?? <NoteRelease>[];

    return Future.wait<void>(releases.map((releaseNote) => releaseNote()))
        .then<void>((_) {});
  }

  /// Releases a note immediately or defers it until the pedal is lifted.
  ///
  /// [cycle] must be captured when the physical key-release event occurs.
  /// This protects against delayed events crossing pedal cycles.
  Future<void> releaseNote({
    required int? cycle,
    required NoteRelease release,
  }) {
    if (cycle != null && _isDown && cycle == _cycle) {
      _deferredReleases.putIfAbsent(cycle, () => <NoteRelease>[]).add(release);

      return Future<void>.value();
    }

    return release();
  }

  /// Clears deferred callbacks after an external all-notes-off operation.
  void clearDeferredReleases() {
    _deferredReleases.clear();
  }
}
