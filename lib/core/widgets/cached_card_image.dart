// lib/core/widgets/cached_card_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/flipping_card_image.dart';

class CardImageCacheManager {
  static const key = 'cardImageCache';
  static const maxMemCacheSize = 50 * 1024 * 1024; // 50MB

  static final _instance = DefaultCacheManager();
  static DefaultCacheManager get instance => _instance;

  // Track which images have already been animated
  static final _animatedImages = <String>{};
  static final _loadedImages = <String>{};

  static bool hasBeenAnimated(String url) {
    return _animatedImages.contains(url);
  }

  static bool isImageLoaded(String url) {
    return _loadedImages.contains(url);
  }

  static void markAsAnimated(String url) {
    _animatedImages.add(url);
  }

  static void markAsLoaded(String url) {
    _loadedImages.add(url);
  }

  static void initCache() {
    PaintingBinding.instance.imageCache.maximumSize = 200; // Increased from 50
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxMemCacheSize;
    // Don't clear the cache on init to maintain images across navigation
    // Only clear animation tracking
    _animatedImages.clear();
    _loadedImages.clear();
  }
}

class CachedCardImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool animate;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool useProgressiveLoading;
  final VoidCallback? onImageError;

  const CachedCardImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.animate = true,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.useProgressiveLoading = false,
    this.onImageError,
  });

  @override
  State<CachedCardImage> createState() => _CachedCardImageState();
}

class _CachedCardImageState extends State<CachedCardImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _isLoaded = CardImageCacheManager.isImageLoaded(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: _buildNetworkImage(context),
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    if (!widget.useProgressiveLoading) {
      return _buildCachedImage(context);
    }

    return FutureBuilder<bool>(
      future: CardImageUtils.isImageCached(widget.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildCachedImage(context);
        }

        final lowQualityUrl = widget.imageUrl.contains('_in_1000x1000.jpg')
            ? widget.imageUrl.replaceAll('_in_1000x1000.jpg', '_400w.jpg')
            : widget.imageUrl.replaceAll('.jpg', '_400w.jpg');

        return CachedNetworkImage(
          imageUrl: widget.imageUrl,
          cacheManager: CardImageCacheManager.instance,
          progressIndicatorBuilder: (context, url, progress) {
            return _buildCachedImage(context, imageUrl: lowQualityUrl);
          },
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: widget.fit,
              ),
              borderRadius: widget.borderRadius,
            ),
          ),
          errorWidget: (context, url, error) {
            talker.error('Failed to load image: $url', error);
            widget.onImageError?.call();
            return widget.errorWidget ?? _buildErrorWidget(context);
          },
        );
      },
    );
  }

  Widget _buildCachedImage(BuildContext context, {String? imageUrl}) {
    final targetUrl = imageUrl ?? widget.imageUrl;
    final cacheKey = Uri.parse(targetUrl).pathSegments.last;

    // Calculate optimal cache dimensions based on device pixel ratio
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Safely calculate target dimensions, handling null, infinity, and NaN cases
    int? safeTargetWidth;
    int? safeTargetHeight;

    if (widget.width != null &&
        widget.width!.isFinite &&
        !widget.width!.isNaN &&
        widget.width! > 0) {
      final targetWidth = (widget.width! * pixelRatio).toInt();
      safeTargetWidth = targetWidth.clamp(1, 4096); // Max texture size 4096
    }

    if (widget.height != null &&
        widget.height!.isFinite &&
        !widget.height!.isNaN &&
        widget.height! > 0) {
      final targetHeight = (widget.height! * pixelRatio).toInt();
      safeTargetHeight = targetHeight.clamp(1, 4096);
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        key: ValueKey('cached_$cacheKey'),
        imageUrl: targetUrl,
        cacheManager: CardImageCacheManager.instance,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        memCacheWidth: safeTargetWidth,
        memCacheHeight: safeTargetHeight,
        maxWidthDiskCache: safeTargetWidth,
        maxHeightDiskCache: safeTargetHeight,
        cacheKey: cacheKey,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) {
          if (_isLoaded) {
            return Image.asset(
              'assets/images/card-back.jpeg',
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
            );
          }
          return widget.placeholder ??
              Image.asset(
                'assets/images/card-back.jpeg',
                fit: widget.fit,
                width: widget.width,
                height: widget.height,
              );
        },
        imageBuilder: (context, imageProvider) {
          if (!_isLoaded) {
            _isLoaded = true;
            CardImageCacheManager.markAsLoaded(targetUrl);
            talker.debug(
                'CachedCardImage: Image loaded successfully: $targetUrl');
          }

          // Keep the image in memory cache
          imageProvider.resolve(ImageConfiguration.empty);

          final imageWidget = Image(
            image: imageProvider,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          );

          if (!widget.animate ||
              CardImageCacheManager.hasBeenAnimated(targetUrl)) {
            talker.debug('CachedCardImage: Skipping animation for $targetUrl');
            return imageWidget;
          }

          // Mark this URL as animated before starting the animation
          CardImageCacheManager.markAsAnimated(targetUrl);

          talker.debug('CachedCardImage: Starting flip animation');
          return FlippingCardImage(
            key: ValueKey(cacheKey),
            frontWidget: Image.asset(
              'assets/images/card-back.jpeg',
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
            ),
            backWidget: imageWidget,
            duration: const Duration(milliseconds: 500),
            onAnimationComplete: () {
              CardImageCacheManager.markAsAnimated(targetUrl);
            },
          );
        },
        errorWidget: (context, url, error) {
          talker.error('Failed to load image: $url', error);
          widget.onImageError?.call();
          return widget.errorWidget ?? _buildErrorWidget(context);
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: widget.borderRadius,
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: colorScheme.onErrorContainer,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Image Failed to Load',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardImageUtils {
  static Future<bool> isImageCached(String url) async {
    final fileKey = Uri.parse(url).pathSegments.last;
    final file = await CardImageCacheManager.instance.getFileFromCache(fileKey);
    return file != null;
  }

  static Future<void> prefetchImage(String url) async {
    try {
      await CardImageCacheManager.instance.downloadFile(url);
      talker.debug('Prefetched image: $url');
    } catch (e, stack) {
      talker.error('Error prefetching image: $url', e, stack);
    }
  }

  static Size getAspectRatioSize(double width) {
    const aspectRatio = 223 / 311; // FFTCG card ratio
    final height = width / aspectRatio;
    return Size(width, height);
  }

  static double getHeightForWidth(double width) {
    return width * (311 / 223);
  }

  static double getWidthForHeight(double height) {
    return height * (223 / 311);
  }
}
