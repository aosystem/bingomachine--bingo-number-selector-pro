import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class SoundPlayer {
  SoundPlayer() {
    _load();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;

  Future<void> _load() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech().copyWith(
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
      androidWillPauseWhenDucked: false,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    ));
    try {
      await _player.setAsset('assets/audio/karakara.wav');
      await _player.load();
      _loaded = true;
    } catch (_) {
      _loaded = false;
    }
  }

  Future<void> play(double volume) async {
    if (!_loaded) {
      await _load();
    }
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
