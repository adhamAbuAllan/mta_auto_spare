part of '../chat_detail_page.dart';

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 108),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF2EEE7),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => _TypingIndicatorDot(
                    progress: _controller.value,
                    index: index,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorDot extends StatelessWidget {
  const _TypingIndicatorDot({required this.progress, required this.index});

  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final shifted = (progress - (index * 0.16) + 1) % 1;
    final wave = math.sin(shifted * math.pi).clamp(0.0, 1.0).toDouble();
    final lift = wave * 5;
    final opacity = 0.34 + (wave * 0.66);

    return Padding(
      padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
      child: Transform.translate(
        offset: Offset(0, -lift),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF7B756D),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.statusLabel,
    required this.connectionStatus,
    required this.avatarName,
    required this.avatarUrl,
    required this.presenceColor,
    required this.showBack,
    this.onProfileTap,
    this.onBack,
  });

  final String title;
  final String statusLabel;
  final ChatConnectionStatus connectionStatus;
  final String avatarName;
  final String? avatarUrl;
  final Color? presenceColor;
  final bool showBack;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        UserAvatar(label: avatarName, imageUrl: avatarUrl, onTap: onProfileTap),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: onProfileTap,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (presenceColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: presenceColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _connectionLabel(context, statusLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _connectionLabel(BuildContext context, String fallbackStatus) {
    return switch (connectionStatus) {
      ChatConnectionStatus.connecting => context.l10n.connecting,
      ChatConnectionStatus.reconnecting => context.l10n.reconnecting,
      ChatConnectionStatus.failed => context.l10n.liveUpdatesUnavailable,
      ChatConnectionStatus.connected => fallbackStatus,
      ChatConnectionStatus.disconnected => fallbackStatus,
    };
  }
}

class _RequestAccessPanel extends StatelessWidget {
  const _RequestAccessPanel({
    required this.sharedProducts,
    required this.selectedProductId,
    required this.selectedProduct,
    required this.selectedRequest,
    required this.accesses,
    required this.currentUserId,
    required this.otherUserId,
    required this.isLoading,
    required this.isUpdating,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onSelectProduct,
    required this.onRequestAccess,
    required this.onApproveAccess,
    required this.onRejectAccess,
  });

  final List<PartRequestBrief> sharedProducts;
  final int? selectedProductId;
  final PartRequestBrief selectedProduct;
  final PartRequest? selectedRequest;
  final List<PartRequestAccess> accesses;
  final int currentUserId;
  final int? otherUserId;
  final bool isLoading;
  final bool isUpdating;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onSelectProduct;
  final Future<void> Function() onRequestAccess;
  final Future<void> Function(PartRequestAccess access) onApproveAccess;
  final Future<void> Function(PartRequestAccess access) onRejectAccess;

  @override
  Widget build(BuildContext context) {
    final request = selectedRequest;
    final statusLabel =
        request?.statusDetails?.label ?? selectedProduct.statusDetails?.label;
    final isOwner = request?.isOwner ?? false;
    final hasManageAccess = request?.canUpdateStatus == true;

    PartRequestAccess? myAccess;
    PartRequestAccess? acceptedAccess;
    PartRequestAccess? pendingOtherAccess;
    for (final access in accesses) {
      if (access.user == currentUserId) {
        myAccess = access;
      }
      if (access.isAccepted && acceptedAccess == null) {
        acceptedAccess = access;
      }
      if (otherUserId != null &&
          access.user == otherUserId &&
          access.isPending &&
          pendingOtherAccess == null) {
        pendingOtherAccess = access;
      }
    }

    final infoText = switch ((
      isOwner,
      myAccess?.status,
      acceptedAccess?.user,
    )) {
      (true, _, final acceptedUserId?) when acceptedUserId == otherUserId =>
        context.l10n.thisChatCanManageRequestStatus,
      (true, _, final acceptedUserId?) when acceptedUserId != otherUserId =>
        context.l10n.thisRequestIsAssignedToAnotherSupplier,
      (true, _, _) => context.l10n.noAccessRequestForThisRequestYet,
      (false, 'accepted', _) => context.l10n.youCanChangeThisRequestStatusNow,
      (false, 'pending', _) => context.l10n.waitingForOwnerApproval,
      (false, 'rejected', _) => context.l10n.ownerRejectedYourAccessRequest,
      _ => context.l10n.askOwnerForStatusAccess,
    };
    final pendingAccessForOther = pendingOtherAccess;
    final toggleTooltip = isExpanded
        ? context.l10n.collapseRequestControl
        : context.l10n.expandRequestControl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0D7CA)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.requestControl,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedProduct.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF0C4A63),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: toggleTooltip,
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ],
            ),
            if (statusLabel != null && statusLabel.trim().isNotEmpty) ...[
              // const SizedBox(height: 10),
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 10,
              //     vertical: 6,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE3EEF1),
              //     borderRadius: BorderRadius.circular(999),
              //   ),
              //   child: Text(
              //     statusLabel,
              //     style: Theme.of(context).textTheme.labelLarge?.copyWith(
              //       color: const Color(0xFF0C4A63),
              //       fontWeight: FontWeight.w800,
              //     ),
              //   ),
              // ),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              if (sharedProducts.length > 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final product in sharedProducts)
                      ChoiceChip(
                        label: Text(product.displayTitle),
                        selected: product.id == selectedProductId,
                        onSelected: (_) => onSelectProduct(product.id),
                      ),
                  ],
                ),
              if (sharedProducts.length > 1) const SizedBox(height: 12),
              if (isLoading && request == null)
                const LinearProgressIndicator()
              else
                Text(
                  infoText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F6A63),
                    height: 1.35,
                  ),
                ),
              if (request?.grantedUser != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.currentManager(request!.grantedUser!.name),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0C4A63),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (isOwner && pendingAccessForOther != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => onApproveAccess(pendingAccessForOther),
                      icon: Icon(
                        isUpdating
                            ? Icons.hourglass_top_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      label: Text(
                        isUpdating
                            ? context.l10n.approving
                            : context.l10n.approveAccess,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => onRejectAccess(pendingAccessForOther),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(context.l10n.rejectAccess),
                    ),
                  ],
                )
              else if (!isOwner &&
                  !hasManageAccess &&
                  myAccess?.status != 'pending')
                FilledButton.tonalIcon(
                  onPressed: isUpdating ? null : onRequestAccess,
                  icon: Icon(
                    isUpdating
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_open_rounded,
                  ),
                  label: Text(
                    isUpdating
                        ? context.l10n.sendingRequest
                        : context.l10n.requestAccess,
                  ),
                )
              else if (!isOwner && myAccess?.status == 'pending')
                Text(
                  context.l10n.accessRequestPending,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8A5A1F),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (!isOwner && hasManageAccess)
                Text(
                  context.l10n.openAssignedRequestsToUpdateStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0C4A63),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
