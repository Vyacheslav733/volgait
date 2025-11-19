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
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0066CC),
            brightness: Brightness.light,
            primary: const Color(0xFF0066CC),
            secondary: const Color(0xFF66A3FF),
            surface: const Color(0xFFF8F9FA),
            background: const Color(0xFFFFFFFF),
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF66A3FF),
            brightness: Brightness.dark,
            primary: const Color(0xFF66A3FF),
            secondary: const Color(0xFF0066CC),
            surface: const Color(0xFF1E1E1E),
            background: const Color(0xFF121212),
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
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
