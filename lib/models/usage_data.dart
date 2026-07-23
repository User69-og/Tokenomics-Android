class UsageMetric {
  final String label;
  final double used;
  final double? limit;
  final String unit; // 'tokens', 'credits', 'characters', 'requests'
  final DateTime? windowResetsAt;

  const UsageMetric({
    required this.label,
    required this.used,
    this.limit,
    this.unit = 'tokens',
    this.windowResetsAt,
  });

  double get fraction => (limit != null && limit! > 0) ? (used / limit!).clamp(0.0, 1.0) : 0.0;
  bool get hasLimit => limit != null && limit! > 0;

  UsageMetric operator +(UsageMetric other) => UsageMetric(
        label: label,
        used: used + other.used,
        limit: (limit != null && other.limit != null) ? limit! + other.limit! : limit ?? other.limit,
        unit: unit,
        windowResetsAt: windowResetsAt,
      );
}

enum ConnectionStatus { connected, error, loading, notConfigured }

class AccountUsageSnapshot {
  final String accountId;
  final String providerId;
  final List<UsageMetric> metrics;
  final DateTime fetchedAt;
  final ConnectionStatus status;
  final String? errorMessage;

  const AccountUsageSnapshot({
    required this.accountId,
    required this.providerId,
    required this.metrics,
    required this.fetchedAt,
    this.status = ConnectionStatus.connected,
    this.errorMessage,
  });

  static AccountUsageSnapshot loading(String accountId, String providerId) =>
      AccountUsageSnapshot(
        accountId: accountId,
        providerId: providerId,
        metrics: [],
        fetchedAt: DateTime.now(),
        status: ConnectionStatus.loading,
      );

  static AccountUsageSnapshot withError(
          String accountId, String providerId, String error) =>
      AccountUsageSnapshot(
        accountId: accountId,
        providerId: providerId,
        metrics: [],
        fetchedAt: DateTime.now(),
        status: ConnectionStatus.error,
        errorMessage: error,
      );
}

class AggregateUsage {
  final String providerId;
  final List<UsageMetric> totals;
  final int accountCount;

  const AggregateUsage({
    required this.providerId,
    required this.totals,
    required this.accountCount,
  });

  static AggregateUsage compute(
      String providerId, List<AccountUsageSnapshot> snapshots) {
    final connected =
        snapshots.where((s) => s.status == ConnectionStatus.connected).toList();

    if (connected.isEmpty) {
      return AggregateUsage(
          providerId: providerId, totals: [], accountCount: 0);
    }

    // Sum metrics with matching labels
    final Map<String, UsageMetric> aggregated = {};
    for (final snapshot in connected) {
      for (final metric in snapshot.metrics) {
        if (aggregated.containsKey(metric.label)) {
          aggregated[metric.label] = aggregated[metric.label]! + metric;
        } else {
          aggregated[metric.label] = metric;
        }
      }
    }

    return AggregateUsage(
      providerId: providerId,
      totals: aggregated.values.toList(),
      accountCount: connected.length,
    );
  }
}
