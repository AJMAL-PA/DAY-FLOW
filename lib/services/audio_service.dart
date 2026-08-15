import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../models/settings.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static Timer? _loopTimer;

  static Uint8List _generateToneWav({
    required List<double> frequencies,
    required double durationSeconds,
    required double decay,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    const int numChannels = 1;
    const int bitsPerSample = 16;
    const int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int dataSize = numSamples * blockAlign;
    final int fileSize = 36 + dataSize;

    final ByteData header = ByteData(44);
    // RIFF
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    // WAVE
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // fmt 
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final ByteData pcm = ByteData(dataSize);
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      double sample = 0.0;
      for (int f = 0; f < frequencies.length; f++) {
        final double freq = frequencies[f];
        final double noteStartTime = f * 0.12;
        if (t >= noteStartTime) {
          final double dt = t - noteStartTime;
          sample += math.sin(2 * math.pi * freq * dt) * math.exp(-decay * dt);
        }
      }

      sample = (sample / frequencies.length).clamp(-1.0, 1.0);
      final int pcmVal = (sample * 32767).toInt();
      pcm.setInt16(i * 2, pcmVal, Endian.little);
    }

    final Uint8List result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, pcm.buffer.asUint8List());
    return result;
  }

  static Uint8List getToneBytes(AlarmTone tone) {
    switch (tone) {
      case AlarmTone.gentle:
        return _generateToneWav(frequencies: [523.25, 659.25, 783.99], durationSeconds: 1.5, decay: 2.0);
      case AlarmTone.marimba:
        return _generateToneWav(frequencies: [440.0, 554.37, 659.25, 880.0], durationSeconds: 1.2, decay: 4.0);
      case AlarmTone.digital:
        return _generateToneWav(frequencies: [1046.5, 1046.5, 1046.5], durationSeconds: 0.8, decay: 8.0);
      case AlarmTone.harp:
        return _generateToneWav(frequencies: [329.63, 440.0, 554.37, 659.25, 880.0], durationSeconds: 2.0, decay: 1.5);
      case AlarmTone.bell:
        return _generateToneWav(frequencies: [880.0, 1760.0], durationSeconds: 1.0, decay: 5.0);
      case AlarmTone.zen:
        return _generateToneWav(frequencies: [220.0, 440.0], durationSeconds: 2.5, decay: 0.8);
      case AlarmTone.birds:
        return _generateToneWav(frequencies: [1760.0, 2637.02, 3520.0], durationSeconds: 1.2, decay: 6.0);
    }
  }

  static Future<void> playAlarmTone(AlarmTone tone, {bool soundEnabled = true}) async {
    if (!soundEnabled) return;
    await stopAlarm();
    _isPlaying = true;

    try {
      final bytes = getToneBytes(tone);
      await _audioPlayer.play(BytesSource(bytes));

      _loopTimer?.cancel();
      _loopTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) async {
        if (_isPlaying) {
          try {
            await _audioPlayer.play(BytesSource(bytes));
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  static Future<void> playTonePreview(AlarmTone tone) async {
    await stopAlarm();
    try {
      final bytes = getToneBytes(tone);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  static Future<void> stopAlarm() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    if (_isPlaying) {
      try {
        await _audioPlayer.stop();
      } catch (_) {}
      _isPlaying = false;
    }
  }
}
