import 'dart:typed_data';
import 'download_helper_mobile.dart'
    if (dart.library.html) 'download_helper_web.dart';

void downloadImageFile(Uint8List bytes, String filename) {
  downloadImage(bytes, filename);
}
