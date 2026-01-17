#!/usr/bin/env dart
/// Script to update worker base URL in generated files

import 'dart:io';

void main(List<String> args) {
  final baseUrl = args.isNotEmpty ? args[0] : 'workers';
  final file = File('lib/core/workers/pentomino_solver_service.web.g.dart');
  
  if (!file.existsSync()) {
    print('Error: Generated file not found');
    exit(1);
  }
  
  var content = file.readAsStringSync();
  
  // Replace the Squadron.uri path
  final pattern = RegExp(r"Squadron\.uri\('([^']+)'\)");
  final match = pattern.firstMatch(content);
  
  if (match != null) {
    final oldPath = match.group(1)!;
    final newPath = baseUrl.endsWith('/') 
        ? '$baseUrl${oldPath.split('/').last}'
        : '$baseUrl/${oldPath.split('/').last}';
    
    content = content.replaceAll(
      "Squadron.uri('$oldPath')",
      "Squadron.uri('$newPath')",
    );
    
    file.writeAsStringSync(content);
    print('✓ Updated worker base URL to: $newPath');
  } else {
    print('Error: Could not find Squadron.uri in generated file');
    exit(1);
  }
}
