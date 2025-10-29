import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/photo_provider.dart';
import 'src/screens/gallery_screen.dart';
import 'src/screens/photo_view_screen.dart';
import 'src/screens/map_screen.dart';

void main() {
  runApp(const GeoAlbumApp());
}

class GeoAlbumApp extends StatelessWidget {
  const GeoAlbumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PhotoProvider()..loadPhotos(),
      child: MaterialApp(
        title: 'ГеоАльбом',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        initialRoute: '/gallery',
        routes: {
          '/gallery': (context) => const GalleryScreen(),
          '/photo': (context) => const PhotoViewScreen(),
          '/map': (context) => const MapScreen(),
        },
      ),
    );
  }
}
