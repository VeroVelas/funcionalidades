import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextScreen extends StatefulWidget {
  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _statusMessage = '';
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // Inicializar el reconocimiento de voz
  void _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) {
        setState(() {
          _statusMessage = 'Estado: $val';
        });
        print('onStatus: $val');
      },
      onError: (val) {
        setState(() {
          _statusMessage = 'Error: $val';
        });
        print('onError: $val');
      },
    );
    setState(() {
      _speechEnabled = available;
      if (!available) {
        _statusMessage = 'Reconocimiento de voz no disponible';
      }
    });
  }

  // Función para iniciar o detener el reconocimiento de voz
  void _listen() async {
    if (_speechEnabled && !_isListening) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _textController.text = val.recognizedWords;
        }),
      );
    } else if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Limpiar el campo de texto
  void _clearText() {
    setState(() {
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reconocimiento de Voz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Texto reconocido',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: _speechEnabled ? _listen : null,
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                ),
                ElevatedButton(
                  onPressed: _clearText,
                  child: Text('Limpiar'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
