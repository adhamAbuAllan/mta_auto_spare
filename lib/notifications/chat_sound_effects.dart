import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Lightweight in-app sounds for an open conversation.
///
/// Background message alerts continue to use the operating system's push
/// notification sound; these effects are intentionally limited to actions in
/// the foreground chat experience.
class ChatSoundEffects {
  final AudioPlayer _incomingMessagePlayer = AudioPlayer();
  final AudioPlayer _recordingStartPlayer = AudioPlayer();
  final AudioPlayer _voicePlaybackEndPlayer = AudioPlayer();

  Future<void> playIncomingMessage() {
    return _play(_incomingMessagePlayer, 'assets/sounds/incoming_message.wav');
  }

  Future<void> playRecordingStarted() {
    return _play(_recordingStartPlayer, 'assets/sounds/recording_start.wav');
  }

  Future<void> playVoicePlaybackEnded() {
    return _play(
      _voicePlaybackEndPlayer,
      'assets/sounds/voice_playback_end.wav',
    );
  }

  Future<void> _play(AudioPlayer player, String assetPath) async {
    try {
      await player.stop();
      await player.setAsset(assetPath);
      await player.play();
    } catch (_) {
      // Sounds are optional feedback and must never interrupt chat actions.
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _incomingMessagePlayer.dispose(),
      _recordingStartPlayer.dispose(),
      _voicePlaybackEndPlayer.dispose(),
    ]);
  }
}
