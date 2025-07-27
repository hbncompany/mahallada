// lib/widgets/image_input.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mahallda_app/l10n/app_localizations.dart'; // Import localizations

class ImageInput extends StatefulWidget {
  const ImageInput({
    super.key,
    required this.onPickImages,
    this.existingImageUrls = const [], // Optional: for editing existing items
  });

  final void Function(List<File> images) onPickImages;
  final List<String>
      existingImageUrls; // List of URLs for images already on server

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  final List<File> _selectedImages = [];
  final List<String> _removedImageUrls =
      []; // To track images removed from existing

  void _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickMultiImage(
      imageQuality: 70, // Adjust image quality
      maxWidth: 1500, // Max width for picked images
    );

    if (pickedImage == null || pickedImage.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages
          .addAll(pickedImage.map((xFile) => File(xFile.path)).toList());
    });

    widget.onPickImages(_selectedImages);
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onPickImages(_selectedImages);
  }

  void _removeExistingImage(String url) {
    setState(() {
      _removedImageUrls.add(url);
    });
    // You might want to update the parent widget about removed URLs as well
    // or handle the deletion from server when the form is submitted.
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Filter out existing images that have been marked for removal
    final currentExistingImageUrls = widget.existingImageUrls
        .where((url) => !_removedImageUrls.contains(url))
        .toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(localizations.translate('addImages')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Display existing images
        if (currentExistingImageUrls.isNotEmpty)
          SizedBox(
            height: 100, // Fixed height for image display
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentExistingImageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = currentExistingImageUrls[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(imageUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (currentExistingImageUrls.isNotEmpty && _selectedImages.isNotEmpty)
          const SizedBox(height: 10),
        // Display newly selected images
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100, // Fixed height for image display
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final imageFile = _selectedImages[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFile,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
