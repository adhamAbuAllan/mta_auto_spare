part of '../chat_detail_page.dart';

abstract class _ChatDetailPageStateVoiceAndMedia
    extends _ChatDetailPageStateMessageActions {
  Future<void> _startVoiceRecording() async {
    final l10n = context.l10n;
    if (_isVoiceRecording || _isVoiceRecorderBusy) {
      return;
    }
    if (_messageController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedProduct != null) {
      _showComposerSnackBar(l10n.sendOrClearDraftBeforeVoiceMessage);
      return;
    }

    setState(() {
      _isVoiceRecorderBusy = true;
    });

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showComposerSnackBar(l10n.microphonePermissionRequiredForVoiceMessage);
        return;
      }

      final tempDirectory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${tempDirectory.path}${Platform.pathSeparator}voice-${widget.conversationId}-$timestamp.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 24000,
          numChannels: 1,
          bitRate: 48000,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: filePath,
      );
      if (!mounted) {
        await _audioRecorder.cancel();
        return;
      }

      _composerFocusNode.unfocus();
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
      setState(() {
        _isVoiceRecording = true;
        _voiceRecordingStartedAt = DateTime.now();
        _voiceRecordingDuration = Duration.zero;
      });
      _startVoiceRecordingTicker();
      _keepLatestMessageVisible();
    } catch (_) {
      _showComposerSnackBar(l10n.voiceRecordingCouldNotStart);
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording({bool silent = false}) async {
    final l10n = context.l10n;
    if (_isVoiceRecorderBusy) {
      return;
    }

    final shouldCancel = _isVoiceRecording || _voiceRecordingStartedAt != null;
    if (!shouldCancel) {
      return;
    }

    if (mounted) {
      setState(() {
        _isVoiceRecorderBusy = true;
      });
    }

    try {
      await _audioRecorder.cancel();
      if (!silent) {
        _showComposerSnackBar(l10n.voiceMessageDiscarded);
      }
    } catch (_) {
      if (!silent) {
        _showComposerSnackBar(l10n.voiceMessageDiscardFailed);
      }
    } finally {
      _resetVoiceRecordingState();
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _stopAndSendVoiceMessage() async {
    final l10n = context.l10n;
    if (!_isVoiceRecording || _isVoiceRecorderBusy) {
      return;
    }

    setState(() {
      _isVoiceRecorderBusy = true;
    });

    try {
      final recordedPath = await _audioRecorder.stop();
      if (recordedPath == null || recordedPath.trim().isEmpty) {
        _resetVoiceRecordingState();
        _showComposerSnackBar(l10n.noVoiceMessageCaptured);
        return;
      }

      final recordedFile = File(recordedPath);
      final attachment = ChatUploadImage(
        path: recordedPath,
        fileName: recordedFile.path.split(Platform.pathSeparator).last,
        contentType: 'audio/mp4',
        size: await recordedFile.length(),
      );

      _resetVoiceRecordingState();
      await _sendMessage(attachmentsOverride: [attachment]);
    } catch (_) {
      _showComposerSnackBar(l10n.voiceMessageCouldNotBeSent);
      _resetVoiceRecordingState();
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (!mounted || pickedFiles.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages = [
        ..._selectedImages,
        ...pickedFiles.map(_mapPickedFile),
      ];
    });
  }

  void _removeSelectedImage(ChatUploadImage image) {
    setState(() {
      _selectedImages = _selectedImages
          .where((item) => item.path != image.path)
          .toList(growable: false);
    });
  }

  void _handleComposerChanged() {
    if (_isVoiceRecording) {
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
      return;
    }
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_composerFocusNode.hasFocus) {
      _keepLatestMessageVisible();
    }
    _messagesNotifier.sendTyping(
      isTyping: _composerFocusNode.hasFocus && hasText,
      hasText: hasText,
    );
  }

  ChatUploadImage _mapPickedFile(XFile file) {
    final fileName = file.name.trim().isNotEmpty
        ? file.name
        : file.path.split(Platform.pathSeparator).last;
    return ChatUploadImage(
      path: file.path,
      fileName: fileName,
      contentType: lookupMimeType(file.path) ?? _fallbackMimeType(fileName),
    );
  }

  String _fallbackMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  void _startVoiceRecordingTicker() {
    _voiceRecordingTicker?.cancel();
    _voiceRecordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _voiceRecordingStartedAt;
      if (!mounted || startedAt == null) {
        return;
      }
      setState(() {
        _voiceRecordingDuration = DateTime.now().difference(startedAt);
      });
    });
  }

  void _resetVoiceRecordingState() {
    _voiceRecordingTicker?.cancel();
    _voiceRecordingTicker = null;
    _voiceRecordingStartedAt = null;
    _voiceRecordingDuration = Duration.zero;
    _isVoiceRecording = false;
  }
}
