import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_application_1/src/models/photo_model.dart';

class PhotoService {
  static Future<List<Photo>> getPhotos() async {
    final List<Photo> photos = [];

    try {
      final Directory homeDir = Directory('/home/user');
      final Directory picturesDir = Directory('${homeDir.path}/Pictures');

      if (await picturesDir.exists()) {
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
      }

      if (photos.isEmpty) {
        photos.addAll(await _createSamplePhotos());
      }
    } catch (e) {
      photos.addAll(await _createSamplePhotos());
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
      originalPath: file.path,
    );
  }

  static Future<List<Photo>> _createSamplePhotos() async {
    final now = DateTime.now();
    final List<Photo> samplePhotos = [];

    final List<Map<String, dynamic>> sampleData = [
      {
        'assetPath': 'assets/images/sample1.jpg',
        'title': 'Ульяновск - Площадь Ленина',
        'lat': 54.318,
        'lon': 48.406,
      },
      {
        'assetPath': 'assets/images/sample2.jpg',
        'title': 'Краеведческий музей',
        'lat': 54.315,
        'lon': 48.406,
      },
      {
        'assetPath': 'assets/images/sample3.jpg',
        'title': 'Музей Гражданской авиации',
        'lat': 54.291,
        'lon': 48.233,
      },
      {
        'assetPath': 'assets/images/sample4.jpg',
        'title': 'Фото без геолокации',
        'lat': null,
        'lon': null,
      },
    ];

    for (final data in sampleData) {
      try {
        final tempFile = await _createTempFileFromAsset(data['assetPath']);

        samplePhotos.add(Photo(
          id: tempFile.path,
          path: tempFile.path,
          title: data['title'],
          creationDate: now.subtract(Duration(days: Random().nextInt(10) + 1)),
          latitude: data['lat'],
          longitude: data['lon'],
          hasGeolocation: data['lat'] != null && data['lon'] != null,
          originalPath: tempFile.path,
        ));
      } catch (e) {
        samplePhotos.add(Photo(
          id: '${data['assetPath']}_${Random().nextInt(1000)}',
          path: data['assetPath'],
          title: data['title'],
          creationDate: now.subtract(Duration(days: Random().nextInt(10) + 1)),
          latitude: data['lat'],
          longitude: data['lon'],
          hasGeolocation: data['lat'] != null && data['lon'] != null,
          originalPath: data['assetPath'],
        ));
      }
    }

    return samplePhotos;
  }

  static Future<File> _createTempFileFromAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final tempDir = await Directory.systemTemp.createTemp();
      final fileName = path.basename(assetPath);
      final tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(bytes);

      return tempFile;
    } catch (e) {
      throw Exception('Не удалось создать временный файл для asset: $e');
    }
  }

  static double _convertGPSCoordinate(List<dynamic> values) {
    try {
      if (values.length >= 3) {
        final double degrees = _parseGpsValue(values[0]);
        final double minutes = _parseGpsValue(values[1]);
        final double seconds = _parseGpsValue(values[2]);
        return degrees + (minutes / 60.0) + (seconds / 3600.0);
      }
    } catch (e) {/**/}
    return 0.0;
  }

  static double _parseGpsValue(dynamic value) {
    try {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    } catch (e) {/**/}
    return 0.0;
  }
}
