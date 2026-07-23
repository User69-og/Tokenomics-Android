import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_profile.dart';
import '../models/usage_data.dart';
import '../services/account_repository.dart';
import '../services/usage_providers.dart';
import '../services/alarm_service.dart';
import '../models/provider_id.dart';

// ── Repository provider ────────────────────────────────────────────────────

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

// ── Accounts state ─────────────────────────────────────────────────────────

class AccountsNotifier extends AsyncNotifier<List<AccountProfile>> {
  @override
  Future<List<AccountProfile>> build() async {
    final repo = ref.read(accountRepositoryProvider);
    return repo.loadAccounts();
  }

  Future<void> addAccount(AccountProfile account, String credential) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.addAccount(account);
    await repo.saveCredential(account.id, credential);
    
    // Automatically fetch usage right after adding
    ref.read(usageStateProvider.notifier).refreshAccount(account);
    
    ref.invalidateSelf();
  }

  Future<void> updateAccount(AccountProfile account) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.updateAccount(account);
    ref.invalidateSelf();
  }

  Future<void> deleteAccount(String accountId) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.deleteAccount(accountId);
    ref.invalidateSelf();
    // Also clear cached usage
    ref.invalidate(usageStateProvider);
  }

  Future<void> toggleAccount(String accountId) async {
    final accounts = state.value ?? [];
    final account = accounts.firstWhere((a) => a.id == accountId);
    await updateAccount(account.copyWith(isEnabled: !account.isEnabled));
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<AccountProfile>>(
        AccountsNotifier.new);

// ── Usage state ────────────────────────────────────────────────────────────

class UsageState {
  final Map<String, AccountUsageSnapshot> snapshots; // keyed by accountId
  final bool isRefreshing;

  const UsageState({
    this.snapshots = const {},
    this.isRefreshing = false,
  });

  UsageState copyWith({
    Map<String, AccountUsageSnapshot>? snapshots,
    bool? isRefreshing,
  }) {
    return UsageState(
      snapshots: snapshots ?? this.snapshots,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  List<AccountUsageSnapshot> snapshotsForProvider(String providerId) {
    return snapshots.values
        .where((s) => s.providerId == providerId)
        .toList();
  }

  AggregateUsage aggregateFor(String providerId) {
    return AggregateUsage.compute(
        providerId, snapshotsForProvider(providerId));
  }
}

class UsageNotifier extends Notifier<UsageState> {
  @override
  UsageState build() => const UsageState();

  Future<void> refresh(List<AccountProfile> accounts) async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);

    final repo = ref.read(accountRepositoryProvider);
    final enabled = accounts.where((a) => a.isEnabled).toList();

    // Fetch all accounts in parallel
    final futures = enabled.map((account) async {
      final credential = await repo.loadCredential(account.id);
      if (credential == null || credential.isEmpty) {
        return AccountUsageSnapshot(
          accountId: account.id,
          providerId: account.providerId,
          metrics: [],
          fetchedAt: DateTime.now(),
          status: ConnectionStatus.notConfigured,
          errorMessage: 'No credential saved',
        );
      }
      try {
        final provider = providerForId(account.providerId);
        final metrics = await provider.fetchUsage(credential);
        
        for (final m in metrics) {
          if (m.windowResetsAt != null) {
            final providerDisplayName = ProviderId.values.firstWhere((p) => p.rawValue == account.providerId).displayName;
            AlarmService.scheduleAlarm(account.label, providerDisplayName, m.windowResetsAt!);
          }
        }
        
        return AccountUsageSnapshot(
          accountId: account.id,
          providerId: account.providerId,
          metrics: metrics,
          fetchedAt: DateTime.now(),
          status: ConnectionStatus.connected,
        );
      } catch (e) {
        return AccountUsageSnapshot.withError(
            account.id, account.providerId, e.toString());
      }
    });

    final results = await Future.wait(futures);
    final updatedSnapshots = Map<String, AccountUsageSnapshot>.from(state.snapshots);
    for (final result in results) {
      updatedSnapshots[result.accountId] = result;
    }

    state = state.copyWith(
      snapshots: updatedSnapshots,
      isRefreshing: false,
    );
  }

  Future<void> refreshAccount(AccountProfile account) async {
    final repo = ref.read(accountRepositoryProvider);
    final credential = await repo.loadCredential(account.id);

    // Mark as loading
    final updatedSnapshots = Map<String, AccountUsageSnapshot>.from(state.snapshots);
    updatedSnapshots[account.id] =
        AccountUsageSnapshot.loading(account.id, account.providerId);
    state = state.copyWith(snapshots: updatedSnapshots);

    try {
      if (credential == null || credential.isEmpty) {
        throw Exception('No credential saved');
      }
      final provider = providerForId(account.providerId);
      final metrics = await provider.fetchUsage(credential);
      
      for (final m in metrics) {
        if (m.windowResetsAt != null) {
          final providerDisplayName = ProviderId.values.firstWhere((p) => p.rawValue == account.providerId).displayName;
          AlarmService.scheduleAlarm(account.label, providerDisplayName, m.windowResetsAt!);
        }
      }
      
      updatedSnapshots[account.id] = AccountUsageSnapshot(
        accountId: account.id,
        providerId: account.providerId,
        metrics: metrics,
        fetchedAt: DateTime.now(),
        status: ConnectionStatus.connected,
      );
    } catch (e) {
      updatedSnapshots[account.id] = AccountUsageSnapshot.withError(
          account.id, account.providerId, e.toString());
    }

    state = state.copyWith(snapshots: Map.from(updatedSnapshots));
  }
}

final usageStateProvider = NotifierProvider<UsageNotifier, UsageState>(
    UsageNotifier.new);
