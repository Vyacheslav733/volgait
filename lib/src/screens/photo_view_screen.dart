import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/src/services/photo_provider.dart';
import 'package:flutter_application_1/src/models/photo_model.dart';
import 'package:flutter_application_1/src/screens/crop_photo_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openPhotoInExternalApp(
      BuildContext context, Photo photo) async {
    final messenger = ScaffoldMessenger.of(context);

    if (photo.path.startsWith('assets/')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Невозможно открыть asset-изображение во внешнем приложении'),
        ),
      );
      return;
    }

    try {
      final file = File(photo.path);
      if (!await file.exists()) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
        return;
      }

      final success = await launchUrl(
        Uri.file(file.absolute.path),
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Не удалось открыть файл. Проверьте наличие приложений для просмотра изображений.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка открытия: $e')),
      );
      debugPrint('Error opening file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String photoId = ModalRoute.of(context)!.settings.arguments as String;
    final Photo? photo = context.watch<PhotoProvider>().getPhotoById(photoId);

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
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Переименовать',
            onPressed: () async {
              final controller = TextEditingController(text: photo.title ?? '');
              final provider = context.read<PhotoProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final newTitle = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Название фотографии'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration:
                        const InputDecoration(hintText: 'Введите название'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              );
              if (newTitle != null) {
                provider.updatePhoto(photo.id, title: newTitle);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Название обновлено')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop),
            tooltip: 'Обрезать',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CropPhotoScreen(photoId: photo.id),
                ),
              );
              if (changed == true) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Фото обрезано')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Открыть в другом приложении',
            onPressed: () => _openPhotoInExternalApp(context, photo),
          ),
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
              transformationController: TransformationController(),
              minScale: 0.1,
              maxScale: 10,
              boundaryMargin: EdgeInsets.zero,
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
