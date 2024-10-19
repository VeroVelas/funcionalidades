import 'package:flutter/material.dart';
import 'screens/geolocator.dart';
import 'screens/sensorplus.dart';
import 'screens/text_to_speech.dart';
import 'screens/speech_to_text.dart';  // Asegúrate de que este import esté correctamente referenciado.
import 'screens/qr_scanner.dart';
import 'screens/dev_team.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movil Act',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      routes: {
        '/geolocator': (context) => GeolocatorView(),
        '/sensorplus': (context) => SensorPlus(),
        '/text_to_speech': (context) => TextToSpeechScreen(),
        '/speech_to_text': (context) => SpeechToTextScreen(),  // Asegúrate de que esta ruta sea correcta
        '/qr_scanner': (context) => QRScannerView(),
        '/dev_team': (context) => DevTeam(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movil Act'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () {
              Navigator.pushNamed(context, '/geolocator');
            },
          ),
          IconButton(
            icon: Icon(Icons.sensors),
            onPressed: () {
              Navigator.pushNamed(context, '/sensorplus');
            },
          ),
          IconButton(
            icon: Icon(Icons.text_fields),
            onPressed: () {
              Navigator.pushNamed(context, '/text_to_speech');
            },
          ),
          IconButton(
            icon: Icon(Icons.mic),
            onPressed: () {
              Navigator.pushNamed(context, '/speech_to_text');
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () {
              Navigator.pushNamed(context, '/qr_scanner');
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/dev_team');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Bienvenido a Movil Act'),
      ),
    );
  }
}
