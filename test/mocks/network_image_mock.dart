import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MockNetworkImageProvider extends ImageProvider<MockNetworkImageProvider> {
  final String url;

  const MockNetworkImageProvider(this.url);

  @override
  Future<MockNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MockNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    MockNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadAsync());
  }

  Future<ImageInfo> _loadAsync() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    return ImageInfo(image: image, scale: 1.0);
  }

  @override
  String toString() => 'MockNetworkImageProvider("$url")';
}
