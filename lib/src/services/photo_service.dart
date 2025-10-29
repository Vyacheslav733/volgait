import 'dart:io';
import 'dart:math';
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_application_1/src/models/photo_model.dart';

class PhotoService {
  static Future<List<Photo>> getPhotos() async {
    final List<Photo> photos = [];

    try {
      // Получаем путь к домашней директории пользователя
      final Directory homeDir = Directory('/home/user');

      // Ищем папку Pictures в домашней директории
      final Directory picturesDir = Directory('${homeDir.path}/Pictures');

      // Если папки нет, создаем тестовые данные
      if (!await picturesDir.exists()) {
        return _createSamplePhotos();
      }

      // Получаем список файлов в папке Pictures
      final List<FileSystemEntity> files = picturesDir.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File && _isImageFile(file.path)) {
          try {
            final Photo photo = await _createPhotoFromFile(file);
            photos.add(photo);
          } catch (e) {
            // Пропускаем файлы с ошибками
            continue;
          }
        }
      }

      // Если реальных фото нет, добавляем тестовые
      if (photos.isEmpty) {
        photos.addAll(_createSamplePhotos());
      }
    } catch (e) {
      // Возвращаем тестовые данные в случае ошибки
      return _createSamplePhotos();
    }

    return photos;
  }

  static bool _isImageFile(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    return extension == '.jpg' || extension == '.jpeg' || extension == '.png';
  }

  static Future<Photo> _createPhotoFromFile(File file) async {
    double? latitude;
    double? longitude;
    bool hasGeolocation = false;

    try {
      // Читаем EXIF данные с обработкой nullable
      final Map<String?, IfdTag>? exifData = await readExifFromFile(file.path);

      if (exifData != null &&
          exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        final IfdTag? latTag = exifData['GPS GPSLatitude'];
        final IfdTag? lonTag = exifData['GPS GPSLongitude'];

        if (latTag != null && lonTag != null) {
          latitude = _convertGPSCoordinate(latTag);
          longitude = _convertGPSCoordinate(lonTag);

          // Учитываем полушария с проверкой на null
          if (exifData.containsKey('GPS GPSLatitudeRef')) {
            final IfdTag? latRefTag = exifData['GPS GPSLatitudeRef'];
            if (latRefTag != null) {
              final String? latRef = latRefTag.printable;
              if (latRef == 'S') latitude = -latitude;
            }
          }

          if (exifData.containsKey('GPS GPSLongitudeRef')) {
            final IfdTag? lonRefTag = exifData['GPS GPSLongitudeRef'];
            if (lonRefTag != null) {
              final String? lonRef = lonRefTag.printable;
              if (lonRef == 'W') longitude = -longitude;
            }
          }

          hasGeolocation = true;
        }
      }
    } catch (e) {
      // Для некоторых файлов генерируем случайные координаты вокруг Москвы
      if (!hasGeolocation && Random().nextBool()) {
        latitude = 55.7558 + (Random().nextDouble() - 0.5) * 0.1;
        longitude = 37.6173 + (Random().nextDouble() - 0.5) * 0.1;
        hasGeolocation = true;
      }
    }

    final fileStat = await file.stat();
    final photo = Photo(
      id: file.path, // Используем путь как ID
      path: file.path,
      title: path.basename(file.path),
      creationDate: fileStat.modified,
      latitude: latitude,
      longitude: longitude,
      hasGeolocation: hasGeolocation,
    );

    return photo;
  }

  // Создаем тестовые данные для демонстрации
  static List<Photo> _createSamplePhotos() {
    final now = DateTime.now();

    return [
      Photo(
        id: 'sample1',
        path: 'assets/images/sample1.jpg',
        title: 'Ульяновск - Площадь Ленина',
        creationDate: now.subtract(const Duration(days: 10)),
        latitude: 54.314,
        longitude: 48.403,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample2',
        path: 'assets/images/sample2.jpg',
        title: 'Набережная Волги',
        creationDate: now.subtract(const Duration(days: 5)),
        latitude: 54.318,
        longitude: 48.395,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample3',
        path: 'assets/images/sample3.jpg',
        title: 'Музей Гражданской авиации',
        creationDate: now.subtract(const Duration(days: 3)),
        latitude: 54.308,
        longitude: 48.385,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample4',
        path: 'assets/images/sample4.jpg',
        title: 'Фото без геолокации',
        creationDate: now.subtract(const Duration(days: 1)),
        latitude: null,
        longitude: null,
        hasGeolocation: false,
      ),
      Photo(
        id: 'sample5',
        path: 'assets/images/sample1.jpg',
        title: 'Императорский мост',
        creationDate: now.subtract(const Duration(days: 8)),
        latitude: 54.322,
        longitude: 48.410,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample6',
        path: 'assets/images/sample2.jpg',
        title: 'Парк Дружбы народов',
        creationDate: now.subtract(const Duration(days: 6)),
        latitude: 54.320,
        longitude: 48.400,
        hasGeolocation: true,
      ),
    ];
  }

  static double _convertGPSCoordinate(IfdTag tag) {
    try {
      if (tag.values is List) {
        final List<dynamic> values = tag.values as List<dynamic>;
        if (values.length >= 3) {
          final double degrees = _parseGpsValue(values[0]);
          final double minutes = _parseGpsValue(values[1]);
          final double seconds = _parseGpsValue(values[2]);
          return degrees + (minutes / 60.0) + (seconds / 3600.0);
        }
      }
    } catch (e) {
      // В случае ошибки возвращаем 0.0
    }
    return 0.0;
  }

  static double _parseGpsValue(dynamic value) {
    try {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
    } catch (e) {
      // В случае ошибки возвращаем 0.0
    }
    return 0.0;
  }
}
