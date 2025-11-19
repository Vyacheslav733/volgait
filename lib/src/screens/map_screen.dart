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

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      if (_currentZoom > 18.0) _currentZoom = 18.0;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      if (_currentZoom < 3.0) _currentZoom = 3.0;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  @override
  void initState() {
    super.initState();
    _mapController.mapEventStream.listen((event) {
      setState(() {
        _currentZoom = _mapController.zoom;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Consumer<PhotoProvider>(
          builder: (context, photoProvider, child) {
            final photosWithGeolocation = photoProvider.photosWithGeolocation;

            if (photosWithGeolocation.isEmpty) {
              return _buildEmptyState();
            }

            return Stack(
              children: [
                _buildMap(photosWithGeolocation),
                _buildAppBar(),
                _buildZoomControls(),
                _buildShowAllPhotosButton(photoProvider),
                _buildInfoPanel(photosWithGeolocation.length),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(List photosWithGeolocation) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(54.314, 48.403),
        initialZoom: _currentZoom,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.geo_album',
        ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.photo_rounded,
                    color: Colors.white,
                    size: _getIconSize(_currentZoom),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const MarkerLayer(
          markers: [
            Marker(
              point: LatLng(54.314, 48.403),
              width: 60,
              height: 60,
              child: Icon(
                Icons.location_city_rounded,
                color: Colors.red,
                size: 48,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      size: 20, color: Theme.of(context).colorScheme.onSurface),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Text(
                'Карта фотографий',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      size: 20, color: Theme.of(context).colorScheme.onSurface),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/gallery');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map_outlined,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Нет фотографий с геолокацией',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Фотографии с координатами будут отображены на карте',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.9),
              Theme.of(context).colorScheme.surface.withOpacity(0.7),
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
                    size: 20, color: Theme.of(context).colorScheme.onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Text(
              'Карта фотографий',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded,
                    size: 20, color: Theme.of(context).colorScheme.onSurface),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/gallery');
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.my_location_rounded,
                    size: 20, color: Theme.of(context).colorScheme.onPrimary),
              ),
              onPressed: () {
                _mapController.move(const LatLng(54.314, 48.403), 12.0);
                setState(() {
                  _currentZoom = 12.0;
                });
              },
              tooltip: 'Центрировать на Ульяновске',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          GestureDetector(
            onTap: _zoomIn,
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.add_rounded,
                    size: 24, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_currentZoom.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          GestureDetector(
            onTap: _zoomOut,
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.remove_rounded,
                    size: 24, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowAllPhotosButton(PhotoProvider photoProvider) {
    final photos = photoProvider.photosWithGeolocation;
    if (photos.isEmpty) return const SizedBox();

    return Positioned(
      right: 16,
      top: 280,
      child: GestureDetector(
        onTap: () {
          final bounds = _calculateBounds(photos);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(
              padding: EdgeInsets.all(80),
            ),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.zoom_out_map_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(int photoCount) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Фотографий на карте:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                Text(
                  '$photoCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                _buildLegendItem(
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.photo_rounded,
                  text: 'Фото',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: Colors.red,
                  icon: Icons.location_city_rounded,
                  text: 'Ульяновск',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            icon,
            size: 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  double _getMarkerSize(double zoom) {
    if (zoom < 10) return 24;
    if (zoom < 13) return 32;
    if (zoom < 16) return 40;
    return 48;
  }

  double _getIconSize(double zoom) {
    if (zoom < 10) return 14;
    if (zoom < 13) return 18;
    if (zoom < 16) return 22;
    return 26;
  }

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

    const padding = 0.01;
    return LatLngBounds(
      LatLng(minLat - padding, minLon - padding),
      LatLng(maxLat + padding, maxLon + padding),
    );
  }
}
