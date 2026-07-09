import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../models/models.dart';

class CarModelCard extends StatelessWidget {
  const CarModelCard({
    super.key,
    required this.carModel,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
    this.compact = false,
  });

  final CarModelOption carModel;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = compact
        ? _CompactCarModelCard(
            carModel: carModel,
            isSelected: isSelected,
            onRemove: onRemove,
          )
        : _FullCarModelCard(
            carModel: carModel,
            isSelected: isSelected,
            onRemove: onRemove,
          );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _FullCarModelCard extends StatelessWidget {
  const _FullCarModelCard({
    required this.carModel,
    required this.isSelected,
    required this.onRemove,
  });

  final CarModelOption carModel;
  final bool isSelected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFE5DED1),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x16116466),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(21),
                      ),
                      child: _CarModelImage(
                        imageUrl: carModel.imageUrl,
                        height: constraints.maxHeight,
                        width: double.infinity,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration:  BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (onRemove != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.18),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onRemove,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  carModel.makeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF0C4A63),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  carModel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1B18),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCarModelCard extends StatelessWidget {
  const _CompactCarModelCard({
    required this.carModel,
    required this.isSelected,
    required this.onRemove,
  });

  final CarModelOption carModel;
  final bool isSelected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEAF0FE) : const Color(0xFFFBF8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFE7DFD2),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(17),
            ),
            child: _CarModelImage(
              imageUrl: carModel.imageUrl,
              width: 92,
              height: 72,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carModel.makeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF0C4A63),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    carModel.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            )
          else if (isSelected)
             Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CarModelImage extends StatelessWidget {
  const _CarModelImage({
    required this.imageUrl,
    required this.height,
    required this.width,
  });

  final String? imageUrl;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = ApiConstants.resolveUrl(imageUrl ?? '');
    if (normalizedUrl.trim().isEmpty) {
      return _CarImagePlaceholder(height: height, width: width);
    }

    return Image.network(
      normalizedUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      headers: const {
        ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
      },
      errorBuilder: (context, error, stackTrace) {
        return _CarImagePlaceholder(height: height, width: width);
      },
    );
  }
}

class _CarImagePlaceholder extends StatelessWidget {
  const _CarImagePlaceholder({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8ECE3), Color(0xFFD9E5E2), Color(0xFFF3EFE7)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 34,
        color: Color(0xFF6A7A7A),
      ),
    );
  }
}
