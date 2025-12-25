import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Types of UI events to log
enum UIEventType {
  // User interactions
  pieceTapped,
  squareTapped,
  actionButtonPressed,
  
  // UI state changes
  selectionChanged,
  validMovesComputed,
  animationStarted,
  animationCompleted,
  
  // Bridge calls
  bridgeCallStarted,
  bridgeCallCompleted,
  bridgeCallFailed,
  
  // Game events
  gameStarted,
  gameEnded,
  turnChanged,
  goalScored,
  
  // Errors
  error,
}

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final String source; // 'ENGINE' or 'UI'
  final String event;
  final Map<String, dynamic>? data;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.source,
    required this.event,
    this.data,
    this.error,
  });

  String toLogLine() {
    final ts = timestamp.toIso8601String();
    final dataStr = data != null ? ' ${json.encode(data)}' : '';
    final errorStr = error != null ? ' ERROR: $error' : '';
    return '[$ts] $source:$event$dataStr$errorStr';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'event': event,
    if (data != null) 'data': data,
    if (error != null) 'error': error,
  };
}

/// Match logger for comprehensive debugging
class MatchLogger {
  final String gameId;
  final List<LogEntry> _entries = [];
  final DateTime _startTime;
  File? _logFile;
  
  // Timing tracking for bridge calls
  final Map<String, DateTime> _pendingCalls = {};

  MatchLogger(this.gameId) : _startTime = DateTime.now();

  /// Log a UI event
  void logUI(UIEventType type, String description, {Map<String, dynamic>? data}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: 'UI',
      event: '${type.name} $description',
      data: data,
    );
    _entries.add(entry);
    debugPrint(entry.toLogLine());
  }

  /// Log the start of a bridge call (for timing)
  void logBridgeStart(String method) {
    _pendingCalls[method] = DateTime.now();
    logUI(UIEventType.bridgeCallStarted, method);
  }

  /// Log the completion of a bridge call
  void logBridgeComplete(String method, {Map<String, dynamic>? result}) {
    final startTime = _pendingCalls.remove(method);
    final duration = startTime != null 
        ? DateTime.now().difference(startTime).inMilliseconds 
        : 0;
    logUI(UIEventType.bridgeCallCompleted, method, data: {
      'duration_ms': duration,
      if (result != null) ...result,
    });
  }

  /// Log a bridge call failure
  void logBridgeFailed(String method, String error) {
    _pendingCalls.remove(method);
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: 'UI',
      event: '${UIEventType.bridgeCallFailed.name} $method',
      error: error,
    );
    _entries.add(entry);
    debugPrint(entry.toLogLine());
  }

  /// Log an error
  void logError(String description, {String? error, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: 'UI',
      event: '${UIEventType.error.name} $description',
      error: error ?? stackTrace?.toString(),
    );
    _entries.add(entry);
    debugPrint(entry.toLogLine());
  }

  /// Log engine action from ActionLogView
  void logEngineAction(ActionLogView action) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: 'ENGINE',
      event: 'ACTION',
      data: {
        'team': action.team?.name,
        'action': action.actionType.name,
        'from': '(${action.from.row},${action.from.col})',
        'to': '(${action.to.row},${action.to.col})',
        'path': action.path.map((p) => '(${p.row},${p.col})').toList(),
        if (action.pieceId != null) 'piece': action.pieceId,
      },
    );
    _entries.add(entry);
    debugPrint(entry.toLogLine());
  }

  /// Sync action log from engine
  Future<void> syncFromEngine() async {
    try {
      final actions = await getActionLog(gameId: gameId);
      // Only log new actions (compare with existing engine entries)
      final existingCount = _entries.where((e) => e.source == 'ENGINE').length;
      for (var i = existingCount; i < actions.length; i++) {
        logEngineAction(actions[i]);
      }
    } catch (e) {
      logError('Failed to sync from engine', error: e.toString());
    }
  }

  /// Get the log file path
  Future<String> get _logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${dir.path}/xfutebol_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    final timestamp = _startTime.toIso8601String().replaceAll(':', '-').split('.').first;
    return '${logsDir.path}/match_${timestamp}_$gameId.log';
  }

  /// Export log to file
  Future<File> exportToFile() async {
    final path = await _logFilePath;
    final file = File(path);
    final content = await _generateLogContent();
    await file.writeAsString(content);
    _logFile = file;
    debugPrint('[MatchLogger] Exported to: $path');
    return file;
  }

  /// Generate the full log content
  Future<String> _generateLogContent() async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 80);
    buffer.writeln('XFUTEBOL MATCH LOG');
    buffer.writeln('=' * 80);
    buffer.writeln('Game ID: $gameId');
    buffer.writeln('Started: ${_startTime.toIso8601String()}');
    buffer.writeln('-' * 80);
    buffer.writeln();
    
    // Get match state from engine
    try {
      final state = await getMatchState(gameId: gameId);
      if (state != null) {
        buffer.writeln('Mode: ${state.mode.name}');
        buffer.writeln('Turn: ${state.currentTurn}');
        buffer.writeln('Score: White ${state.scoreWhite} - Black ${state.scoreBlack}');
        buffer.writeln('Status: ${state.isFinished ? "Finished" : "In Progress"}');
        if (state.winner != null) {
          buffer.writeln('Winner: ${state.winner!.name}');
        }
        buffer.writeln('Board: ${state.boardNotation}');
        buffer.writeln();
        buffer.writeln('-' * 80);
        buffer.writeln();
      }
    } catch (e) {
      buffer.writeln('(Could not fetch match state: $e)');
      buffer.writeln();
    }
    
    // Log entries
    for (final entry in _entries) {
      buffer.writeln(entry.toLogLine());
    }
    
    // Summary
    buffer.writeln();
    buffer.writeln('-' * 80);
    buffer.writeln('SUMMARY');
    buffer.writeln('-' * 80);
    final duration = DateTime.now().difference(_startTime);
    buffer.writeln('Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    buffer.writeln('Total log entries: ${_entries.length}');
    buffer.writeln('UI events: ${_entries.where((e) => e.source == "UI").length}');
    buffer.writeln('Engine events: ${_entries.where((e) => e.source == "ENGINE").length}');
    buffer.writeln('Errors: ${_entries.where((e) => e.error != null).length}');
    buffer.writeln('=' * 80);
    
    return buffer.toString();
  }

  /// Export log as string (for clipboard/sharing)
  Future<String> exportToString() async {
    return _generateLogContent();
  }

  /// Get all log entries
  List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Get entry count
  int get entryCount => _entries.length;

  /// Clear log file if it exists
  Future<void> cleanup() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }

  /// Clean up old log files (keep last N)
  static Future<void> cleanupOldLogs({int keepCount = 10}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/xfutebol_logs');
      if (!await logsDir.exists()) return;

      final files = await logsDir.list().where((e) => e is File).toList();
      if (files.length <= keepCount) return;

      // Sort by modification time (oldest first)
      final fileStats = await Future.wait(
        files.map((f) async => (file: f as File, stat: await f.stat())),
      );
      fileStats.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));

      // Delete oldest files
      final toDelete = fileStats.take(fileStats.length - keepCount);
      for (final item in toDelete) {
        await item.file.delete();
        debugPrint('[MatchLogger] Deleted old log: ${item.file.path}');
      }
    } catch (e) {
      debugPrint('[MatchLogger] Cleanup failed: $e');
    }
  }
}

