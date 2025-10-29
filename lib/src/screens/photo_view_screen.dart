import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/src/services/photo_provider.dart';
import 'package:flutter_application_1/src/models/photo_model.dart';

class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({super.key});

  Widget _buildImageWidget(Photo photo) {
    if (photo.path.startsWith('assets/')) {
      return Image.asset(
        photo.path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Ошибка загрузки изображения'),
              ],
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(photo.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Ошибка загрузки изображения'),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String photoId = ModalRoute.of(context)!.settings.arguments as String;
    final Photo? photo = context.read<PhotoProvider>().getPhotoById(photoId);

    if (photo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Фото не найдено'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Фотография не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр фото'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (photo.hasGeolocation)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/map',
                  arguments: photo.id,
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: _buildImageWidget(photo),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.title != null && photo.title!.isNotEmpty)
                  Text(
                    'Название: ${photo.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (photo.creationDate != null)
                  Text(
                    'Дата: ${photo.creationDate!.toString().split(' ')[0]}',
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      photo.hasGeolocation
                          ? Icons.location_on
                          : Icons.location_off,
                      color: photo.hasGeolocation ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      photo.hasGeolocation
                          ? 'Геолокация доступна'
                          : 'Геолокация отсутствует',
                      style: TextStyle(
                        color: photo.hasGeolocation ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (photo.hasGeolocation)
                  Text(
                    'Координаты: ${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
