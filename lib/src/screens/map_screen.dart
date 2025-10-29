import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/photo_provider.dart';
import '../models/photo_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? initialPhotoId =
        ModalRoute.of(context)!.settings.arguments as String?;

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

          // Координаты Москвы (домашний город олимпиады)
          final LatLng moscow = LatLng(55.7558, 37.6173);

          return FlutterMap(
            options: MapOptions(
              center: moscow,
              zoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.geo_album',
              ),
              MarkerLayer(
                markers: photosWithGeolocation.map((photo) {
                  return Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(photo.latitude!, photo.longitude!),
                    builder: (ctx) => GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/photo',
                          arguments: photo.id,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
