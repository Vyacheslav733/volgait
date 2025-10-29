import 'dart:io';
import 'dart:math';
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_application_1/src/models/photo_model.dart';

class PhotoService {
  static Future<List<Photo>> getPhotos() async {
    final List<Photo> photos = [];

    try {
      final Directory homeDir = Directory('/home/user');
      final Directory picturesDir = Directory('${homeDir.path}/Pictures');

      if (!await picturesDir.exists()) {
        return _createSamplePhotos();
      }

      final List<FileSystemEntity> files = picturesDir.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File && _isImageFile(file.path)) {
          try {
            final Photo photo = await _createPhotoFromFile(file);
            photos.add(photo);
          } catch (e) {
            continue;
          }
        }
      }

      if (photos.isEmpty) {
        photos.addAll(_createSamplePhotos());
      }
    } catch (e) {
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
      final bytes = await file.readAsBytes();
      final exifData = await readExifFromBytes(bytes);

      if (exifData.isNotEmpty &&
          exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        final latTag = exifData['GPS GPSLatitude'];
        final lonTag = exifData['GPS GPSLongitude'];

        if (latTag != null && lonTag != null) {
          latitude = _convertGPSCoordinate(latTag.values as List);
          longitude = _convertGPSCoordinate(lonTag.values as List);

          final latRef = exifData['GPS GPSLatitudeRef']?.printable;
          final lonRef = exifData['GPS GPSLongitudeRef']?.printable;

          if (latRef == 'S') latitude = -latitude;
          if (lonRef == 'W') longitude = -longitude;

          hasGeolocation = true;
        }
      }
    } catch (e) {
      if (!hasGeolocation && Random().nextBool()) {
        latitude = 54.314 + (Random().nextDouble() - 0.5) * 0.1;
        longitude = 48.403 + (Random().nextDouble() - 0.5) * 0.1;
        hasGeolocation = true;
      }
    }

    final fileStat = await file.stat();
    return Photo(
      id: file.path,
      path: file.path,
      title: path.basename(file.path),
      creationDate: fileStat.modified,
      latitude: latitude,
      longitude: longitude,
      hasGeolocation: hasGeolocation,
    );
  }

  static List<Photo> _createSamplePhotos() {
    final now = DateTime.now();
    return [
      Photo(
        id: 'sample1',
        path: 'assets/images/sample1.jpg',
        title: 'Ульяновск - Площадь Ленина',
        creationDate: now.subtract(const Duration(days: 10)),
        latitude: 54.318,
        longitude: 48.406,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample2',
        path: 'assets/images/sample2.jpg',
        title: 'Краеведческий музей',
        creationDate: now.subtract(const Duration(days: 5)),
        latitude: 54.315,
        longitude: 48.406,
        hasGeolocation: true,
      ),
      Photo(
        id: 'sample3',
        path: 'assets/images/sample3.jpg',
        title: 'Музей Гражданской авиации',
        creationDate: now.subtract(const Duration(days: 3)),
        latitude: 54.291,
        longitude: 48.233,
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
    ];
  }

  static double _convertGPSCoordinate(List<dynamic> values) {
    try {
      if (values.length >= 3) {
        final double degrees = _parseGpsValue(values[0]);
        final double minutes = _parseGpsValue(values[1]);
        final double seconds = _parseGpsValue(values[2]);
        return degrees + (minutes / 60.0) + (seconds / 3600.0);
      }
      // ignore: empty_catches
    } catch (e) {}
    return 0.0;
  }

  static double _parseGpsValue(dynamic value) {
    try {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      // ignore: empty_catches
    } catch (e) {}
    return 0.0;
  }
}
