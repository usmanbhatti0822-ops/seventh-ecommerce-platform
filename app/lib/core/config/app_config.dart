/// Central runtime configuration for both the Customer app and Admin panel.
///
/// Portfolio/demo note: this app ships with `demoMode = true` by default so it
/// runs standalone — every screen is fully functional against an in-memory
/// mock backend (see `core/network/mock_backend.dart`) with no server, database,
/// or third-party credentials required. Flip to a real NestJS deployment by
/// building with:
///   flutter run --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
/// The repository/provider layer is identical in both modes — only the Dio
/// transport underneath changes.
class AppConfig {
  AppConfig._();

  static const bool demoMode = bool.fromEnvironment("DEMO_MODE", defaultValue: true);

  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:3000/api/v1",
  );

  /// Simulated network latency range for the mock backend, so loading/shimmer
  /// states are visible instead of resolving instantly (feels like a real API).
  static const int mockLatencyMinMs = 280;
  static const int mockLatencyMaxMs = 650;
}
