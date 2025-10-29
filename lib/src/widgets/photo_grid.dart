import 'package:flutter/material.dart';
import '../models/photo_model.dart';

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;

  const PhotoGrid({super.key, required this.photos});

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
              Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
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
