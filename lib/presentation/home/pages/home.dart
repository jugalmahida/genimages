import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:genimages/presentation/home/bloc/image_bloc.dart';
import 'package:genimages/presentation/home/bloc/image_state.dart';
import 'package:genimages/presentation/home/bloc/image_event.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _shareImage() async {
    if (_imageBytes == null) return;

    try {
      // Method 1: Direct sharing using XFile.fromData (recommended for WhatsApp)
      await Share.shareXFiles([
        XFile.fromData(
          _imageBytes!,
          name: 'generated_image_${DateTime.now().millisecondsSinceEpoch}.png',
          mimeType: 'image/png',
        ),
      ], text: 'Check out this AI-generated image!');
    } catch (e) {
      // Fallback method if direct sharing fails
      try {
        await _shareImageFallback();
      } catch (fallbackError) {
        print('Sharing error: $e, Fallback error: $fallbackError');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Sharing failed. Please try saving the image and sharing manually.")),
        );
      }
    }
  }

  Future<void> _shareImageFallback() async {
    if (_imageBytes == null) return;

    // Use external storage cache directory for better compatibility
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage not available');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/generated_image_$timestamp.png';

    final file = File(filePath);
    await file.writeAsBytes(_imageBytes!);

    // Verify file exists and has proper permissions
    if (await file.exists()) {
      final stat = await file.stat();
      print('File size: ${stat.size} bytes'); // Debug info

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], text: 'Check out this AI-generated image!');

      // Clean up the file after sharing (optional)
      // file.delete();
    } else {
      throw Exception('Failed to create shareable file');
    }
  }

  Future<void> _downloadImage() async {
    if (_imageBytes == null) return;

    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _imageBytes!,
        quality: 100,
        name: 'generated_image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save image: ${result['errorMessage'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('Download error: $e'); // Add logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("GenImages"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Text(
                "Describe your image",
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  controller: _promptController,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Describe your desired image...",
                    fillColor: theme.colorScheme.surfaceVariant,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 18),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text(
                    "Generate Image",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  onPressed: () {
                    final prompt = _promptController.text.trim();
                    if (prompt.isNotEmpty) {
                      context.read<ImageBloc>().add(GenerateImageEvent(prompt));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a prompt")),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 22),
              Flexible(
                child: BlocBuilder<ImageBloc, ImageState>(
                  builder: (context, state) {
                    switch (state.runtimeType) {
                      case ImageInitial:
                        return _buildTip(theme,
                            "Describe a scene to get started. For best results, be specific about details, lighting, and style.");
                      case ImageLoading:
                        return _buildSkeletonLoader();
                      case ImageSuccess:
                        final successState = state as ImageSuccess;
                        _imageBytes = base64Decode(successState.base64);
                        return _buildInteractiveImage(theme, _imageBytes!);
                      case ImageFailure:
                        final failureState = state as ImageFailure;
                        return _buildError(theme, failureState.error);
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _shareImage,
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _downloadImage,
                      icon: const Icon(Icons.download),
                      label: const Text("Download"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(ThemeData theme, String tip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          tip,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveImage(ThemeData theme, Uint8List bytes) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.16),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
              height: MediaQuery.of(context).size.width * 0.85,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Text(
          'Error: $error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
