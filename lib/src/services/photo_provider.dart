import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/models/photo_model.dart';
import 'package:flutter_application_1/src/services/photo_service.dart';

class PhotoProvider with ChangeNotifier {
  List<Photo> _photos = [];
  bool _isLoading = false;
  String? _error;

  List<Photo> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Photo> get photosWithGeolocation =>
      _photos.where((photo) => photo.hasGeolocation).toList();

  Future<void> loadPhotos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photos = await PhotoService.getPhotos();
    } catch (e) {
      _error = 'Ошибка загрузки фотографий: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Photo? getPhotoById(String id) {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (e) {
      return null;
    }
  }

  void updatePhoto(String id,
      {String? title,
      String? path,
      String? originalPath,
      List<double>? lastCropRect}) {
    final index = _photos.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final current = _photos[index];
    _photos[index] = current.copyWith(
      title: title ?? current.title,
      path: path ?? current.path,
      originalPath: originalPath ?? current.originalPath,
      lastCropRect: lastCropRect ?? current.lastCropRect,
    );
    notifyListeners();
  }

  void restoreOriginal(String id) {
    final index = _photos.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final current = _photos[index];
    if (current.originalPath != null && current.originalPath!.isNotEmpty) {
      _photos[index] = current.copyWith(
        path: current.originalPath,
        originalPath: null,
        lastCropRect: null,
      );
      notifyListeners();
    }
  }
}
