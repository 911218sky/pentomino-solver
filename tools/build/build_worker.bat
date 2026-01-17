@echo off
REM Build Squadron Web Worker for pentomino solver (JavaScript)

echo Building Squadron Web Worker (JavaScript)...

REM Create workers directory if it doesn't exist
if not exist "web\workers" mkdir "web\workers"

REM Compile the worker to JavaScript without source maps
dart compile js lib/core/workers/pentomino_solver_service.web.g.dart -o web/workers/pentomino_solver_service.web.g.dart.js -O2 --no-source-maps

echo.
echo Worker built successfully!
echo Output: web/workers/pentomino_solver_service.web.g.dart.js
