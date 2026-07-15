import 'dart:async';

typedef VoicePlaybackAction = Future<void> Function();
typedef VoicePlaybackSequenceCompleted = Future<void> Function();

/// Coordinates voice-note playback within one conversation.
///
/// Only one registered note can play at a time. When it completes, playback
/// advances through the order supplied by the chat message list.
class VoiceMessagePlaybackController {
  final Map<String, _VoicePlaybackCallbacks> _callbacks = {};
  List<String> _playbackOrder = const [];
  String? _playingId;
  VoicePlaybackSequenceCompleted? onPlaybackSequenceCompleted;

  void updatePlaybackOrder(Iterable<String> playbackOrder) {
    _playbackOrder = List.unmodifiable(playbackOrder);
  }

  void register({
    required String playbackId,
    required VoicePlaybackAction play,
    required VoicePlaybackAction stop,
  }) {
    _callbacks[playbackId] = _VoicePlaybackCallbacks(play: play, stop: stop);
  }

  void unregister(String playbackId) {
    _callbacks.remove(playbackId);
    if (_playingId == playbackId) {
      _playingId = null;
    }
  }

  Future<void> requestPlay(String playbackId) async {
    final previousId = _playingId;
    if (previousId != null && previousId != playbackId) {
      await _callbacks[previousId]?.stop();
    }

    _playingId = playbackId;
    await _callbacks[playbackId]?.play();
  }

  void notifyPaused(String playbackId) {
    if (_playingId == playbackId) {
      _playingId = null;
    }
  }

  Future<void> notifyCompleted(String playbackId) async {
    if (_playingId != playbackId) {
      return;
    }

    final currentIndex = _playbackOrder.indexOf(playbackId);
    final nextId =
        currentIndex == -1 || currentIndex + 1 >= _playbackOrder.length
        ? null
        : _playbackOrder[currentIndex + 1];

    if (nextId == null) {
      _playingId = null;
      await onPlaybackSequenceCompleted?.call();
      return;
    }

    _playingId = nextId;
    await _callbacks[nextId]?.play();
  }
}

class _VoicePlaybackCallbacks {
  const _VoicePlaybackCallbacks({required this.play, required this.stop});

  final VoicePlaybackAction play;
  final VoicePlaybackAction stop;
}
