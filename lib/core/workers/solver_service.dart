/// High-level service for solving pentomino puzzles with Squadron workers
library;

import 'dart:async';

import 'package:pentomino/core/utils/app_logger.dart';
import 'package:pentomino/core/workers/pentomino_solver_service.dart';

/// Status of the solver
enum SolverStatus {
  idle,
  solving,
  completed,
  stopped,
  error,
}

/// Progress update
class SolverProgress {
  SolverProgress({
    required this.solutionsFound,
    required this.operationsCount,
  });

  final int solutionsFound;
  final int operationsCount;
}

/// Service for managing pentomino solving with Squadron workers
class SolverService {
  PentominoSolverServiceWorker? _worker;
  StreamSubscription<Map<String, dynamic>>? _streamSub;

  final _solutionsController = StreamController<List<List<int>>>.broadcast();
  final _progressController = StreamController<SolverProgress>.broadcast();
  final _statusController = StreamController<SolverStatus>.broadcast();

  /// Stream of solutions as they are found
  Stream<List<List<int>>> get solutions => _solutionsController.stream;

  /// Stream of progress updates
  Stream<SolverProgress> get progress => _progressController.stream;

  /// Stream of status changes
  Stream<SolverStatus> get status => _statusController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Start solving with given parameters
  Future<void> start({
    int boardRows = 6,
    int boardCols = 10,
    int maxSolutions = -1,
    bool eliminateSymmetry = true,
  }) async {
    AppLogger.info('[SolverService] Starting solver...');

    if (_isRunning) {
      AppLogger.warning('[SolverService] Already running, stopping first');
      await stop();
    }

    _isRunning = true;
    _statusController.add(SolverStatus.solving);

    try {
      // Create Squadron worker
      _worker = PentominoSolverServiceWorker();
      AppLogger.info('[SolverService] Squadron worker created');

      // Subscribe to solution stream
      _streamSub = _worker!
          .solveStream(
            boardRows,
            boardCols,
            maxSolutions,
            eliminateSymmetry,
          )
          .listen(
            (message) {
              final type = message['type'] as String?;

              switch (type) {
                case 'solution':
                  // Handle type conversion for WASM compatibility
                  final data = message['data'];
                  final board = <List<int>>[];
                  if (data is List) {
                    for (final row in data) {
                      if (row is List) {
                        board.add(List<int>.from(row));
                      }
                    }
                  }
                  _solutionsController.add(board);

                case 'progress':
                  final progress = SolverProgress(
                    solutionsFound: message['solutionsFound'] as int,
                    operationsCount: message['operationsCount'] as int,
                  );
                  _progressController.add(progress);

                case 'complete':
                  AppLogger.info(
                    '[SolverService] Completed: ${message['totalSolutions']} solutions, '
                    '${message['totalOperations']} operations',
                  );
                  _statusController.add(SolverStatus.completed);
                  _isRunning = false;
                  unawaited(_cleanup());
              }
            },
            onError: (Object error, StackTrace stack) {
              AppLogger.error('[SolverService] Stream error: $error', error, stack);
              _statusController.add(SolverStatus.error);
              _isRunning = false;
              unawaited(_cleanup());
            },
            onDone: () {
              AppLogger.info('[SolverService] Stream completed');
              if (_isRunning) {
                _statusController.add(SolverStatus.completed);
                _isRunning = false;
              }
              unawaited(_cleanup());
            },
          );

      AppLogger.info('[SolverService] Worker started successfully');
    } catch (e, stack) {
      AppLogger.error('[SolverService] Failed to start: $e', e, stack);
      _statusController.add(SolverStatus.error);
      _isRunning = false;
      unawaited(_cleanup());
    }
  }

  /// Stop the current solving process
  Future<void> stop() async {
    AppLogger.info('[SolverService] Stopping...');
    await _cleanup();
    _isRunning = false;
    _statusController.add(SolverStatus.stopped);
  }

  Future<void> _cleanup() async {
    await _streamSub?.cancel();
    _streamSub = null;
    _worker?.stop();
    _worker = null;
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await stop();
    await _solutionsController.close();
    await _progressController.close();
    await _statusController.close();
  }
}
