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
  AudioSource? _waveform;

  bool get soundEnabled => _soundEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;

    try {
      await SoLoud.instance.init();
      // Load a sine waveform for soft bell-like tones
      // Parameters: waveform, superWave, scale, detune
      _waveform = await SoLoud.instance.loadWaveform(
        WaveForm.sin,
        false,
        0.5,
        0.0,
      );

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
    if (!_soundEnabled || !_initialized || _waveform == null) return;

    try {
      // Pick random frequency from pentatonic scale
      final freq = _frequencies[_random.nextInt(_frequencies.length)];

      // Set frequency on the waveform source, then play
      SoLoud.instance.setWaveformFreq(_waveform!, freq);
      final handle = await SoLoud.instance.play(_waveform!, volume: 0.25);

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

  @override
  void dispose() {
    if (_waveform != null) {
      SoLoud.instance.disposeSource(_waveform!);
    }
    SoLoud.instance.filters.freeverbFilter.deactivate();
    SoLoud.instance.deinit();
    super.dispose();
  }
}
