import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _keyboardPlayer = AudioPlayer();
  final AudioPlayer _benarPlayer = AudioPlayer();
  final AudioPlayer _salahPlayer = AudioPlayer();

  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> initializeMusic() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    if (_isMusicEnabled) {
      try {
        await _musicPlayer.play(AssetSource('music.mp3'));
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint("Error playing music: $e");
      }
    }
  }

  Future<void> playClickSound() async {
    if (_isSoundEnabled) {
      try {
        await _clickPlayer.play(AssetSource('click.mp3'));
      } catch (e) {
        debugPrint("Error playing click sound: $e");
      }
    }
  }

  Future<void> playKeyboardSound() async {
    if (_isSoundEnabled) {
      try {
        await _keyboardPlayer.play(AssetSource('keyboard.mp3'));
      } catch (e) {
        debugPrint("Error playing keyboard sound: $e");
      }
    }
  }

  Future<void> playBenarSound() async {
    if (_isSoundEnabled) {
      try {
        await _benarPlayer.play(AssetSource('benar.mp3'));
      } catch (e) {
        debugPrint("Error playing benar sound: $e");
      }
    }
  }

  Future<void> playSalahSound() async {
    if (_isSoundEnabled) {
      try {
        await _salahPlayer.play(AssetSource('salah.mp3'));
      } catch (e) {
        debugPrint("Error playing salah sound: $e");
      }
    }
  }

  void toggleMusic(bool value) {
    _isMusicEnabled = value;
    value ? _musicPlayer.resume() : _musicPlayer.pause();
    notifyListeners();
  }

  void toggleSound(bool value) {
    _isSoundEnabled = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _clickPlayer.dispose();
    _keyboardPlayer.dispose();
    _benarPlayer.dispose();
    _salahPlayer.dispose();
    super.dispose();
  }
}
