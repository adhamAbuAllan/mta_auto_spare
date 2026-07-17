import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    this.label,
    this.imageUrl,
    this.imageProvider,
    this.radius = 22,
    this.backgroundColor = const Color(0xFFD7E9E4),
    this.foregroundColor = const Color(0xFF1E5E33),
    this.presenceColor,
    this.onTap,
  });

  final String? label;
  final String? imageUrl;
  final ImageProvider<Object>? imageProvider;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? presenceColor;
  final VoidCallback? onTap;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  Widget build(BuildContext context) {
    final initial = widget.label?.trim()[0].toUpperCase() ?? "?";
    final resolvedImageProvider =
        widget.imageProvider ?? _networkImageProvider(context);

    final avatar = SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              backgroundImage: resolvedImageProvider,
              child: resolvedImageProvider == null
                  ? Text(
                      initial,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: widget.foregroundColor,
                      ),
                    )
                  : null,
            ),
          ),
          if (widget.presenceColor != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: widget.radius < 18 ? 10 : 12,
                height: widget.radius < 18 ? 10 : 12,
                decoration: BoxDecoration(
                  color: widget.presenceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }

  ImageProvider<Object>? _networkImageProvider(BuildContext context) {
    final trimmedImageUrl = widget.imageUrl?.trim() ?? '';
    if (trimmedImageUrl.isEmpty) {
      return null;
    }
    final diameter =
        (widget.radius * 2 * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ResizeImage(
      NetworkImage(
        ApiConstants.resolveUrl(trimmedImageUrl),
        headers: const {
          ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
        },
      ),
      width: diameter,
      height: diameter,
    );
  }
}
