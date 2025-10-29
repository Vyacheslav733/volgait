import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/models/photo_model.dart';

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;

  const PhotoGrid({super.key, required this.photos});

  Widget _buildImageWidget(Photo photo) {
    if (photo.path.startsWith('assets/')) {
      return Image.asset(
        photo.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderWidget();
        },
      );
    } else {
      return Image.file(
        File(photo.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderWidget();
        },
      );
    }
  }

  Widget _buildPlaceholderWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.photo, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/photo',
              arguments: photo.id,
            );
          },
          child: Stack(
            children: [
              _buildImageWidget(photo),
              if (!photo.hasGeolocation)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.location_off,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
