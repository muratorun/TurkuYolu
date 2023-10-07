import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlaylistPage(),
    );
  }
}

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, dynamic>> playlist = [];
  bool isRefreshing = false;
  bool refreshCompleted = false;

  @override
  void initState() {
    super.initState();
    fetchAndUpdatePlaylist();
  }

  Future<void> fetchAndUpdatePlaylist() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://raw.githubusercontent.com/muratorun/TurkuYolu/main/playlist.json'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updatedPlaylist =
            List<Map<String, dynamic>>.from(jsonData['songs']);

        setState(() {
          playlist = updatedPlaylist;
        });

        print('Liste başarıyla güncellendi');
      } else {
        throw Exception('Failed to load playlist data');
      }
    } catch (error) {
      print('Hata: $error');
    }
  }

  Future<void> refreshList() async {
    try {
      await fetchAndUpdatePlaylist();

      print('Swipe işlemiyle liste güncellendi');

      setState(() {
        refreshCompleted = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          refreshCompleted = false;
        });
      });
    } catch (error) {
      print('Hata: $error');
      print('Swipe işlemiyle liste güncellenemedi');
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshList();
        },
        child: ListView.builder(
          itemCount: playlist.length,
          itemBuilder: (context, index) {
            final song = playlist[index];
            return ListTile(
              title: Text(song['songName']),
            );
          },
        ),
      ),
    );
  }
}
