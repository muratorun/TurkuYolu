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
  String currentlyPlayingSong = ""; // Boş bir metin olarak başlatın
  int currentlyPlayingIndex = -1; // Şu an çalınan şarkının indeksi
  Duration songDuration = Duration.zero;
  Duration songPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchAndUpdatePlaylist();
  }

  Future<void> fetchAndUpdatePlaylist() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/muratorun/TurkuYolu/main/playlist.json',
        ),
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

  Widget _buildPlayerControls() {
    return Column(
      children: [
        SizedBox(height: 20),
        if (currentlyPlayingSong
            .isNotEmpty) // Şarkı çalınıyorsa süre bilgilerini göster
          Column(
            children: [
              Text(
                currentlyPlayingSong, // Şarkının adını göster
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous),
                    iconSize: 36.0,
                    onPressed: () async {
                      try {
                        if (currentlyPlayingIndex == 0) {
                          // Eğer listenin başındaysa, son şarkıya git
                          currentlyPlayingIndex = playlist.length - 1;
                        } else {
                          // Değilse, bir önceki şarkıya git
                          currentlyPlayingIndex--;
                        }

                        final prevSong = playlist[currentlyPlayingIndex];
                        final audioUrl = prevSong['songURL'] as String;
                        await audioPlayer.setAudioSource(
                            AudioSource.uri(Uri.parse(audioUrl)));
                        await audioPlayer.play();

                        setState(() {
                          currentlyPlayingSong = prevSong['songName'];
                          songDuration = audioPlayer.duration ?? Duration.zero;
                          songPosition = Duration.zero;
                        });
                      } catch (error) {
                        print('Hata oluştu: $error');
                      }
                    },
                  ),
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
                        return SizedBox();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next),
                    iconSize: 36.0,
                    onPressed: () async {
                      try {
                        if (currentlyPlayingIndex == playlist.length - 1) {
                          // Eğer listenin sonundayız, başa dön
                          currentlyPlayingIndex = 0;
                        } else {
                          // Değilse, bir sonraki şarkıya git
                          currentlyPlayingIndex++;
                        }

                        final nextSong = playlist[currentlyPlayingIndex];
                        final audioUrl = nextSong['songURL'] as String;
                        await audioPlayer.setAudioSource(
                            AudioSource.uri(Uri.parse(audioUrl)));
                        await audioPlayer.play();

                        setState(() {
                          currentlyPlayingSong = nextSong['songName'];
                          songDuration = audioPlayer.duration ?? Duration.zero;
                          songPosition = Duration.zero;
                        });
                      } catch (error) {
                        print('Hata oluştu: $error');
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Slider(
                value: songPosition.inSeconds.toDouble(),
                onChanged: (double value) {
                  audioPlayer.seek(Duration(seconds: value.toInt()));
                },
                min: 0,
                max: songDuration.inSeconds.toDouble(),
              ),
              SizedBox(height: 8),
              Text(
                '${songPosition.inMinutes}:${(songPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${songDuration.inMinutes}:${(songDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
            ],
          ),
      ],
    );
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
                  final isCurrentlyPlaying = index == currentlyPlayingIndex;

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
                        setState(() {
                          currentlyPlayingSong = song['songName'];
                          currentlyPlayingIndex =
                              index; // Yeni çalınan şarkının indeksini güncelle
                          songDuration = audioPlayer.duration ?? Duration.zero;
                          songPosition = Duration.zero;
                        });
                      } catch (error) {
                        print('Hata oluştu: $error');
                      }
                      print('Şarkı çalınıyor: ${song['songName']}');
                    },
                  );
                },
              ),
            ),
          ),
          _buildPlayerControls(),
        ],
      ),
    );
  }
}
