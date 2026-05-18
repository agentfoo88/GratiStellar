import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_logger.dart';

class SoundService extends ChangeNotifier {
  static const String _soundEnabledKey = 'sound_enabled';

  // Pentatonic scale frequencies (C5, D5, E5, G5, A5) - always sounds pleasant
  static const List<double> _frequencies = [523.25, 587.33, 659.25, 783.99, 880.0];

  /// Original pleasant mix (creation-tune era); per-frequency sources avoid doubling.
  static const double _freeverbWet = 0.65;
  static const double _freeverbRoom = 0.85;

  /// Chime envelope: soft attack avoids “stuttery” onset; long tail lets reverb decay.
  static const int _chimeAttackMs = 72;
  static const double _chimePeakVolume = 0.25;
  static const int _chimeSustainMs = 1100;
  static const int _chimeFadeMs = 320;
  static const int _chimeTailAfterFadeMs = 1250;

  /// Creation arpeggio: shorter attack than chime so steps stay distinct.
  static const int _creationAttackMs = 48;
  static const int _creationInnerSustainMs = 360;
  static const int _creationInnerFadeMs = 180;
  static const int _creationInnerTailMs = 560;

  static const int _creationFinalSustainMs = 1250;
  static const int _creationFinalFadeMs = 400;
  static const int _creationFinalTailMs = 980;

  final Random _random = Random();
  bool _soundEnabled = true;
  bool _initialized = false;
  // One AudioSource per frequency — handles from different sources are fully
  // independent, so playing note N never mutates the pitch of note N-1.
  final Map<double, AudioSource> _waveforms = {};
  bool _isPlayingCreation = false;
  int _lastChimeMs = 0;
  int _debugSoundSeq = 0;

  bool get soundEnabled => _soundEnabled;

  void _logSoundPath(String message) {
    if (!kDebugMode) return;
    _debugSoundSeq++;
    AppLogger.debug('[$_debugSoundSeq] $message', 'Sound');
  }

  /// Play silent then ramp to [peakVolume] — removes clicky / “separated” attack on waveforms + reverb.
  SoundHandle _playWithSoftAttack(
    AudioSource source,
    double peakVolume, {
    required int attackMs,
  }) {
    final handle = SoLoud.instance.play(source, volume: 0);
    SoLoud.instance.fadeVolume(
      handle,
      peakVolume,
      Duration(milliseconds: attackMs),
    );
    return handle;
  }

  /// Schedules fade then [stop] only after fade completes plus [tailMs] for reverb decay.
  /// flutter_soloud 4.x `play()` is synchronous; timing is controlled here, not via `await play`.
  void _scheduleFadeStopTail(
    SoundHandle handle, {
    required int sustainMs,
    required int fadeMs,
    required int tailMs,
  }) {
    Future.delayed(Duration(milliseconds: sustainMs), () {
      if (!SoLoud.instance.isInitialized) return;
      SoLoud.instance.fadeVolume(handle, 0, Duration(milliseconds: fadeMs));
    });
    Future.delayed(Duration(milliseconds: sustainMs + fadeMs + tailMs), () {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.stop(handle);
      }
    });
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;

    try {
      await SoLoud.instance.init();

      for (final freq in _frequencies) {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.sin,
          false,
          0.5,
          0.0,
        );
        SoLoud.instance.setWaveformFreq(source, freq);
        _waveforms[freq] = source;
      }

      SoLoud.instance.filters.freeverbFilter.activate();
      SoLoud.instance.filters.freeverbFilter.wet.value = _freeverbWet;
      SoLoud.instance.filters.freeverbFilter.roomSize.value = _freeverbRoom;

      _initialized = true;
    } catch (e) {
      debugPrint('SoundService initialization failed: $e');
      _initialized = false;
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> playChime() async {
    if (!_soundEnabled || !_initialized || _waveforms.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastChimeMs < 150) {
      _logSoundPath(
        'playChime DEBOUNCED ${now - _lastChimeMs}ms since last (threshold 150ms)',
      );
      return;
    }
    _lastChimeMs = now;

    try {
      final freq = _frequencies[_random.nextInt(_frequencies.length)];
      _logSoundPath('playChime SoLoud.play frequency=${freq}Hz');
      final handle = _playWithSoftAttack(
        _waveforms[freq]!,
        _chimePeakVolume,
        attackMs: _chimeAttackMs,
      );

      _scheduleFadeStopTail(
        handle,
        sustainMs: _chimeSustainMs,
        fadeMs: _chimeFadeMs,
        tailMs: _chimeTailAfterFadeMs,
      );
    } catch (e) {
      debugPrint('SoundService playChime failed: $e');
    }
  }

  Future<void> playStarCreation() async {
    if (!_soundEnabled || !_initialized || _waveforms.isEmpty) return;
    if (_isPlayingCreation) {
      _logSoundPath('playStarCreation SKIP (sequence already in progress)');
      return;
    }
    _isPlayingCreation = true;
    _logSoundPath('playStarCreation START (5 steps)');

    try {
      // Play ascending pentatonic sequence
      for (int i = 0; i < _frequencies.length; i++) {
        final freq = _frequencies[i];
        final isLast = i == _frequencies.length - 1;

        await Future.delayed(Duration(milliseconds: i * 80));

        _logSoundPath('playStarCreation SoLoud.play step=${i + 1}/5 frequency=${freq}Hz');
        final peak = isLast ? 0.35 : 0.2;
        final handle = _playWithSoftAttack(
          _waveforms[freq]!,
          peak,
          attackMs: _creationAttackMs,
        );

        if (isLast) {
          _scheduleFadeStopTail(
            handle,
            sustainMs: _creationFinalSustainMs,
            fadeMs: _creationFinalFadeMs,
            tailMs: _creationFinalTailMs,
          );
        } else {
          _scheduleFadeStopTail(
            handle,
            sustainMs: _creationInnerSustainMs,
            fadeMs: _creationInnerFadeMs,
            tailMs: _creationInnerTailMs,
          );
        }
      }
    } catch (e) {
      debugPrint('SoundService playStarCreation failed: $e');
    } finally {
      _isPlayingCreation = false;
      _logSoundPath('playStarCreation END');
    }
  }

  @override
  void dispose() {
    for (final source in _waveforms.values) {
      SoLoud.instance.disposeSource(source);
    }
    _waveforms.clear();
    SoLoud.instance.filters.freeverbFilter.deactivate();
    SoLoud.instance.deinit();
    super.dispose();
  }
}
