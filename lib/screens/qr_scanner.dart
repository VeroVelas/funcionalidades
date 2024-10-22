import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/foundation.dart';

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

  // Función para validar si el string es una matrícula (en este caso, asumimos que es un número)
  bool _isValidMatricula(String? data) {
    if (data == null) return false;
    final matriculaRegExp = RegExp(r'^[0-9]+$'); // Asume que la matrícula solo tiene números
    return matriculaRegExp.hasMatch(data);
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
                  ? Text('Matrícula escaneada: ${result!.code}') // Muestra la matrícula
                  : Text('Escanea un código QR'),
            ),
          ),
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
          _isScanning = false; // Detiene el escaneo para evitar múltiples lecturas
        });

        // Pausa la cámara para evitar reescaneo continuo
        controller.pauseCamera();

        // Validar si el QR escaneado es una matrícula válida
        if (_isValidMatricula(result?.code)) {
          // Aquí puedes hacer cualquier acción adicional con la matrícula si lo deseas
          print('Matrícula escaneada: ${result!.code}');
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
