class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabasePublishableKey, this.apiBaseUrl = ''});

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String apiBaseUrl;

  bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        apiBaseUrl: String.fromEnvironment('OG_WORKFORCE_API_BASE_URL'),
      );
}
