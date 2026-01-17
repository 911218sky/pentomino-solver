/// Worker configuration
library;

/// Get the base URL for workers based on environment
const String workerBaseUrl = String.fromEnvironment(
  'WORKER_BASE_URL',
  defaultValue: 'workers',
);
