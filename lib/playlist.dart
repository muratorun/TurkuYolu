import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
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

  @override
  void initState() {
    super.initState();
    fetchAndUpdatePlaylist();
  }

  Future<void> fetchAndUpdatePlaylist() async {
    // Verileri çekme işlemi
    // ...

    setState(() {
      // Verileri güncelleme işlemi
    });
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await fetchAndUpdatePlaylist();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist'),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemCount: playlist.length,
          itemBuilder: (context, index) {
            final song = playlist[index];
            return ListTile(
              title: Text(song['songName']),
              // Müziği çalmak için gereken işlevi burada çağırabilirsiniz.
              // Örneğin, onPressed ile bir fonksiyonu çağırarak müziği çalabilirsiniz.
            );
          },
        ),
      ),
    );
  }
}
