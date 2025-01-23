// lib/utils/audio_buffer_manager.dart

import 'dart:typed_data';
import 'package:logger/logger.dart';

class AudioBufferManager {
  // Configuration
  final int targetChunkSize;
  final Logger _logger = Logger();

  // Buffer state
  Uint8List? _buffer;
  int _bufferSize = 0;

  // Statistics
  int _totalProcessed = 0;
  int _chunkCount = 0;
  int _underflowCount = 0;
  int _overflowCount = 0;
  double _maxChunkSize = 0;
  double _minChunkSize = double.infinity;
  final Map<int, int> _chunkSizeDistribution = {};
  final List<int> _recentChunkSizes = [];
  static const int _maxRecentChunks = 100;

  AudioBufferManager(this.targetChunkSize) {
    _logger.i(
        'AudioBufferManager initialized with target chunk size: $targetChunkSize');
  }

  /// Process incoming audio chunk and return list of complete chunks
  List<Uint8List> processChunk(Uint8List inputChunk) {
    if (inputChunk.isEmpty) {
      _logger.w('Received empty input chunk');
      return [];
    }

    List<Uint8List> completeChunks = [];

    // Update statistics
    _updateStatistics(inputChunk);

    // If we have a previous buffer, combine it with the new chunk
    if (_buffer != null) {
      final newBuffer = Uint8List(_bufferSize + inputChunk.length);
      newBuffer.setRange(0, _bufferSize, _buffer!);
      newBuffer.setRange(
          _bufferSize, _bufferSize + inputChunk.length, inputChunk);
      _buffer = newBuffer;
      _bufferSize += inputChunk.length;
    } else {
      _buffer = Uint8List.fromList(inputChunk);
      _bufferSize = inputChunk.length;
    }

    // Extract complete chunks
    while (_bufferSize >= targetChunkSize) {
      final chunk = Uint8List(targetChunkSize);
      chunk.setRange(0, targetChunkSize, _buffer!.sublist(0, targetChunkSize));
      completeChunks.add(chunk);

      _buffer = Uint8List.fromList(_buffer!.sublist(targetChunkSize));
      _bufferSize -= targetChunkSize;
    }

    // Check for potential issues
    if (_bufferSize > targetChunkSize * 2) {
      _overflowCount++;
      _logger.w('Buffer overflow detected: $_bufferSize bytes accumulated');
    }

    return completeChunks;
  }

  void _updateStatistics(Uint8List chunk) {
    _chunkCount++;
    _totalProcessed += chunk.length;

    // Update chunk size distribution
    _chunkSizeDistribution[chunk.length] =
        (_chunkSizeDistribution[chunk.length] ?? 0) + 1;

    // Update min/max chunk sizes
    _maxChunkSize =
        _maxChunkSize < chunk.length ? chunk.length.toDouble() : _maxChunkSize;
    _minChunkSize =
        _minChunkSize > chunk.length ? chunk.length.toDouble() : _minChunkSize;

    // Track recent chunk sizes
    _recentChunkSizes.add(chunk.length);
    if (_recentChunkSizes.length > _maxRecentChunks) {
      _recentChunkSizes.removeAt(0);
    }

    // Log statistics periodically
    if (_chunkCount % 100 == 0) {
      logStats();
    }
  }

  /// Get current buffer statistics
  Map<String, dynamic> getStats() {
    final avgChunkSize = _chunkCount > 0 ? _totalProcessed / _chunkCount : 0;

    final recentAvgChunkSize = _recentChunkSizes.isNotEmpty
        ? _recentChunkSizes.reduce((a, b) => a + b) / _recentChunkSizes.length
        : 0;

    return {
      'totalBytesProcessed': _totalProcessed,
      'totalChunksProcessed': _chunkCount,
      'averageChunkSize': avgChunkSize,
      'recentAverageChunkSize': recentAvgChunkSize,
      'minChunkSize': _minChunkSize,
      'maxChunkSize': _maxChunkSize,
      'currentBufferSize': _bufferSize,
      'bufferOverflows': _overflowCount,
      'bufferUnderflows': _underflowCount,
      'chunkSizeDistribution': _chunkSizeDistribution,
    };
  }

  /// Log current buffer statistics
  void logStats() {
    final stats = getStats();
    _logger.i('Audio Buffer Statistics:');
    _logger.i('Total bytes processed: ${stats['totalBytesProcessed']}');
    _logger.i('Total chunks processed: ${stats['totalChunksProcessed']}');
    _logger.i(
        'Average chunk size: ${stats['averageChunkSize'].toStringAsFixed(2)}');
    _logger.i(
        'Recent average chunk size: ${stats['recentAverageChunkSize'].toStringAsFixed(2)}');
    _logger.i('Min chunk size: ${stats['minChunkSize']}');
    _logger.i('Max chunk size: ${stats['maxChunkSize']}');
    _logger.i('Current buffer size: ${stats['currentBufferSize']}');
    _logger.i('Buffer overflows: ${stats['bufferOverflows']}');
    _logger.i('Buffer underflows: ${stats['bufferUnderflows']}');
  }

  /// Reset the buffer and statistics
  void reset() {
    _buffer = null;
    _bufferSize = 0;
    _totalProcessed = 0;
    _chunkCount = 0;
    _underflowCount = 0;
    _overflowCount = 0;
    _maxChunkSize = 0;
    _minChunkSize = double.infinity;
    _chunkSizeDistribution.clear();
    _recentChunkSizes.clear();
    _logger.i('AudioBufferManager reset');
  }

  /// Get the current buffer size
  int get currentBufferSize => _bufferSize;

  /// Check if the buffer is empty
  bool get isEmpty => _bufferSize == 0;
}
