// lib/core/widgets/cached_card_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CardImageCacheManager {
  static const key = 'cardImageCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}

class CachedCardImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool animate;

  const CachedCardImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: CardImageCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      progressIndicatorBuilder: (context, url, progress) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image),
      ),
    );

    return animate
        ? image.animate().fade().scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
            )
        : image;
  }
}
