/// Squadron service for pentomino solving
library;

import 'dart:async';

import 'package:pentomino/core/algorithms/pentomino_solver.dart';
import 'package:squadron/squadron.dart';

import 'pentomino_solver_service.activator.g.dart';

part 'pentomino_solver_service.worker.g.dart';

@SquadronService(
  baseUrl: '~/workers',
  targetPlatform: TargetPlatform.vm | TargetPlatform.wasm,
)
base class PentominoSolverService {
  /// Solve pentomino puzzle and stream results
  /// This method yields progress and solutions as they are found
  @squadronMethod
  Stream<Map<String, dynamic>> solveStream(
    int boardRows,
    int boardCols,
    int maxSolutions,
    bool eliminateSymmetry,
  ) async* {
    final solver = PentominoSolver(
      boardRows: boardRows,
      boardCols: boardCols,
    );

    // Create a stream controller to emit progress in real-time
    final controller = StreamController<Map<String, dynamic>>();
    
    // Start solving asynchronously
    unawaited(
      solver.solveAsync(
        maxSolutions: maxSolutions,
        eliminateSymmetry: eliminateSymmetry,
        onProgress: (found, operations) {
          // Emit progress update
          controller.add({
            'type': 'progress',
            'solutionsFound': found,
            'operationsCount': operations,
          });
        },
        onSolutionFound: (board) {
          // Emit solution immediately when found
          controller.add({
            'type': 'solution',
            'data': board,
          });
        },
      ).then((solutions) {
        // Emit completion
        controller.add({
          'type': 'complete',
          'totalSolutions': solutions.length,
          'totalOperations': solver.solve().length,
        });
        controller.close();
      }).catchError((Object error, StackTrace stack) {
        controller.addError(error, stack);
        controller.close();
      }),
    );

    // Yield all messages from the controller
    await for (final message in controller.stream) {
      yield message;
    }
  }
}
