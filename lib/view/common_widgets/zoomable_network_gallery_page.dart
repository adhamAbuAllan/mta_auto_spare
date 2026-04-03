import 'package:flutter/material.dart';

class ZoomableNetworkGalleryPage extends StatefulWidget {
  const ZoomableNetworkGalleryPage({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.headers,
    this.heroTagBuilder,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final Map<String, String>? headers;
  final Object? Function(int index)? heroTagBuilder;

  @override
  State<ZoomableNetworkGalleryPage> createState() =>
      _ZoomableNetworkGalleryPageState();
}

class _ZoomableNetworkGalleryPageState
    extends State<ZoomableNetworkGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isCurrentImageZoomed = false;

  @override
  void initState() {
    super.initState();
    final lastIndex = widget.imageUrls.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, lastIndex);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091015),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: _isCurrentImageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                if (_currentIndex == index) {
                  return;
                }
                setState(() {
                  _currentIndex = index;
                  _isCurrentImageZoomed = false;
                });
              },
              itemBuilder: (context, index) {
                return _ZoomableGalleryImage(
                  key: ValueKey('zoomable-gallery-image-$index'),
                  imageUrl: widget.imageUrls[index],
                  headers: widget.headers,
                  heroTag: widget.heroTagBuilder?.call(index),
                  isActive: index == _currentIndex,
                  onZoomChanged: (isZoomed) {
                    if (!mounted ||
                        index != _currentIndex ||
                        _isCurrentImageZoomed == isZoomed) {
                      return;
                    }
                    setState(() => _isCurrentImageZoomed = isZoomed);
                  },
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('zoomable-image-viewer-close'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.34),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Text(
                _isCurrentImageZoomed
                    ? 'Double tap to return to the full image.'
                    : 'Double tap to zoom in. Pinch to zoom and drag to explore.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableGalleryImage extends StatefulWidget {
  const _ZoomableGalleryImage({
    super.key,
    required this.imageUrl,
    required this.isActive,
    required this.onZoomChanged,
    this.headers,
    this.heroTag,
  });

  final String imageUrl;
  final Map<String, String>? headers;
  final Object? heroTag;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableGalleryImage> createState() => _ZoomableGalleryImageState();
}

class _ZoomableGalleryImageState extends State<_ZoomableGalleryImage>
    with SingleTickerProviderStateMixin {
  static const double _zoomScale = 2.6;
  static const double _zoomEpsilon = 0.01;

  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _matrixAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_handleTransformationChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final nextMatrix = _matrixAnimation?.value;
        if (nextMatrix != null) {
          _transformationController.value = nextMatrix;
        }
      });
  }

  @override
  void didUpdateWidget(covariant _ZoomableGalleryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive && _isZoomed) {
      _setMatrix(Matrix4.identity(), animate: false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.removeListener(_handleTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget image = Image.network(
          widget.imageUrl,
          headers: widget.headers,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white70,
                size: 34,
              ),
            );
          },
        );

        if (widget.heroTag != null) {
          image = Hero(tag: widget.heroTag!, child: image);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: () => _handleDoubleTap(constraints.biggest),
          child: InteractiveViewer(
            key: const ValueKey('zoomable-image-viewer-interactive'),
            transformationController: _transformationController,
            minScale: 1,
            maxScale: 4,
            clipBehavior: Clip.none,
            boundaryMargin: const EdgeInsets.all(80),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(child: image),
            ),
          ),
        );
      },
    );
  }

  void _handleTransformationChanged() {
    final nextZoomed =
        _transformationController.value.getMaxScaleOnAxis() > 1 + _zoomEpsilon;
    if (_isZoomed == nextZoomed) {
      return;
    }
    _isZoomed = nextZoomed;
    widget.onZoomChanged(nextZoomed);
  }

  void _handleDoubleTap(Size viewportSize) {
    if (_isZoomed) {
      _setMatrix(Matrix4.identity());
      return;
    }

    final details = _doubleTapDetails;
    if (details == null) {
      _setMatrix(
        Matrix4.identity()..scaleByDouble(_zoomScale, _zoomScale, 1, 1),
      );
      return;
    }

    final tapPosition = details.localPosition;
    final translatedX = (viewportSize.width / 2 - tapPosition.dx) * _zoomScale;
    final translatedY =
        (viewportSize.height / 2 - tapPosition.dy) * _zoomScale;
    final nextMatrix = Matrix4.identity()
      ..translateByDouble(translatedX, translatedY, 0, 1)
      ..scaleByDouble(_zoomScale, _zoomScale, 1, 1);
    _setMatrix(nextMatrix);
  }

  void _setMatrix(Matrix4 target, {bool animate = true}) {
    _animationController.stop();
    if (!animate) {
      _transformationController.value = target;
      return;
    }

    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController
      ..reset()
      ..forward();
  }
}
