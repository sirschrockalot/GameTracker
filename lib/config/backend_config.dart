/// Backend base URL (no trailing slash).
/// Override at build: --dart-define=BACKEND_BASE_URL=https://...
String get backendBaseUrl =>
    const String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'https://roster-flow-api-7ec3aecb99eb.herokuapp.com',
    );
