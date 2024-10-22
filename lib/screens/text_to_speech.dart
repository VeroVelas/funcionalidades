import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TextToSpeechScreen extends StatefulWidget {
  @override
  _TextToSpeechScreenState createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  late FlutterTts flutterTts;
  String? _newVoiceText;
  double volume = 0.5;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<void> _speak() async {
    await flutterTts.setVolume(volume);

    if (_newVoiceText != null && _newVoiceText!.isNotEmpty) {
      await flutterTts.speak(_newVoiceText!);
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() {
      ttsState = TtsState.stopped;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              maxLines: 3,
              onChanged: _onChange,
              decoration: const InputDecoration(
                hintText: 'Escribe el texto que deseas escuchar',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _speak,
                  child: const Text('Hablar'),
                ),
                ElevatedButton(
                  onPressed: isPlaying ? _stop : null,
                  child: const Text('Detener'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSliders(), // Solo el control de volumen
          ],
        ),
      ),
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        Slider(
          value: volume,
          onChanged: (newVolume) {
            setState(() {
              volume = newVolume;
            });
          },
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: "Volumen: $volume",
        ),
      ],
    );
  }
}
