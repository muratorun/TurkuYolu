import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, dynamic>> playlist = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylistData();
  }

  Future<void> fetchPlaylistData() async {
    final response = await http.get(
      Uri.parse(
          'https://raw.githubusercontent.com/muratorun/TurkuYolu/main/playlist.json'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        playlist = List<Map<String, dynamic>>.from(jsonData['songs']);
      });
    } else {
      throw Exception('Failed to load playlist data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist'),
      ),
      body: ListView.builder(
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          final song = playlist[index];
          return ListTile(
            title: Text(song['songName']),
            // Burada şarkıyı çalmak için gerekli işlevi çağırabilirsiniz.
            // Örneğin, onPressed ile bir fonksiyonu çağırarak müziği çalabilirsiniz.
          );
        },
      ),
    );
  }
}
