// lib/core/widgets/cached_card_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class CardImageCacheManager {
  static const key = 'cardImageCache';
  static const maxMemCacheSize = 50 * 1024 * 1024; // 50MB
  static const maxCacheObjects = 500;

  static final instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: maxCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );

  static void initCache() {
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxMemCacheSize;
    PaintingBinding.instance.imageCache.clear();
  }
}

class CachedCardImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildNetworkImage(context),
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    if (!useProgressiveLoading) {
      return _buildCachedImage(context);
    }

    return FutureBuilder<bool>(
      future: CardImageUtils.isImageCached(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildCachedImage(context);
        }

        final lowQualityUrl = imageUrl.contains('_in_1000x1000.jpg')
            ? imageUrl.replaceAll('_in_1000x1000.jpg', '_400w.jpg')
            : imageUrl.replaceAll('.jpg', '_400w.jpg');

        return CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: CardImageCacheManager.instance,
          progressIndicatorBuilder: (context, url, progress) {
            return _buildCachedImage(context, imageUrl: lowQualityUrl);
          },
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
              ),
              borderRadius: borderRadius,
            ),
          ),
          errorWidget: (context, url, error) {
            talker.error('Failed to load image: $url', error);
            onImageError?.call();
            return errorWidget ?? _buildErrorWidget(context);
          },
        );
      },
    );
  }

  Widget _buildCachedImage(BuildContext context, {String? imageUrl}) {
    final targetUrl = imageUrl ?? this.imageUrl;

    // Calculate optimal cache dimensions based on device pixel ratio
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Safely calculate target dimensions, handling null, infinity, and NaN cases
    int? safeTargetWidth;
    int? safeTargetHeight;

    if (width != null && width!.isFinite && !width!.isNaN && width! > 0) {
      final targetWidth = (width! * pixelRatio).toInt();
      safeTargetWidth = targetWidth.clamp(1, 4096); // Max texture size 4096
    }

    if (height != null && height!.isFinite && !height!.isNaN && height! > 0) {
      final targetHeight = (height! * pixelRatio).toInt();
      safeTargetHeight = targetHeight.clamp(1, 4096);
    }

    return CachedNetworkImage(
      imageUrl: targetUrl,
      cacheManager: CardImageCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      // Only use cache dimensions if they're valid
      memCacheWidth: safeTargetWidth,
      memCacheHeight: safeTargetHeight,
      maxWidthDiskCache: safeTargetWidth,
      maxHeightDiskCache: safeTargetHeight,
      cacheKey: Uri.parse(targetUrl).pathSegments.last,
      // Skip fade animation for cached images
      fadeInDuration: const Duration(milliseconds: 0),
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: fit,
          ),
          borderRadius: borderRadius,
        ),
      ),
      placeholder: (context, url) =>
          placeholder ?? _buildDefaultPlaceholder(context),
      errorWidget: (context, url, error) {
        talker.error('Failed to load image: $url', error);
        onImageError?.call();
        return errorWidget ?? _buildErrorWidget(context);
      },
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
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
    );
  }

  static Future<void> precacheImage(BuildContext context, String url) async {
    try {
      final provider = CachedNetworkImageProvider(
        url,
        cacheManager: CardImageCacheManager.instance,
      );
      provider.resolve(ImageConfiguration.empty);
    } catch (e, stack) {
      talker.error('Error precaching image: $url', e, stack);
    }
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
