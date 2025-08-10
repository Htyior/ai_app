import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageProcessingService {
  // New method to convert any image format to JPG
  static Future<Uint8List> _convertToJpg(Uint8List imageBytes) async {
    print('[IMAGE_CONVERSION] Converting image to JPG format');
    print('[IMAGE_CONVERSION] Original size: ${imageBytes.length} bytes');

    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        format: CompressFormat.jpeg,
        quality: 90, // Adjust quality as needed
      );

      print('[IMAGE_CONVERSION] Converted size: ${result.length} bytes');
      print(
        '[IMAGE_CONVERSION] Conversion ratio: ${(result.length / imageBytes.length * 100).toStringAsFixed(1)}%',
      );
      return result;
    } catch (e) {
      print('[IMAGE_CONVERSION] Error converting image: $e');
      // If conversion fails, return original bytes
      return imageBytes;
    }
  }

  static Future<Uint8List?> removeBackground({
    required BuildContext context,
    required Uint8List? selectedImageBytes,
    required bool isOriginalImage,
  }) async {
    BuildContext? dialogContext;

    final startTime = DateTime.now();
    print('[BG_REMOVAL] START: ${startTime.toIso8601String()}');
    print('[BG_REMOVAL] Image size: ${selectedImageBytes?.length ?? 0} bytes');

    try {
      // Only show dialog if widget is still mounted
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            dialogContext = context;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Processing image..."),
                      Text(
                        "This may take up to 3 minutes",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }

      var uri = Uri.parse('http://152.228.206.178:8000/remove-bg');
      print('[BG_REMOVAL] Preparing request to: $uri');

      // Create a multipart request
      var request = http.MultipartRequest('POST', uri);

      if (selectedImageBytes != null) {
        // Convert image to JPG if it's the original image
        Uint8List imageBytes = selectedImageBytes;
        if (isOriginalImage) {
          imageBytes = await _convertToJpg(selectedImageBytes);
        }

        print(
          '[BG_REMOVAL] Adding JPG image to request (${imageBytes.length} bytes)',
        );

        // Make sure to name the field "file" as expected by the server
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // This field name must match what the server expects
            imageBytes,
            filename: 'image.jpg', // Changed extension to jpg
            contentType: MediaType(
              'image',
              'jpeg',
            ), // Changed content type to jpeg
          ),
        );

        print('[BG_REMOVAL] Sending multipart request to server...');
        final requestSentTime = DateTime.now();

        var streamedResponse = await request.send().timeout(
          Duration(seconds: 180),
          onTimeout: () {
            throw Exception(
              'Server timeout - please try again with a smaller image',
            );
          },
        );

        final responseReceivedTime = DateTime.now();
        final responseLatency = responseReceivedTime.difference(
          requestSentTime,
        );
        print(
          '[BG_REMOVAL] Initial response received after ${responseLatency.inMilliseconds}ms',
        );
        print('[BG_REMOVAL] Response status: ${streamedResponse.statusCode}');
        print('[BG_REMOVAL] Response headers: ${streamedResponse.headers}');

        var response = await http.Response.fromStream(streamedResponse);

        // Close the dialog using dialogContext
        if (dialogContext != null) Navigator.of(dialogContext!).pop();

        // Calculate total time
        final totalTime = DateTime.now().difference(startTime);
        print(
          '[BG_REMOVAL] TOTAL PROCESSING TIME: ${totalTime.inSeconds} seconds',
        );

        if (response.statusCode == 200 && context.mounted) {
          print('[BG_REMOVAL] Request successful, updating UI with new image');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Background removed successfully!")),
          );
          return response.bodyBytes;
        } else if (context.mounted) {
          print('[BG_REMOVAL] Error response: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed: ${response.statusCode} - ${response.reasonPhrase}",
              ),
            ),
          );
        }
      } else {
        // Handle case where no image is selected
        if (dialogContext != null) Navigator.of(dialogContext!).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("No image selected.")));
        }
        return null;
      }
    } catch (e) {
      // Close dialog using dialogContext
      if (dialogContext != null) Navigator.of(dialogContext!).pop();

      // Log error with timing information
      final errorTime = DateTime.now();
      final duration = errorTime.difference(startTime);
      print('[BG_REMOVAL] Exception after ${duration.inSeconds} seconds: $e');

      String errorMessage = "Error: ";
      if (e.toString().contains('timeout')) {
        errorMessage +=
            "Server took too long to respond. Try with a smaller image.";
      } else if (e.toString().contains('SocketException')) {
        errorMessage += "Network connection failed. Check your internet.";
      } else {
        errorMessage += e.toString();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 5)),
        );
      }
    }
    return null;
  }
}
