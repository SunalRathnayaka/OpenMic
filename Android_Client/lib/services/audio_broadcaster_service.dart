// lib/services/audio_broadcaster_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:logger/logger.dart';
import 'package:openmic/services/foreground_task_handler.dart';
import '../utils/audio_buffer_manager.dart';
import '../config/constants.dart';

class BroadcastState {
  final bool isStreaming;
  final List<Socket> clients;
  final String? error;

  BroadcastState({
    required this.isStreaming,
    required this.clients,
    this.error,
  });
}

class AudioBroadcasterService {
  // Core components
  final FlutterSoundRecorder _recorder;
  final AudioBufferManager _bufferManager;
  final Logger _logger;
  final ForegroundServiceManager _foregroundService =
      ForegroundServiceManager();

  // Server and streaming
  ServerSocket? _server;
  final List<Socket> _clients = [];
  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription? _recorderSubscription;

  // State
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;
  List<Socket> get clients => List.unmodifiable(_clients);

  AudioBroadcasterService()
      : _recorder = FlutterSoundRecorder(logLevel: Level.error),
        _bufferManager = AudioBufferManager(AudioConstants.bufferSize),
        _logger = Logger();

  Future<void> initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 23),
      );
      _logger.i('Recorder initialized successfully');
    } catch (e) {
      _logger.e('Error initializing recorder: $e');
      rethrow;
    }
  }

  final _stateController = StreamController<BroadcastState>.broadcast();
  Stream<BroadcastState> get stateStream => _stateController.stream;

  // Method to emit state updates
  void _emitState([String? error]) {
    _stateController.add(BroadcastState(
      isStreaming: _isStreaming,
      clients: List.unmodifiable(_clients),
      error: error,
    ));
  }

  Future<void> startBroadcasting() async {
    if (_isStreaming) {
      _logger.w('Broadcasting is already in progress');
      return;
    }
    try {
      // Initialize server
      _server = await ServerSocket.bind(
          InternetAddress.anyIPv4, AudioConstants.serverPort);
      _logger.i('Server listening on port ${AudioConstants.serverPort}');

      // Setup client handling
      _server!.listen(
        _handleClientConnection,
        onError: (error) {
          _logger.e('Server error: $error');
          stopBroadcasting();
        },
      );

      // Setup audio streaming
      _audioStreamController = StreamController<Uint8List>();
      _recorderSubscription = _audioStreamController!.stream.listen(
        _processAudioChunk,
        onError: (error) {
          _logger.e('Stream error: $error');
          stopBroadcasting();
        },
      );

      // Start recording
      await _recorder.startRecorder(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: AudioConstants.sampleRate,
        bitRate: 16 * AudioConstants.sampleRate,
        toStream: _audioStreamController!.sink,
        audioSource: AudioSource.microphone,
      );

      _isStreaming = true;
      _emitState();
      _logger.i('Broadcasting started successfully');
      await _foregroundService.initForegroundTask();
      await _foregroundService.startForegroundService();
    } catch (e) {
      _logger.e('Error starting broadcasting: $e');
      _emitState(e.toString());
      await stopBroadcasting();
      await _foregroundService.stopForegroundService();
      rethrow;
    }
  }

  void _handleClientConnection(Socket client) {
    _logger.i('Client connected from ${client.remoteAddress.address}');
    _clients.add(client);
    _emitState(); // Emit state update when client connects

    client.listen(
      null,
      onError: (error) {
        _logger.e('Client error: $error');
        _removeClient(client);
      },
      onDone: () {
        _logger.i('Client disconnected');
        _removeClient(client);
      },
    );
  }

  void _processAudioChunk(Uint8List chunk) {
    if (chunk.isEmpty) return;

    final completeChunks = _bufferManager.processChunk(chunk);

    for (var processedChunk in completeChunks) {
      _broadcastChunk(processedChunk);
    }
  }

  void _broadcastChunk(Uint8List chunk) {
    // Prepare the payload with length prefix
    final payload = ByteData(8 + chunk.length);
    payload.setUint64(0, chunk.length, Endian.big);
    payload.buffer.asUint8List().setRange(8, 8 + chunk.length, chunk);
    final data = payload.buffer.asUint8List();

    List<Socket> deadClients = [];

    // Send to all clients
    for (var client in _clients) {
      try {
        client.add(data);
      } catch (e) {
        _logger.e('Error sending to client ${client.remoteAddress}: $e');
        deadClients.add(client);
      }
    }

    // Clean up dead clients
    for (var client in deadClients) {
      _removeClient(client);
    }
  }

  void _removeClient(Socket client) {
    _clients.remove(client);
    client.close();
    _emitState();
  }

  Future<void> stopBroadcasting() async {
    if (!_isStreaming) return;

    try {
      // Stop recording
      await _foregroundService.stopForegroundService();
      await _recorder.stopRecorder();

      // Close all client connections
      for (var client in _clients) {
        await client.close();
      }
      _clients.clear();

      // Clean up server and stream
      await _server?.close();
      await _recorderSubscription?.cancel();
      await _audioStreamController?.close();

      _server = null;
      _audioStreamController = null;
      _recorderSubscription = null;
      _isStreaming = false;
      _emitState();
      _logger.i('Broadcasting stopped successfully');
    } catch (e) {
      _logger.e('Error stopping broadcasting: $e');
      _emitState(e.toString());
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await stopBroadcasting();
      await _stateController.close();
      await _recorder.closeRecorder();
      _bufferManager.logStats();
      _logger.i('AudioBroadcasterService disposed successfully');
    } catch (e) {
      _logger.e('Error disposing AudioBroadcasterService: $e');
    }
  }
}
