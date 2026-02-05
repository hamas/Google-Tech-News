import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService extends Notifier<TtsState> {
  final FlutterTts _flutterTts = FlutterTts();
  String? _currentText;

  @override
  TtsState build() {
    _initTts();
    return TtsState.stopped;
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() => state = TtsState.playing);
    _flutterTts.setCompletionHandler(() => state = TtsState.stopped);
    _flutterTts.setCancelHandler(() => state = TtsState.stopped);
    _flutterTts.setPauseHandler(() => state = TtsState.paused);
    _flutterTts.setContinueHandler(() => state = TtsState.continued);

    _flutterTts.setErrorHandler((msg) {
      state = TtsState.stopped;
    });
  }

  Future<void> speak(String text) async {
    _currentText = text;
    if (state == TtsState.playing) {
      await stop();
    }
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    _currentText = null;
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  Future<void> resume() async {
    if (_currentText != null) {
      await _flutterTts.speak(_currentText!);
    }
  }
}

final ttsServiceProvider = NotifierProvider<TtsService, TtsState>(() {
  return TtsService();
});
