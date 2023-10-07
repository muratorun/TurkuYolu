import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

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
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentlyPlayingSong; // Çalan şarkının adını saklayacak değişken

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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await refreshList();
              },
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  final song = playlist[index];
                  final isCurrentlyPlaying =
                      song['songName'] == currentlyPlayingSong;

                  return ListTile(
                    title: Text(
                      song['songName'],
                      style: TextStyle(
                        color: isCurrentlyPlaying ? Colors.blue : Colors.black,
                        fontWeight: isCurrentlyPlaying
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () async {
                      try {
                        final audioUrl = song['songURL'] as String;
                        await audioPlayer.setAudioSource(
                            AudioSource.uri(Uri.parse(audioUrl)));
                        await audioPlayer.play();
                      } catch (error) {
                        print('Hata oluştu: $error');
                      }

                      setState(() {
                        currentlyPlayingSong = song['songName'];
                      });
                      print('Şarkı çalınıyor: ${song['songName']}');
                    },
                  );
                },
              ),
            ),
          ),
          _buildPlayerControls(), // Müzik çalar kontrol panelini ekliyoruz
        ],
      ),
    );
  }

  // Müzik çalar kontrol paneli
  Widget _buildPlayerControls() {
    return Column(
      children: [
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            if (playerState?.playing == true) {
              return IconButton(
                icon: Icon(Icons.pause),
                iconSize: 48.0,
                onPressed: () {
                  audioPlayer.pause();
                },
              );
            } else if (playerState?.playing == false) {
              return IconButton(
                icon: Icon(Icons.play_arrow),
                iconSize: 48.0,
                onPressed: () {
                  audioPlayer.play();
                },
              );
            } else {
              return SizedBox(); // Müzik çalmıyorsa hiçbir şey gösterme
            }
          },
        ),
        StreamBuilder<Duration?>(
          stream: audioPlayer.durationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return Text(
              '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 24.0,
              ),
            );
          },
        ),
      ],
    );
  }
}
