import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart'; // Importa url_launcher para abrir enlaces

class QRScannerView extends StatefulWidget {
  @override
  _QRScannerViewState createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _isScanning = true; // Bandera para controlar si se está escaneando

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Función para verificar si el string es un URL
  bool _isValidURL(String? url) {
    if (url == null) return false;
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  // Función para abrir el enlace en el navegador
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir el enlace: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Código QR: ${describeEnum(result!.format)} - ${result!.code}')
                  : Text('Escanea un código QR'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      if (_isScanning) {
        setState(() {
          result = scanData;
          _isScanning = false; // Detiene el escaneo para evitar múltiples redirecciones
        });

        // Pausa la cámara para evitar reescaneo continuo
        controller.pauseCamera();

        // Si el código escaneado es una URL válida, redirigir automáticamente
        if (_isValidURL(result?.code)) {
          await _launchURL(result!.code!);
        }

        // Opcional: Si quieres cerrar la pantalla después de escanear
        // Navigator.pop(context);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }
}
