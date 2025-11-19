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
          return _buildErrorWidget();
        },
      );
    } else {
      return Image.file(
        File(photo.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade100, Colors.grey.shade300],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotoInExternalApp(
      BuildContext context, Photo photo) async {
    final messenger = ScaffoldMessenger.of(context);

    if (photo.path.startsWith('assets/')) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Невозможно открыть asset-изображение'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final file = File(photo.path);
      if (!await file.exists()) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Файл не найден'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final success = await launchUrl(
        Uri.file(file.absolute.path),
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Не удалось открыть файл'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showRenameDialog(BuildContext context, Photo photo) async {
    final controller = TextEditingController(text: photo.title ?? '');
    final provider = context.read<PhotoProvider>();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(40),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Название фотографии',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Введите название',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final newTitle = controller.text.trim();
                        if (newTitle.isNotEmpty) {
                          provider.updatePhoto(photo.id, title: newTitle);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Название обновлено'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String photoId = ModalRoute.of(context)!.settings.arguments as String;
    final Photo? photo = context.watch<PhotoProvider>().getPhotoById(photoId);

    if (photo == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Фото не найдено',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Фотография не найдена',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 60, bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.background.withOpacity(0.9),
                  Theme.of(context).colorScheme.background.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  'Просмотр фото',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_vert_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Переименовать'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'crop',
                      child: Row(
                        children: [
                          Icon(Icons.crop_rounded,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Обрезать'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Открыть в...'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameDialog(context, photo);
                        break;
                      case 'crop':
                        Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => CropPhotoScreen(photoId: photo.id),
                          ),
                        );
                        break;
                      case 'open':
                        _openPhotoInExternalApp(context, photo);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  transformationController: TransformationController(),
                  minScale: 0.1,
                  maxScale: 10,
                  boundaryMargin: EdgeInsets.zero,
                  child: _buildImageWidget(photo),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.title != null && photo.title!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Название',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photo.title!,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (photo.creationDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дата создания',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photo.creationDate!.toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: photo.hasGeolocation
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: photo.hasGeolocation
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          photo.hasGeolocation
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          size: 20,
                          color: photo.hasGeolocation
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.hasGeolocation
                                  ? 'Геолокация доступна'
                                  : 'Геолокация отсутствует',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: photo.hasGeolocation
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                  ),
                            ),
                            if (photo.hasGeolocation) const SizedBox(height: 2),
                            if (photo.hasGeolocation)
                              Text(
                                '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.7),
                                    ),
                              ),
                          ],
                        ),
                      ),
                      if (photo.hasGeolocation)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.map_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
