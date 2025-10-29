import 'dart:io';
import 'package:exif/exif.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

class PhotoService {
  static Future<List<Photo>> getPhotos() async {
    final List<Photo> photos = [];

    try {
      // Получаем доступ к галерее
      final PermissionState state =
          await PhotoManager.requestPermissionExtend();
      if (!state.hasAccess) {
        throw Exception('Доступ к галерее не предоставлен');
      }

      // Получаем все альбомы
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      for (final AssetPathEntity album in albums) {
        // Получаем фотографии из альбома
        final List<AssetEntity> assets = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );

        for (final AssetEntity asset in assets) {
          try {
            final File? file = await asset.file;
            if (file != null) {
              final Photo photo = await _createPhotoFromAsset(asset, file);
              photos.add(photo);
            }
          } catch (e) {
            print('Ошибка обработки фото: $e');
          }
        }
      }
    } catch (e) {
      print('Ошибка получения фото: $e');
    }

    return photos;
  }

  static Future<Photo> _createPhotoFromAsset(
      AssetEntity asset, File file) async {
    double? latitude;
    double? longitude;
    bool hasGeolocation = false;

    try {
      // Читаем EXIF данные
      final Map<String, IfdTag> exifData = await readExifFromFile(file.path);

      if (exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        latitude = _convertGPSCoordinate(exifData['GPS GPSLatitude']!);
        longitude = _convertGPSCoordinate(exifData['GPS GPSLongitude']!);

        // Учитываем полушария
        if (exifData.containsKey('GPS GPSLatitudeRef')) {
          final String latRef = exifData['GPS GPSLatitudeRef']!.printable;
          if (latRef == 'S') latitude = -latitude!;
        }

        if (exifData.containsKey('GPS GPSLongitudeRef')) {
          final String lonRef = exifData['GPS GPSLongitudeRef']!.printable;
          if (lonRef == 'W') longitude = -longitude!;
        }

        hasGeolocation = true;
      }
    } catch (e) {
      print('Ошибка чтения EXIF: $e');
    }

    return Photo(
      id: asset.id,
      path: file.path,
      title: asset.title,
      creationDate: asset.createDateTime,
      latitude: latitude,
      longitude: longitude,
      hasGeolocation: hasGeolocation,
    );
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
    if (value is Rational) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    }
    return 0.0;
  }
}
