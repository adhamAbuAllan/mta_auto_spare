import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../constants/api_constants.dart';
import '../../../models/models.dart';

class VoiceMessageCard extends StatefulWidget {
  const VoiceMessageCard({
    super.key,
    required this.attachment,
    required this.isMine,
  });

  final MessageAttachmentModel attachment;
  final bool isMine;

  @override
  State<VoiceMessageCard> createState() => _VoiceMessageCardState();
}

class _VoiceMessageCardState extends State<VoiceMessageCard> {
  late final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isPreparing = false;
  bool _isReady = false;
  double? _dragProgress;
  String? _errorMessage;
  Future<void>? _prepareFuture;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (!mounted) {
        return;
      }

      final isCompleted =
          playerState.processingState == ProcessingState.completed;
      if (isCompleted) {
        unawaited(_player.seek(Duration.zero));
      }

      setState(() {
        _isPlaying = playerState.playing && !isCompleted;
        if (playerState.processingState == ProcessingState.ready ||
            isCompleted) {
          _isReady = true;
          _isPreparing = false;
        }
        if (isCompleted) {
          _position = Duration.zero;
        }
      });
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      if (!mounted || duration == null) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });
    _positionSubscription = _player.positionStream.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });
    unawaited(_warmUpDuration());
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isMine ? Colors.white : const Color(0xFF1C1B18);
    final activeColor = widget.isMine
        ? const Color(0xFF93E8FF)
        : const Color(0xFF116466);
    final inactiveColor = foreground.withValues(alpha: 0.24);
    final containerColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white;
    final effectivePosition = _displayedPosition;
    final progress = _duration.inMilliseconds <= 0
        ? 0.0
        : (effectivePosition.inMilliseconds / _duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final canSeek = _duration.inMilliseconds > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _isPreparing ? null : _togglePlayback,
            style: IconButton.styleFrom(
              backgroundColor: widget.isMine
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF116466),
              foregroundColor: widget.isMine ? Colors.white : Colors.white,
            ),
            icon: _isPreparing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
            tooltip: _isPlaying ? 'Pause voice message' : 'Play voice message',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _VoiceWaveStrip(
                            progress: progress,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          overlayColor: activeColor.withValues(alpha: 0.12),
                          thumbColor: activeColor,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: canSeek ? _handleSeekChanged : null,
                          onChangeEnd: canSeek ? _handleSeekEnd : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatDuration(effectivePosition),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.78),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    try {
      await _ensurePrepared(showLoadingIndicator: true);
      await _player.play();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = false;
        _errorMessage = 'Unable to play voice message';
      });
    }
  }

  Future<void> _warmUpDuration() async {
    try {
      await _ensurePrepared();
    } catch (_) {
      // Best effort metadata warmup.
    }
  }

  Future<void> _ensurePrepared({bool showLoadingIndicator = false}) async {
    if (_isReady) {
      return;
    }

    final ongoingPreparation = _prepareFuture;
    if (ongoingPreparation != null) {
      return ongoingPreparation;
    }

    if (showLoadingIndicator && mounted) {
      setState(() {
        _isPreparing = true;
        _errorMessage = null;
      });
    }

    final future = _prepareSource();
    _prepareFuture = future;
    try {
      await future;
    } finally {
      _prepareFuture = null;
      if (showLoadingIndicator && mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  Future<void> _prepareSource() async {
    final localPath = widget.attachment.localPath?.trim();
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      await _player.setFilePath(localPath);
    } else {
      final fileUrl = widget.attachment.fileUrl?.trim();
      if (fileUrl == null || fileUrl.isEmpty) {
        throw StateError('No audio source available.');
      }
      await _player.setUrl(ApiConstants.resolveUrl(fileUrl));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = true;
      _duration = _player.duration ?? _duration;
    });
  }

  void _handleSeekChanged(double value) {
    setState(() {
      _dragProgress = value.clamp(0.0, 1.0);
    });
  }

  Future<void> _handleSeekEnd(double value) async {
    final nextProgress = value.clamp(0.0, 1.0);
    try {
      await _ensurePrepared();
      if (_duration.inMilliseconds > 0) {
        await _player.seek(_durationFromProgress(nextProgress));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to seek voice message';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dragProgress = null;
        });
      }
    }
  }

  Duration get _displayedPosition {
    final dragProgress = _dragProgress;
    if (dragProgress == null) {
      return _position;
    }
    return _durationFromProgress(dragProgress);
  }

  Duration _durationFromProgress(double progress) {
    if (_duration.inMilliseconds <= 0) {
      return Duration.zero;
    }
    return Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _VoiceWaveStrip extends StatelessWidget {
  const _VoiceWaveStrip({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barCount = math.max(18, (constraints.maxWidth / 8).floor());
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            final phase = math.sin((index * 0.8) + 0.6).abs();
            final height = 6 + (phase * 16);
            final isActive = ((index + 1) / barCount) <= progress;
            return Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
