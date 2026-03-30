import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.radius = 22,
    this.backgroundColor = const Color(0xFFD7E9E4),
    this.foregroundColor = const Color(0xFF0C4A63),
    this.presenceColor,
  });

  final String label;
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? presenceColor;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();

    return SizedBox(
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
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: imageUrl == null || imageUrl!.isEmpty
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
  }
}
