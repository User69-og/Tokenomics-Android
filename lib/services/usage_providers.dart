import 'package:dio/dio.dart';
import '../models/usage_data.dart';
import 'claude_scraper_service.dart';
import 'alarm_service.dart';
import 'firebase_config.dart';

abstract class UsageProvider {
  String get providerId;
  Future<List<UsageMetric>> fetchUsage(String credential);
}

// ── Claude ─────────────────────────────────────────────────────────────────

class ClaudeProvider implements UsageProvider {
  @override
  String get providerId => 'claude';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    final c = credential.trim();
    // Session tokens:  sk-ant-sid01-... or sk-ant-sid02-...
    // Console API keys: sk-ant-api03-...
    // Anything that is NOT a session token goes to the console key path.
    if (c.startsWith('sk-ant-sid')) {
      print('DEBUG: HIT SESSION PATH for credential: $c');
      try {
        final res = await _fetchSessionUsage(c);
        if (res.isEmpty) {
           return [
             const UsageMetric(label: 'Empty response', used: 1, limit: 1)
           ];
        }
        return res;
      } catch (e) {
        String msg = e.toString();
        if (msg.length > 55) {
           msg = msg.substring(0, 55) + '...';
        }
        return [
           UsageMetric(label: 'Err: $msg', used: 1, limit: 1)
        ];
      }
    } else if (c.startsWith('sk-ant-')) {
      print('DEBUG: HIT CONSOLE PATH for credential: $c');
      return _fetchConsoleUsage(c);
    } else {
      print('DEBUG: HIT LEGACY PATH for credential: $c');
      return _fetchSessionUsage(c);
    }
  }

  /// For console.anthropic.com API keys (sk-ant-...)
  Future<List<UsageMetric>> _fetchConsoleUsage(String apiKey) async {
    try {
      await _dio.get(
        'https://api.anthropic.com/v1/models',
        options: Options(headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        }),
      );
      // Anthropic's public API does not expose session usage quotas (the
      // 5-hour / weekly limits you see on claude.ai). Those are only
      // available via the internal session-token endpoint.
      // We confirm the key is valid and surface a clear status instead.
      return [
        UsageMetric(
          label: 'Key: ${apiKey.substring(0, 15)}...',
          used: 1,
          limit: 1,
          unit: 'Connected ✓ (Not a session token)',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Claude');
    }
  }

  /// For claude.ai sessions, we now pull directly from our Firebase mirror!
  Future<List<UsageMetric>> _fetchSessionUsage(String sessionToken) async {
    final firebaseUrl = await FirebaseConfig.getUrl();
    if (firebaseUrl == null || firebaseUrl.trim().isEmpty) {
       return [
          const UsageMetric(
            label: 'Action Required',
            used: 1, limit: 1, unit: 'Configure Firebase URL in Settings',
          )
       ];
    }
    
    // Ensure URL doesn't have double slashes for the path
    final baseUrl = firebaseUrl.endsWith('/') ? firebaseUrl.substring(0, firebaseUrl.length - 1) : firebaseUrl;
    
    try {
      // The credential they pasted is their orgId (e.g. org-xxxxx)
      final accountId = sessionToken;
      // We use the Realtime Database REST API to instantly pull the latest tracked usage
      final response = await _dio.get('$baseUrl/claude_usage/$accountId.json');
      
      if (response.data == null) {
        return [
           UsageMetric(
             label: 'Awaiting Extension Data',
             used: 0,
             unit: 'Type a message in Claude to sync',
           )
        ];
      }
      
      final data = response.data as Map<String, dynamic>;
      
      final List<UsageMetric> metrics = [];

      if (data['quota'] != null) {
        final quota = data['quota'] as Map<String, dynamic>;
        
        String formatReset(String? resetsAtStr) {
          if (resetsAtStr == null) return '';
          final resetsAt = DateTime.tryParse(resetsAtStr);
          if (resetsAt == null) return '';
          final diff = resetsAt.difference(DateTime.now());
          if (diff.isNegative) return '';
          final days = diff.inDays;
          final hours = diff.inHours.remainder(24);
          final minutes = diff.inMinutes.remainder(60);
          
          if (days == 0 && hours == 0 && minutes == 0) return ' · resetting soon';
          if (days > 0) return ' · resets in ${days}d ${hours}h';
          if (hours == 0) return ' · resets in ${minutes}m';
          return ' · resets in ${hours}h ${minutes}m';
        }

        bool isResetPassed(String? resetsAtStr) {
          if (resetsAtStr == null) return false;
          final resetsAt = DateTime.tryParse(resetsAtStr);
          if (resetsAt == null) return false;
          return resetsAt.isBefore(DateTime.now());
        }

        if (quota['five_hour'] != null) {
          final resetsAtStr = quota['five_hour']['resets_at'] as String?;
          final passed = isResetPassed(resetsAtStr);
          final util = passed ? 0.0 : ((quota['five_hour']['utilization'] as num?)?.toDouble() ?? 0);
          final resetStr = passed ? '' : formatReset(resetsAtStr);
          metrics.add(UsageMetric(
            label: 'Session: ${util.round()}%$resetStr',
            used: util,
            limit: 100,
            unit: '%',
            windowResetsAt: resetsAtStr != null && !passed ? DateTime.tryParse(resetsAtStr) : null,
          ));
        }

        if (quota['seven_day'] != null) {
          final passed = isResetPassed(quota['seven_day']['resets_at'] as String?);
          final util = passed ? 0.0 : ((quota['seven_day']['utilization'] as num?)?.toDouble() ?? 0);
          final resetStr = passed ? '' : formatReset(quota['seven_day']['resets_at'] as String?);
          metrics.add(UsageMetric(
            label: 'Weekly: ${util.round()}%$resetStr',
            used: util,
            limit: 100,
            unit: '%',
          ));
        }
      }

      return metrics;
    } on DioException catch (e) {
      return [
        UsageMetric(
          label: 'Firebase Sync Error',
          used: 1, limit: 1, unit: e.message ?? 'Unknown error',
        )
      ];
    }
  }
}

// ── OpenAI (Codex) ─────────────────────────────────────────────────────────

class OpenAIProvider implements UsageProvider {
  @override
  String get providerId => 'openai';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      final now = DateTime.now().toUtc();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await _dio.get(
        'https://api.openai.com/v1/usage',
        queryParameters: {'date': date},
        options: Options(
            headers: {'Authorization': 'Bearer $credential'}),
      );

      final data = response.data as Map<String, dynamic>;
      final totalTokens = (data['data'] as List<dynamic>?)
              ?.fold<double>(
                  0,
                  (sum, item) =>
                      sum +
                      ((item as Map<String, dynamic>)['n_context_tokens_total']
                              as num? ??
                          0)
                          .toDouble()) ??
          0;

      return [
        UsageMetric(
          label: 'Today\'s Usage',
          used: totalTokens,
          unit: 'tokens',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'OpenAI');
    }
  }
}

// ── Gemini ─────────────────────────────────────────────────────────────────

class GeminiProvider implements UsageProvider {
  @override
  String get providerId => 'gemini';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      // Use models endpoint — rate limit data comes from response headers
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': credential, 'pageSize': 1},
      );

      // Extract rate limit info from headers if available
      final headers = response.headers;
      final remaining = headers.value('x-ratelimit-remaining-requests');
      final limit = headers.value('x-ratelimit-limit-requests');

      final metrics = <UsageMetric>[];
      if (remaining != null && limit != null) {
        final lim = double.tryParse(limit) ?? 0;
        final rem = double.tryParse(remaining) ?? 0;
        metrics.add(UsageMetric(
          label: 'Requests',
          used: lim - rem,
          limit: lim,
          unit: 'requests',
        ));
      } else {
        // API key is valid but no usage headers
        metrics.add(UsageMetric(
          label: 'Status',
          used: 0,
          unit: 'requests',
        ));
      }
      return metrics;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gemini');
    }
  }
}

// ── ElevenLabs ─────────────────────────────────────────────────────────────

class ElevenLabsProvider implements UsageProvider {
  @override
  String get providerId => 'elevenlabs';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      final response = await _dio.get(
        'https://api.elevenlabs.io/v1/user/subscription',
        options: Options(headers: {'xi-api-key': credential}),
      );
      final data = response.data as Map<String, dynamic>;
      return [
        UsageMetric(
          label: 'Characters',
          used: (data['character_count'] as num?)?.toDouble() ?? 0,
          limit: (data['character_limit'] as num?)?.toDouble(),
          unit: 'characters',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'ElevenLabs');
    }
  }
}

// ── Runway ─────────────────────────────────────────────────────────────────

class RunwayProvider implements UsageProvider {
  @override
  String get providerId => 'runway';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      final response = await _dio.get(
        'https://api.dev.runwayml.com/v1/organization',
        options: Options(headers: {
          'Authorization': 'Bearer $credential',
          'X-Runway-Version': '2024-11-06',
        }),
      );
      final data = response.data as Map<String, dynamic>;
      final credits = data['credits'] as Map<String, dynamic>?;
      return [
        UsageMetric(
          label: 'Credits',
          used: (credits?['used'] as num?)?.toDouble() ?? 0,
          limit: (credits?['total'] as num?)?.toDouble(),
          unit: 'credits',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Runway');
    }
  }
}

// ── Stability AI ───────────────────────────────────────────────────────────

class StabilityAIProvider implements UsageProvider {
  @override
  String get providerId => 'stableDiffusion';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      final response = await _dio.get(
        'https://api.stability.ai/v1/user/balance',
        options: Options(
            headers: {'Authorization': 'Bearer $credential'}),
      );
      final data = response.data as Map<String, dynamic>;
      return [
        UsageMetric(
          label: 'Credits',
          used: 0,
          limit: (data['credits'] as num?)?.toDouble(),
          unit: 'credits',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Stability AI');
    }
  }
}

// ── GitHub Copilot ─────────────────────────────────────────────────────────

class CopilotProvider implements UsageProvider {
  @override
  String get providerId => 'copilot';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      // Validate token via GitHub user API
      await _dio.get(
        'https://api.github.com/user',
        options: Options(headers: {
          'Authorization': 'Bearer $credential',
          'Accept': 'application/vnd.github+json',
        }),
      );
      // Copilot usage API is limited — return connection status
      return [
        const UsageMetric(
          label: 'Status',
          used: 0,
          unit: 'requests',
        ),
      ];
    } on DioException catch (e) {
      throw _handleDioError(e, 'GitHub Copilot');
    }
  }
}

// ── Cursor ─────────────────────────────────────────────────────────────────

class CursorProvider implements UsageProvider {
  @override
  String get providerId => 'cursor';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<List<UsageMetric>> fetchUsage(String credential) async {
    try {
      final response = await _dio.get(
        'https://www.cursor.com/api/usage',
        options: Options(headers: {'Authorization': 'Bearer $credential'}),
      );
      final data = response.data as Map<String, dynamic>;
      final metrics = <UsageMetric>[];
      if (data['gpt4'] != null) {
        final gpt4 = data['gpt4'] as Map<String, dynamic>;
        metrics.add(UsageMetric(
          label: 'Premium Requests',
          used: (gpt4['numRequestsTotal'] as num?)?.toDouble() ?? 0,
          limit: (gpt4['maxRequestUsage'] as num?)?.toDouble(),
          unit: 'requests',
        ));
      }
      return metrics;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Cursor');
    }
  }
}

// ── Error helper ───────────────────────────────────────────────────────────

String _handleDioError(DioException e, String providerName) {
  if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
    return 'Invalid $providerName credentials. Please check your key.';
  } else if (e.response?.statusCode == 429) {
    return '$providerName rate limit exceeded. Try again later.';
  } else if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return '$providerName request timed out. Check your connection.';
  }
  return '$providerName error: ${e.message ?? 'Unknown error'}';
}

// ── Provider factory ───────────────────────────────────────────────────────

UsageProvider providerForId(String providerId) {
  switch (providerId) {
    case 'claude':
      return ClaudeProvider();
    case 'openai':
      return OpenAIProvider();
    case 'gemini':
      return GeminiProvider();
    case 'copilot':
      return CopilotProvider();
    case 'cursor':
      return CursorProvider();
    case 'elevenlabs':
      return ElevenLabsProvider();
    case 'runway':
      return RunwayProvider();
    case 'stableDiffusion':
      return StabilityAIProvider();
    default:
      throw ArgumentError('Unknown provider: $providerId');
  }
}
