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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: Icon(Icons.photo_outlined, color: Colors.grey.shade400, size: 32),
    );
  }

  void _openPhoto(BuildContext context, Photo photo) {
    Navigator.of(context).pushNamed(
      '/photo',
      arguments: photo.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => _openPhoto(context, photo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Hero(
                      tag: photo.id,
                      child: _buildImageWidget(photo),
                    ),
                    if (!photo.hasGeolocation)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openPhoto(context, photo),
                          splashColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          highlightColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: photos.length,
      ),
    );
  }
}
