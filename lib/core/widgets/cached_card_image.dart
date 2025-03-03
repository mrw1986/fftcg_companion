import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/flipping_card_image.dart';

class CardImageCacheManager {
  static const key = 'cardImageCache';
  static const maxMemCacheSize = 100 * 1024 * 1024; // 100MB
  static const maxAgeCacheObject = Duration(days: 60);
  static const maxNrOfCacheObjects = 2000;
  static const maxDiskCacheSize = 500 * 1024 * 1024; // 500MB

  static CacheManager? _instance;
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: maxAgeCacheObject,
        maxNrOfCacheObjects: maxNrOfCacheObjects,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileSystem: IOFileSystem(key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  // Track which images have already been animated
  static final _animatedImages = <String>{};
  static final _loadedImages = <String>{};

  static bool hasBeenAnimated(String url) => _animatedImages.contains(url);
  static bool isImageLoaded(String url) => _loadedImages.contains(url);
  static void markAsAnimated(String url) => _animatedImages.add(url);
  static void markAsLoaded(String url) => _loadedImages.add(url);

  static void initCache() {
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxMemCacheSize;
    _animatedImages.clear();
    _loadedImages.clear();
  }

  static Future<void> cleanCache() async {
    await instance.emptyCache();
    _animatedImages.clear();
    _loadedImages.clear();
  }
}

class CachedCardImage extends StatefulWidget {
  final String? imageUrl;
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
    _isLoaded = widget.imageUrl != null &&
        CardImageCacheManager.isImageLoaded(widget.imageUrl!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: _buildNetworkImage(context),
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    // Validate URL
    if (widget.imageUrl == null ||
        widget.imageUrl!.isEmpty ||
        !Uri.parse(widget.imageUrl!).hasAuthority) {
      widget.onImageError?.call();
      return widget.errorWidget ?? _buildErrorWidget(context);
    }

    if (!widget.useProgressiveLoading) {
      return _buildCachedImage(context);
    }

    return FutureBuilder<bool>(
      future: CardImageUtils.isImageCached(widget.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildCachedImage(context);
        }

        final lowQualityUrl = widget.imageUrl!.contains('_in_1000x1000.jpg')
            ? widget.imageUrl!.replaceAll('_in_1000x1000.jpg', '_400w.jpg')
            : widget.imageUrl!.replaceAll('.jpg', '_400w.jpg');

        return CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          cacheManager: CardImageCacheManager.instance,
          cacheKey: Uri.parse(widget.imageUrl!).path,
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

    // Validate URL
    if (targetUrl == null ||
        targetUrl.isEmpty ||
        !Uri.parse(targetUrl).hasAuthority) {
      widget.onImageError?.call();
      return widget.errorWidget ?? _buildErrorWidget(context);
    }

    return CachedNetworkImage(
      key: ValueKey(targetUrl),
      imageUrl: targetUrl,
      cacheManager: CardImageCacheManager.instance,
      // Use base URL as cache key to share cached images between views
      cacheKey: Uri.parse(targetUrl).path,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      // Let Flutter handle resizing internally
      memCacheWidth: null,
      memCacheHeight: null,
      maxWidthDiskCache: null,
      maxHeightDiskCache: null,
      fadeInDuration:
          const Duration(milliseconds: 0), // Completely remove fade-in effect
      fadeOutDuration:
          const Duration(milliseconds: 0), // Completely remove fade-out effect
      placeholderFadeInDuration:
          const Duration(milliseconds: 0), // Remove placeholder fade-in
      fadeInCurve: Curves.linear, // Use linear curve for no visible fade effect
      fadeOutCurve:
          Curves.linear, // Use linear curve for no visible fade effect
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
          return imageWidget;
        }

        // Mark this URL as animated before starting the animation
        CardImageCacheManager.markAsAnimated(targetUrl);

        return FlippingCardImage(
          key: ValueKey('flip_$targetUrl'),
          frontWidget: Image.asset(
            'assets/images/card-back.jpeg',
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          ),
          backWidget: imageWidget,
          duration: const Duration(milliseconds: 500),
          borderRadius: widget.borderRadius,
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
  static Future<bool> isImageCached(String? url) async {
    if (url == null || url.isEmpty || !Uri.parse(url).hasAuthority) {
      return false;
    }
    final file = await CardImageCacheManager.instance.getFileFromCache(url);
    return file != null;
  }

  static Future<void> prefetchImage(String? url) async {
    if (url == null || url.isEmpty || !Uri.parse(url).hasAuthority) {
      talker.error('Invalid image URL: $url');
      return;
    }

    try {
      await CardImageCacheManager.instance.downloadFile(url);
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
