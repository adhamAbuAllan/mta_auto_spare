part of '../chat_detail_page.dart';

enum _ChatMessageAction { copy, edit, delete, cancel }

enum _ChatMessageDeleteScope {
  all('all'),
  me('me'),
  cancel('');

  const _ChatMessageDeleteScope(this.apiValue);

  final String apiValue;
}

abstract class _ChatDetailPageStateMessageActions
    extends _ChatDetailPageStateRequestAccess {
  Future<void> _sendMessage({
    PartRequestBrief? sharedProduct,
    List<ChatUploadImage>? attachmentsOverride,
  }) async {
    final text = _messageController.text.trim();
    final productToSend = sharedProduct ?? _selectedProduct;
    final attachments =
        attachmentsOverride ?? List<ChatUploadImage>.from(_selectedImages);
    if (text.isEmpty && attachments.isEmpty && productToSend == null) {
      return;
    }

    final currentUser = ref.read(currentSessionProvider).profile;
    if (currentUser == null) {
      return;
    }

    final replyTarget = _replyTarget;
    _messageController.clear();
    _keepLatestMessageVisible();

    final didSend = await _messagesNotifier.send(
      request: MessageCreateRequest(
        conversation: widget.conversationId,
        messageType: productToSend != null
            ? 'product'
            : attachments.isNotEmpty
            ? 'media'
            : 'text',
        text: text.isEmpty ? null : text,
        product: productToSend?.id,
        replyTo: replyTarget?.id,
        clientTimestamp: DateTime.now().toUtc(),
        attachments: attachments,
      ),
      sender: UserBrief(
        id: currentUser.id,
        name: currentUser.name,
        avatar: currentUser.avatar,
      ),
      optimisticProduct: productToSend,
      optimisticReply: replyTarget == null
          ? null
          : _replyPreviewFromMessage(replyTarget),
    );
    if (!mounted) {
      return;
    }
    if (didSend) {
      setState(() {
        _selectedImages = const [];
        _replyTarget = null;
        _selectedProduct = null;
      });
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
    }
    _keepLatestMessageVisible();
  }

  Future<void> _openMessageActions(
      MessageModel message,
      int currentUserId,
      ) async {
    final l10n = context.l10n;
    final canCopy = _canCopyMessage(message);
    final canEdit = _canEditMessage(message, currentUserId);
    final canDelete = _canDeleteForMe(message);
    if (!canCopy && !canEdit && !canDelete) {
      return;
    }

    final action = await showModalBottomSheet<_ChatMessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (canCopy)
                ListTile(
                  leading: const Icon(Icons.content_copy_rounded),
                  title: Text(l10n.copyMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.copy),
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(l10n.editMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.edit),
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(l10n.deleteMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.delete),
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text(l10n.cancel),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageAction.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null || action == _ChatMessageAction.cancel) {
      return;
    }

    switch (action) {
      case _ChatMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text.trim()));
        _showComposerSnackBar(l10n.messageCopied);
        break;
      case _ChatMessageAction.edit:
        await _editMessage(message);
        break;
      case _ChatMessageAction.delete:
        await _confirmDeleteMessage(message, currentUserId);
        break;
      case _ChatMessageAction.cancel:
        break;
    }
  }

  Future<void> _editMessage(MessageModel message) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: message.text);
    String draft = message.text;

    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final trimmedDraft = draft.trim();
            final canSave =
                trimmedDraft.isNotEmpty && trimmedDraft != message.text.trim();
            return AlertDialog(
              title: Text(l10n.editMessageTitle),
              content: TextField(
                controller: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 5,
                onChanged: (value) {
                  setModalState(() {
                    draft = value;
                  });
                },
                decoration: InputDecoration(hintText: l10n.updateYourMessage),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(trimmedDraft)
                      : null,
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (!mounted || updatedText == null) {
      return;
    }

    final updatedMessage = await _messagesNotifier.editMessage(
      message: message,
      text: updatedText,
    );
    if (!mounted) {
      return;
    }
    if (updatedMessage == null) {
      _showComposerSnackBar(l10n.messageCouldNotBeUpdated);
      return;
    }

    if (_replyTarget?.id == updatedMessage.id) {
      setState(() {
        _replyTarget = updatedMessage;
      });
    }
    _showComposerSnackBar(l10n.messageUpdated);
  }

  Future<void> _confirmDeleteMessage(
      MessageModel message,
      int currentUserId,
      ) async {
    final l10n = context.l10n;
    final canDeleteForAll = _canDeleteForAll(message, currentUserId);
    final scope = await showModalBottomSheet<_ChatMessageDeleteScope>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (canDeleteForAll)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded),
                  title: Text(l10n.deleteForAll),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageDeleteScope.all),
                ),
              ListTile(
                leading: const Icon(Icons.person_remove_alt_1_rounded),
                title: Text(l10n.deleteOnlyMe),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageDeleteScope.me),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text(l10n.cancel),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageDeleteScope.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || scope == null || scope == _ChatMessageDeleteScope.cancel) {
      return;
    }

    final didDelete = await _messagesNotifier.deleteMessage(
      message: message,
      scope: scope.apiValue,
    );
    if (!mounted) {
      return;
    }
    if (!didDelete) {
      _showComposerSnackBar(l10n.messageCouldNotBeDeleted);
      return;
    }

    if (_replyTarget?.id == message.id) {
      setState(() {
        _replyTarget = null;
      });
    }
    _showComposerSnackBar(
      scope == _ChatMessageDeleteScope.all
          ? l10n.messageDeletedForEveryone
          : l10n.messageDeletedForYou,
    );
  }

  bool _canCopyMessage(MessageModel message) {
    return !message.isDeleted && message.text.trim().isNotEmpty;
  }

  Future<void> _openUserProfile(int userId) async {
    if (userId <= 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  bool _canEditMessage(MessageModel message, int currentUserId) {
    return !message.isDeleted &&
        !message.isOptimistic &&
        !message.hasSendError &&
        message.sender.id == currentUserId &&
        message.messageType == 'text' &&
        message.media.isEmpty &&
        message.product == null;
  }

  bool _canDeleteForMe(MessageModel message) {
    return !message.isOptimistic && message.id > 0;
  }

  bool _canDeleteForAll(MessageModel message, int currentUserId) {
    return _canDeleteForMe(message) &&
        !message.isDeleted &&
        message.sender.id == currentUserId;
  }

  MessageReplyModel _replyPreviewFromMessage(MessageModel message) {
    final l10n = context.l10n;
    return MessageReplyModel(
      id: message.id,
      sender: message.sender,
      text: message.isDeleted
          ? l10n.deletedMessage
          : message.text.trim().isNotEmpty
          ? message.text
          : message.media.any((attachment) => attachment.isAudio)
          ? l10n.voiceMessage
          : message.media.any((attachment) => attachment.isImage)
          ? l10n.photo
          : message.product?.title ?? l10n.attachment,
      translatedText: message.text.trim().isNotEmpty
          ? message.translatedText
          : null,
      textLanguage: message.textLanguage,
      product: message.isDeleted ? null : message.product,
      translationTargetLanguage: message.translationTargetLanguage,
      clientTimestamp: message.clientTimestamp,
      serverTimestamp: message.serverTimestamp,
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
    );
  }
}
