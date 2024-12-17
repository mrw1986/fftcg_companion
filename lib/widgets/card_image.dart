import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CardImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final bool isTest;

  const CardImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.isTest = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTest) {
      return Container(
        width: 56,
        height: 56,
        color: Colors.grey,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error),
      ),
    );
  }
}
