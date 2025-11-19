import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/src/services/photo_provider.dart';
import 'package:flutter_application_1/src/screens/gallery_screen.dart';
import 'package:flutter_application_1/src/screens/photo_view_screen.dart';
import 'package:flutter_application_1/src/screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
