// test/mocks/network_image_mock.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

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
    return OneFrameImageStreamCompleter(_createMockImageInfo());
  }

  Future<ImageInfo> _createMockImageInfo() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint());
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    return ImageInfo(image: image, scale: 1.0);
  }
}
