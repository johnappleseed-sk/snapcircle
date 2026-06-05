import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  const ImageCompressor();

  Future<File> compressAvatar(File file) {
    return _compress(file, maxWidth: 512, quality: 82, label: 'avatar');
  }

  Future<File> compressPostImage(File file) {
    return _compress(file, maxWidth: 1280, quality: 82, label: 'post');
  }

  Future<File> compressCoverImage(File file) {
    return _compress(file, maxWidth: 1600, quality: 82, label: 'cover');
  }

  Future<File> compressStoryImage(File file) {
    return _compress(file, maxWidth: 1080, quality: 80, label: 'story');
  }

  Future<File> _compress(
    File file, {
    required int maxWidth,
    required int quality,
    required String label,
  }) async {
    if (kIsWeb || !await file.exists()) {
      return file;
    }

    try {
      final targetPath =
          '${file.parent.path}/snapcircle_${label}_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        return file;
      }

      final compressedFile = File(compressed.path);
      if (!await compressedFile.exists()) {
        return file;
      }

      return compressedFile;
    } catch (_) {
      return file;
    }
  }
}
