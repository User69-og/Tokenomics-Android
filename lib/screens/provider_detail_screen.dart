import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_profile.dart';
import '../models/provider_id.dart';
import '../models/usage_data.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/usage_widgets.dart';
import 'add_account_screen.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final ProviderId provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final usageState = ref.watch(usageStateProvider);

    return accountsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentClaude)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allAccounts) {
        final accounts = allAccounts
            .where((a) => a.providerId == provider.rawValue && a.isEnabled)
            .toList();
        final color = provider.accentColor;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      provider.shortName[0],
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(provider.displayName),
              ],
            ),
            actions: [
              if (usageState.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    ref
                        .read(usageStateProvider.notifier)
                        .refresh(accounts);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _addAccount(context, ref),
              ),
            ],
          ),
          body: accounts.isEmpty
              ? EmptyStateWidget(
                  providerName: provider.shortName,
                  color: color,
                  onAdd: () => _addAccount(context, ref),
                )
              : _buildContent(context, ref, accounts, usageState, color),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<AccountProfile> accounts,
    UsageState usageState,
    Color color,
  ) {
    final snapshots = accounts
        .map((a) =>
            usageState.snapshots[a.id] ??
            AccountUsageSnapshot(
              accountId: a.id,
              providerId: provider.rawValue,
              metrics: [],
              fetchedAt: DateTime.now(),
              status: ConnectionStatus.notConfigured,
            ))
        .toList();

    final aggregate = AggregateUsage.compute(provider.rawValue, snapshots);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Per-account breakdown ────────────────────────────────────────
        const SectionHeader(title: 'ACCOUNTS'),
        const SizedBox(height: 12),
        ...List.generate(accounts.length, (i) {
          final account = accounts[i];
          final snapshot = snapshots[i];
          return _AccountCard(
            account: account,
            snapshot: snapshot,
            color: color,
            onRefresh: () => ref
                .read(usageStateProvider.notifier)
                .refreshAccount(account),
            onDelete: () => _deleteAccount(context, ref, account),
          );
        }),

        // ── Last synced footer ───────────────────────────────────────────
        if (snapshots.any((s) => s.status == ConnectionStatus.connected)) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Last synced ${_timeSince(snapshots.firstWhere((s) => s.status == ConnectionStatus.connected).fetchedAt)}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _addAccount(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(provider: provider),
      ),
    );
  }

  Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref, AccountProfile account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Delete Account',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove "${account.label}"? This will delete its saved credentials.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(accountsProvider.notifier)
          .deleteAccount(account.id);
    }
  }
}

// ── Account Card ───────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountProfile account;
  final AccountUsageSnapshot snapshot;
  final Color color;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.snapshot,
    required this.color,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  account.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(status: snapshot.status),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(Icons.refresh_rounded,
                    color: AppTheme.textMuted, size: 18),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textMuted, size: 18),
              ),
            ],
          ),
          if (snapshot.status == ConnectionStatus.loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              backgroundColor: AppTheme.border,
              color: AppTheme.accentClaude,
              minHeight: 2,
            ),
          ] else if (snapshot.status == ConnectionStatus.error) ...[
            const SizedBox(height: 10),
            Text(
              snapshot.errorMessage ?? 'Unknown error',
              style: const TextStyle(
                  color: AppTheme.error, fontSize: 12),
            ),
          ] else if (snapshot.metrics.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No usage data yet. Tap ↻ to refresh.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ...snapshot.metrics.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UsageBar(metric: m, color: color, compact: false),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Aggregate Card ─────────────────────────────────────────────────────────


