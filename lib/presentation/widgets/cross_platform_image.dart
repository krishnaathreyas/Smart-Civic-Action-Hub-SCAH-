// presentation/widgets/cross_platform_image.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CrossPlatformImage extends StatelessWidget {
  final XFile imageFile;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CrossPlatformImage({
    super.key,
    required this.imageFile,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit ?? BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          } else {
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else {
      return Image.file(
        File(imageFile.path),
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
      );
    }
  }
}
