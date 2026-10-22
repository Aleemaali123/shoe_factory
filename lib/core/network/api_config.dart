String defaultApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  // Android phones reach this host through `adb reverse tcp:4000 tcp:4000`.
  // The emulator alias is 10.0.2.2; pass it with --dart-define=API_BASE_URL when needed.
  return 'http://127.0.0.1:4000';
}
