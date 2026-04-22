import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService extends ChangeNotifier {
  static const String _soundEnabledKey = 'sound_enabled';

  // Pentatonic scale frequencies (C5, D5, E5, G5, A5) - always sounds pleasant
  static const List<double> _frequencies = [523.25, 587.33, 659.25, 783.99, 880.0];

  final Random _random = Random();
  bool _soundEnabled = true;
  bool _initialized = false;
  // One AudioSource per frequency — handles from different sources are fully
  // independent, so playing note N never mutates the pitch of note N-1.
  final Map<double, AudioSource> _waveforms = {};
  bool _isPlayingCreation = false;
  int _lastChimeMs = 0;

  bool get soundEnabled => _soundEnabled;

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

      // Add global reverb filter for echoing effect
      SoLoud.instance.filters.freeverbFilter.activate();
      SoLoud.instance.filters.freeverbFilter.wet.value = 0.65;      // Mix: 30% reverb
      SoLoud.instance.filters.freeverbFilter.roomSize.value = 0.85; // Large room

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
    if (now - _lastChimeMs < 150) return;
    _lastChimeMs = now;

    try {
      final freq = _frequencies[_random.nextInt(_frequencies.length)];
      final handle = SoLoud.instance.play(_waveforms[freq]!, volume: 0.25);

      // Longer duration with gradual fade for reverb tail
      Future.delayed(const Duration(milliseconds: 500), () {
        if (SoLoud.instance.isInitialized) {
          SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 100));
          Future.delayed(const Duration(milliseconds: 250), () {
            SoLoud.instance.stop(handle);
          });
        }
      });
    } catch (e) {
      debugPrint('SoundService playChime failed: $e');
    }
  }

  Future<void> playStarCreation() async {
    if (!_soundEnabled || !_initialized || _waveforms.isEmpty) return;
    if (_isPlayingCreation) return;
    _isPlayingCreation = true;

    try {
      // Play ascending pentatonic sequence
      for (int i = 0; i < _frequencies.length; i++) {
        final freq = _frequencies[i];
        final isLast = i == _frequencies.length - 1;

        await Future.delayed(Duration(milliseconds: i * 80));

        final handle = SoLoud.instance.play(
          _waveforms[freq]!,
          volume: isLast ? 0.35 : 0.2,
        );

        // Final note rings longer
        final holdTime = isLast ? 600 : 150;
        Future.delayed(Duration(milliseconds: holdTime), () {
          if (SoLoud.instance.isInitialized) {
            SoLoud.instance.fadeVolume(
              handle,
              0,
              Duration(milliseconds: isLast ? 200 : 80),
            );
            Future.delayed(Duration(milliseconds: isLast ? 300 : 100), () {
              SoLoud.instance.stop(handle);
            });
          }
        });
      }
    } catch (e) {
      debugPrint('SoundService playStarCreation failed: $e');
    } finally {
      _isPlayingCreation = false;
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
