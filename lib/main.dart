import 'package:flutter/material.dart';
import 'package:turkuyolu/playlist.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void clearTemporaryDirectory() async {
  Directory tempDir = await getTemporaryDirectory();
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Binding'i başlat
  clearTemporaryDirectory(); // Geçici dizini temizle
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Music Player',
      home: PlaylistPage(), // Playlist sayfasını ana sayfa olarak belirle
    );
  }
}
