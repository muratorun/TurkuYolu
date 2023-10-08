import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PlaylistPage(),
    );
  }
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, dynamic>> playlist = [];
  bool isRefreshing = false;
  bool refreshCompleted = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentlyPlayingSong;
  Duration? songDuration;
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchAndUpdatePlaylist();
    setupAudioPlayer();
  }

  void setupAudioPlayer() {
    audioPlayer.durationStream.listen((Duration? duration) {
      if (duration != null) {
        setState(() {
          songDuration = duration;
        });
      }
    });

    audioPlayer.positionStream.listen((Duration position) {
      setState(() {
        _currentPosition = position;
        _sliderValue = position.inMilliseconds.toDouble();
      });
    });

    audioPlayer.playerStateStream.listen((PlayerState playerState) async {
      if (playerState.playing) {
        setState(() {
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
      if (playerState.processingState == ProcessingState.completed) {
        // Şarkı tamamlandıysa sıradaki şarkıyı çal
        await _playNextSong();
      }
    });
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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

  Future<void> _playPreviousSong() async {
    final currentIndex =
        playlist.indexWhere((song) => song['songName'] == currentlyPlayingSong);
    if (currentIndex > 0) {
      final previousSong = playlist[currentIndex - 1];
      await _playSong(previousSong);
    }
  }

  Future<void> _playNextSong() async {
    final currentIndex =
        playlist.indexWhere((song) => song['songName'] == currentlyPlayingSong);
    if (currentIndex < playlist.length - 1) {
      final nextSong = playlist[currentIndex + 1];
      await _playSong(nextSong);
    }
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    try {
      final audioUrl = song['songURL'] as String;
      await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await audioPlayer.play();
    } catch (error) {
      print('Hata oluştu: $error');
    }

    setState(() {
      currentlyPlayingSong = song['songName'];
      _isPlaying = true;
    });
    print('Şarkı çalınıyor: ${song['songName']}');
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
                      await _playSong(song);
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

  Widget _buildPlayerControls() {
    return Column(
      children: [
        Slider(
          value: _sliderValue,
          onChanged: (newValue) {
            audioPlayer.seek(Duration(milliseconds: newValue.toInt()));
          },
          min: 0.0,
          max: songDuration?.inMilliseconds.toDouble() ?? 1.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _printDuration(_currentPosition),
                style: const TextStyle(fontSize: 16.0),
              ),
              Text(
                _printDuration(songDuration ?? Duration.zero),
                style: const TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () async {
                await _playPreviousSong();
              },
              iconSize: 48.0,
            ),
            const SizedBox(width: 16.0),
            GestureDetector(
              onTap: () {
                if (_isPlaying) {
                  audioPlayer.pause();
                } else {
                  audioPlayer.play();
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48.0,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () async {
                await _playNextSong();
              },
              iconSize: 48.0,
            ),
          ],
        ),
      ],
    );
  }
}
