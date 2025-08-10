import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Only import dart:io for non-web platforms
import 'dart:io' show File;

class PickImagePage extends StatefulWidget {
  const PickImagePage({super.key});

  @override
  State<PickImagePage> createState() => _PickImagePageState();
}

class _PickImagePageState extends State<PickImagePage> {
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isOriginalImage = true; // Track if image has been converted

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isOriginalImage = true;
        if (!kIsWeb) {
          _selectedImageFile = File(image.path);
        }
      });
    }
  }

  // New method to convert any image format to JPG
  Future<Uint8List> _convertToJpg(Uint8List imageBytes) async {
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

  Future<void> _removeBackground() async {
    BuildContext? dialogContext;

    final startTime = DateTime.now();
    print('[BG_REMOVAL] START: ${startTime.toIso8601String()}');
    print('[BG_REMOVAL] Image size: ${_selectedImageBytes?.length ?? 0} bytes');

    try {
      // Only show dialog if widget is still mounted
      if (mounted) {
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

      if (_selectedImageBytes != null) {
        // Convert image to JPG if it's the original image
        Uint8List imageBytes = _selectedImageBytes!;
        if (_isOriginalImage) {
          imageBytes = await _convertToJpg(_selectedImageBytes!);
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

        if (response.statusCode == 200 && mounted) {
          print('[BG_REMOVAL] Request successful, updating UI with new image');
          setState(() {
            _selectedImageBytes = response.bodyBytes;
            _selectedImageFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Background removed successfully!")),
          );
        } else if (mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("No image selected.")));
        }
        return;
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 5)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remove Background"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade600, Colors.red],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: _selectedImageBytes == null
                        ? _buildUploadArea()
                        : _buildImagePreview(),
                  ),
                ),
                if (_selectedImageBytes != null) _buildProcessButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 80,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 20),
          Text(
            "Upload an Image",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Choose from gallery or take a photo",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUploadButton(
                icon: Icons.photo_library,
                label: "Gallery",
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.redAccent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.memory(
              _selectedImageBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageFile = null;
                    _selectedImageBytes = null;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: _removeBackground,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        child: Text(
          "Remove Background",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
