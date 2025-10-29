import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/src/services/photo_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.pushNamed(context, '/gallery');
            },
          ),
          // Кнопка сброса к Ульяновску
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(
                const LatLng(54.314, 48.403),
                12.0,
              );
              setState(() {
                _currentZoom = 12.0;
              });
            },
            tooltip: 'Центрировать на Ульяновске',
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final photosWithGeolocation = photoProvider.photosWithGeolocation;

          if (photosWithGeolocation.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет фотографий с геолокацией',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Фотографии с координатами будут отображены на карте',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Основная карта
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(54.314, 48.403),
                  initialZoom: 12.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() {
                        _currentZoom = position.zoom;
                      });
                    }
                  },
                ),
                children: [
                  // Слой карты OpenStreetMap
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.geo_album',
                    subdomains: const ['a', 'b', 'c'],
                  ),

                  // Слой маркеров фотографий
                  MarkerLayer(
                    markers: photosWithGeolocation.map((photo) {
                      return Marker(
                        point: LatLng(photo.latitude!, photo.longitude!),
                        width: _getMarkerSize(_currentZoom),
                        height: _getMarkerSize(_currentZoom),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/photo',
                              arguments: photo.id,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.photo,
                              color: Colors.white,
                              size: _getIconSize(_currentZoom),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Слой центрального маркера Ульяновска
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(54.314, 48.403),
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.location_city,
                          color: Colors.red,
                          size: 40,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Панель управления зумом
              Positioned(
                right: 16,
                top: 100,
                child: Column(
                  children: [
                    // Кнопка увеличения
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () {
                        final newZoom = _currentZoom + 1;
                        if (newZoom <= 18.0) {
                          _mapController.move(
                            _mapController.camera.center,
                            newZoom,
                          );
                          setState(() {
                            _currentZoom = newZoom;
                          });
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    // Отображение текущего зума
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_currentZoom.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Кнопка уменьшения
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () {
                        final newZoom = _currentZoom - 1;
                        if (newZoom >= 5.0) {
                          _mapController.move(
                            _mapController.camera.center,
                            newZoom,
                          );
                          setState(() {
                            _currentZoom = newZoom;
                          });
                        }
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),

              // Информационная панель внизу
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фотографий на карте: ${photosWithGeolocation.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Фото',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_city,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Ульяновск',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Кнопка быстрого приближения к фотографиям
      floatingActionButton: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final photos = photoProvider.photosWithGeolocation;
          if (photos.isEmpty) return const SizedBox();

          return FloatingActionButton(
            onPressed: () {
              // Приближаемся к границам всех фотографий
              final bounds = _calculateBounds(photos);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              );
            },
            tooltip: 'Показать все фотографии',
            child: const Icon(Icons.zoom_out_map),
          );
        },
      ),
    );
  }

  // Функция для расчета размера маркера в зависимости от зума
  double _getMarkerSize(double zoom) {
    if (zoom < 10) return 20;
    if (zoom < 13) return 30;
    if (zoom < 16) return 40;
    return 50;
  }

  // Функция для расчета размера иконки в зависимости от зума
  double _getIconSize(double zoom) {
    if (zoom < 10) return 12;
    if (zoom < 13) return 16;
    if (zoom < 16) return 20;
    return 24;
  }

  // Функция для расчета границ всех фотографий
  LatLngBounds _calculateBounds(List photos) {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final photo in photos) {
      if (photo.latitude! < minLat) minLat = photo.latitude!;
      if (photo.latitude! > maxLat) maxLat = photo.latitude!;
      if (photo.longitude! < minLon) minLon = photo.longitude!;
      if (photo.longitude! > maxLon) maxLon = photo.longitude!;
    }

    // Добавляем небольшой отступ
    const padding = 0.01;
    return LatLngBounds(
      LatLng(minLat - padding, minLon - padding),
      LatLng(maxLat + padding, maxLon + padding),
    );
  }
}
