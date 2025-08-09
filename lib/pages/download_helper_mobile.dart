import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename) {
  // Mobile platforms don't support web-style downloads
  // This will be handled differently via ImageGallerySaver
  throw UnsupportedError('Web-style downloads not supported on mobile');
}
