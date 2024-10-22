import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Importa url_launcher para abrir enlaces

class GeolocatorView extends StatefulWidget {
  @override
  _GPSLocationScreenState createState() => _GPSLocationScreenState();
}

class _GPSLocationScreenState extends State<GeolocatorView> {
  String locationMessage = "Ubicación no disponible";
  String googleMapsUrl = ""; // Almacena el enlace de Google Maps

  // Método para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de localización están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationMessage = "Los servicios de localización están deshabilitados.";
      });
      return;
    }

    // Verificar si los permisos están concedidos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = "Permiso de ubicación denegado.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = "Los permisos de ubicación están permanentemente denegados.";
      });
      return;
    }

    // Obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Crear el enlace de Google Maps basado en las coordenadas
    googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

    setState(() {
      locationMessage =
          "Latitud: ${position.latitude}, Longitud: ${position.longitude}";
    });
  }

  // Método para abrir Google Maps con las coordenadas actuales
  Future<void> _launchGoogleMaps() async {
    if (googleMapsUrl.isNotEmpty && await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      setState(() {
        locationMessage = "No se pudo abrir Google Maps.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Obtener Ubicación GPS'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(locationMessage),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text("Obtener Ubicación Actual"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _launchGoogleMaps,
              child: Text("Abrir en Google Maps"),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: GeolocatorView(),
  ));
}
