import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider_id.dart';
import '../models/usage_data.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/usage_widgets.dart';
import 'provider_detail_screen.dart';
import 'settings_screen.dart';
import '../services/update_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
    Timer? _pollingTimer;

    @override
    void initState() {
      super.initState();
      
      // Wait for accounts to finish loading from storage, then trigger first fetch
      ref.read(accountsProvider.future).then((_) {
        if (mounted) _refresh();
      });
      
      // Auto-poll Firebase every 5 seconds to simulate real-time streaming
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && !ref.read(usageStateProvider).isRefreshing) {
          _refresh();
        }
      });

      // Check for updates after the frame renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }

    @override
    void dispose() {
      _pollingTimer?.cancel();
      super.dispose();
    }

  Future<void> _refresh() async {
    final accounts = ref.read(accountsProvider).value ?? [];
    if (accounts.isNotEmpty) {
      await ref.read(usageStateProvider.notifier).refresh(accounts);
    }
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (!mounted || !updateInfo.hasUpdate) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final usageState = ref.watch(usageStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            toolbarHeight: 70,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentClaude, AppTheme.accentOpenAI],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.token_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tokenomics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Theme toggle
              IconButton(
                icon: Icon(_themeModeIcon(ref.watch(themeModeProvider))),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                tooltip: 'Change theme',
                onPressed: () => _showThemePicker(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              if (usageState.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refresh,
                ),
            ],
          ),
          accountsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accentClaude)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                  child: Text('Error: $e',
                      style:
                          const TextStyle(color: AppTheme.textSecondary))),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyHome(onGetStarted: _openAddAccount),
                );
              }

              final providerIds = ProviderId.values;
              final activeProviders = providerIds
                  .where((p) =>
                      accounts.any((a) => a.providerId == p.rawValue))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    ...activeProviders.map((p) => _ExpandableProviderCard(
                          provider: p,
                          accounts: accounts
                              .where((a) =>
                                  a.providerId == p.rawValue && a.isEnabled)
                              .toList(),
                          usageState: usageState,
                          onAddAccount: () =>
                              _openAddAccountForProvider(context, p),
                        )),
                    const SizedBox(height: 24),
                    _AddProviderTile(onTap: _openAddAccount),
                    const SizedBox(height: 32),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openAddAccount() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProviderPickerSheet(
        onProviderSelected: (p) {
          Navigator.pop(context);
          _openAddAccountForProvider(context, p);
        },
      ),
    );
  }

  void _openAddAccountForProvider(BuildContext context, ProviderId p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProviderDetailScreen(provider: p)),
    );
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'System default',
                subtitle: 'Follows your device setting',
                selected: current == ThemeMode.system,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                subtitle: 'Easy on the eyes at night',
                selected: current == ThemeMode.dark,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                subtitle: 'Clean and bright',
                selected: current == ThemeMode.light,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const _UpdateDialog({required this.updateInfo});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;

  void _startDownload() {
    setState(() {
      _isDownloading = true;
    });

    UpdateService.downloadAndInstallUpdate(
      widget.updateInfo.apkUrl,
      (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
          if (progress == 1.0) {
            Navigator.of(context).pop(); // Close dialog when done
          } else if (progress == -1.0) {
            // Error
            setState(() {
              _isDownloading = false;
              _progress = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to download update.')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isDownloading, // Prevent back button if downloading
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Update Available',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.updateInfo.latestVersion} is available!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Release Notes:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.updateInfo.releaseNotes,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Later',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          if (!_isDownloading)
            ElevatedButton(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
        ],
      ),
    );
  }
}

class _ExpandableProviderCard extends ConsumerStatefulWidget {
  final ProviderId provider;
  final List<dynamic> accounts;
  final UsageState usageState;
  final VoidCallback onAddAccount;

  const _ExpandableProviderCard({
    required this.provider,
    required this.accounts,
    required this.usageState,
    required this.onAddAccount,
  });

  @override
  ConsumerState<_ExpandableProviderCard> createState() =>
      _ExpandableProviderCardState();
}

class _ExpandableProviderCardState
    extends ConsumerState<_ExpandableProviderCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.provider.accentColor;
    final connectedCount = widget.usageState
        .snapshotsForProvider(widget.provider.rawValue)
        .where((s) => s.status == ConnectionStatus.connected)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? color.withOpacity(0.35) : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.provider.shortName[0],
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider.displayName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.accounts.length} account${widget.accounts.length != 1 ? 's' : ''}'
                          '${connectedCount > 0 ? ' · $connectedCount live' : ''}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onAddAccount,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.add_rounded, color: color, size: 18),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 22),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Container(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 4),
                ...widget.accounts.map((account) {
                  final snapshot =
                      widget.usageState.snapshots[account.id] ??
                          AccountUsageSnapshot(
                            accountId: account.id,
                            providerId: widget.provider.rawValue,
                            metrics: [],
                            fetchedAt: DateTime.now(),
                            status: ConnectionStatus.notConfigured,
                          );
                  return _InlineAccountRow(
                    account: account,
                    snapshot: snapshot,
                    color: color,
                    isLast: account == widget.accounts.last,
                    onRefresh: () => ref
                        .read(usageStateProvider.notifier)
                        .refreshAccount(account),
                    onDelete: () => _deleteAccount(account),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(dynamic account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Remove "${account.label}"? This will delete its saved credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountsProvider.notifier).deleteAccount(account.id);
    }
  }
}

class _InlineAccountRow extends StatelessWidget {
  final dynamic account;
  final AccountUsageSnapshot snapshot;
  final Color color;
  final bool isLast;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _InlineAccountRow({
    required this.account,
    required this.snapshot,
    required this.color,
    required this.isLast,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(status: snapshot.status),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRefresh,
                child: Icon(Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 17),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 17),
              ),
            ],
          ),
          if (snapshot.status == ConnectionStatus.loading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).dividerColor,
              color: color,
              minHeight: 2,
            ),
          ] else if (snapshot.status == ConnectionStatus.error) ...[
            const SizedBox(height: 6),
            Text(
              snapshot.errorMessage ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.error, fontSize: 11),
            ),
          ] else if (snapshot.metrics.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...snapshot.metrics.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: UsageBar(metric: m, color: color, compact: true),
                )),
          ],
          if (!isLast) ...[
            const SizedBox(height: 6),
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5), height: 1),
          ],
        ],
      ),
    );
  }
}

class _AddProviderTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProviderTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 20),
            const SizedBox(width: 10),
            Text(
              'Add Provider Account',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderPickerSheet extends StatelessWidget {
  final void Function(ProviderId) onProviderSelected;

  const _ProviderPickerSheet({required this.onProviderSelected});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ProviderId>>{};
    for (final p in ProviderId.values) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Choose a provider',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select the service you want to track',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.border, height: 1),
            // Scrollable list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  ...grouped.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...entry.value.map((p) => _ProviderTile(
                        provider: p,
                        onTap: () => onProviderSelected(p),
                      )),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final ProviderId provider;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = provider.accentColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      provider.shortName[0],
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        provider.category,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _EmptyHome({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.accentClaude, AppTheme.accentOpenAI],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(
              Icons.token_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Track your AI spend',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add accounts for Claude, OpenAI, Gemini,\nElevenLabs, Runway and more to see your\ntoken and credit usage in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onGetStarted,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first account'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentClaude,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.5)
                  : Theme.of(context).dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(0.12)
                      : Theme.of(context).dividerColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? accent : Theme.of(context).hintColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? accent
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
