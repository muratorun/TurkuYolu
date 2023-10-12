import 'package:connectivity/connectivity.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  clearTemporaryDirectory();

  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    runApp(const NoInternetApp());
  } else {
    runApp(const MyApp());
  }
}

class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Internet',
      home: Scaffold(
        body: Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            backgroundColor: Colors.white,
            title: Text(
              'İnternet Bağlantısı Yok',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Text(
              'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  var connectivityResult =
                      await (Connectivity().checkConnectivity());
                  if (connectivityResult != ConnectivityResult.none) {
                    // Mesaj kapatılmadan önce kullanıcının internet bağlantısını kontrol etmesi için birkaç saniye bekle
                    await Future.delayed(Duration(seconds: 2));
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Yeniden Dene',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  exit(0); // Uygulamayı kapat
                },
                child: Text(
                  'Uygulamayı Kapat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      home: PlaylistPage(),
    );
  }
}
