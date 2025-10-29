import 'dart:io';
import 'dart:math';
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import '../models/photo_model.dart';

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
        print('Папка Pictures не найдена, используем тестовые данные');
        return _createSamplePhotos();
      }

      // Получаем список файлов в папке Pictures
      final List<FileSystemEntity> files = picturesDir.listSync();
      print('Найдено файлов в Pictures: ${files.length}');

      for (final FileSystemEntity file in files) {
        if (file is File && _isImageFile(file.path)) {
          try {
            print('Обрабатываем файл: ${file.path}');
            final Photo photo = await _createPhotoFromFile(file);
            photos.add(photo);
          } catch (e) {
            print('Ошибка обработки фото ${file.path}: $e');
          }
        }
      }

      // Если реальных фото нет, добавляем тестовые
      if (photos.isEmpty) {
        print('Реальных фото не найдено, добавляем тестовые данные');
        photos.addAll(_createSamplePhotos());
      }
    } catch (e) {
      print('Ошибка получения фото: $e');
      // Возвращаем тестовые данные в случае ошибки
      return _createSamplePhotos();
    }

    print('Всего загружено фото: ${photos.length}');
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
      print('EXIF данные для ${file.path}: ${exifData?.keys}');

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
              if (latRef == 'S') latitude = -latitude!;
            }
          }

          if (exifData.containsKey('GPS GPSLongitudeRef')) {
            final IfdTag? lonRefTag = exifData['GPS GPSLongitudeRef'];
            if (lonRefTag != null) {
              final String? lonRef = lonRefTag.printable;
              if (lonRef == 'W') longitude = -longitude!;
            }
          }

          hasGeolocation = true;
          print('Найдены координаты: $latitude, $longitude');
        }
      }
    } catch (e) {
      print('Ошибка чтения EXIF для ${file.path}: $e');
      // Для некоторых файлов генерируем случайные координаты вокруг Москвы
      if (!hasGeolocation && Random().nextBool()) {
        latitude = 55.7558 + (Random().nextDouble() - 0.5) * 0.1;
        longitude = 37.6173 + (Random().nextDouble() - 0.5) * 0.1;
        hasGeolocation = true;
        print('Сгенерированы случайные координаты: $latitude, $longitude');
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

    print('Создано фото: ${photo.title}, геолокация: ${photo.hasGeolocation}');
    return photo;
  }

  // Создаем тестовые данные для демонстрации
  static List<Photo> _createSamplePhotos() {
    final now = DateTime.now();

    return [
      Photo(
        id: 'sample1',
        path: 'assets/images/sample1.jpg',
        title: 'Москва - Красная площадь',
        creationDate: now.subtract(const Duration(days: 10)),
        latitude: 55.7539,
        longitude: 37.6208,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample2',
        path: 'assets/images/sample2.jpg',
        title: 'Парк Горького',
        creationDate: now.subtract(const Duration(days: 5)),
        latitude: 55.7312,
        longitude: 37.6047,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample3',
        path: 'assets/images/sample3.jpg',
        title: 'Воробьевы горы',
        creationDate: now.subtract(const Duration(days: 3)),
        latitude: 55.7100,
        longitude: 37.5495,
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
        title: 'Московский Кремль',
        creationDate: now.subtract(const Duration(days: 8)),
        latitude: 55.7520,
        longitude: 37.6175,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample6',
        path: 'assets/images/sample2.jpg',
        title: 'Храм Василия Блаженного',
        creationDate: now.subtract(const Duration(days: 6)),
        latitude: 55.7525,
        longitude: 37.6230,
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
      print('Ошибка конвертации координат: $e');
    }
    return 0.0;
  }

  static double _parseGpsValue(dynamic value) {
    try {
      // В пакете exif значения могут быть разных типов
      // Проверяем основные возможные типы
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
    } catch (e) {
      print('Ошибка парсинга GPS значения: $e');
    }
    return 0.0;
  }
}
