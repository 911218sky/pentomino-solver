#!/bin/bash
# Build Squadron Web Worker for pentomino solver (WASM)

echo "Building Squadron Web Worker (WASM)..."

# Create workers directory if it doesn't exist
mkdir -p web/workers

# Compile the worker to WASM without source maps
dart compile wasm lib/core/workers/pentomino_solver_service.web.g.dart \
  -o web/workers/pentomino_solver_service.web.g.dart.wasm \
  --no-source-maps

echo ""
echo "Worker built successfully!"
echo "Output: web/workers/pentomino_solver_service.web.g.dart.wasm"
echo "Output: web/workers/pentomino_solver_service.web.g.dart.mjs"
