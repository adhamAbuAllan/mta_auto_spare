import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.imageProvider,
    this.radius = 22,
    this.backgroundColor = const Color(0xFFD7E9E4),
    this.foregroundColor = const Color(0xFF1E5E33),
    this.presenceColor,
    this.onTap,
  });

  final String label;
  final String? imageUrl;
  final ImageProvider<Object>? imageProvider;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? presenceColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    final resolvedImageProvider = imageProvider ?? _networkImageProvider();

    final avatar = SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              backgroundImage: resolvedImageProvider,
              child: resolvedImageProvider == null
                  ? Text(
                      initial,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    )
                  : null,
            ),
          ),
          if (presenceColor != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: radius < 18 ? 10 : 12,
                height: radius < 18 ? 10 : 12,
                decoration: BoxDecoration(
                  color: presenceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }

  ImageProvider<Object>? _networkImageProvider() {
    final trimmedImageUrl = imageUrl?.trim() ?? '';
    if (trimmedImageUrl.isEmpty) {
      return null;
    }
    return NetworkImage(
      ApiConstants.resolveUrl(trimmedImageUrl),
      headers: const {
        ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
      },
    );
  }
}
