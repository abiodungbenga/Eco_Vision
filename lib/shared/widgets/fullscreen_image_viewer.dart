import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';

class FullscreenImageViewer {
  const FullscreenImageViewer._();

  static Future<void> show(BuildContext context, String? imageUrl) async {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return;

    final ImageProvider provider = url.startsWith('http')
        ? NetworkImage(url)
        : FileImage(File(url));

    await showImageViewer(
      context,
      provider,
      immersive: true,
      swipeDismissible: true,
      doubleTapZoomable: true,
      backgroundColor: Colors.black,
    );
  }
}
