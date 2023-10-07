import 'package:flutter/material.dart';
import 'package:turkuyolu/playlist.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      home: PlaylistPage(), // Playlist sayfasını ana sayfa olarak belirle
    );
  }
}
