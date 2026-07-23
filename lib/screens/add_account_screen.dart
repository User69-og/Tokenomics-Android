import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account_profile.dart';
import '../models/provider_id.dart';
import '../providers/app_providers.dart';
import '../services/usage_providers.dart';
import '../theme/app_theme.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final ProviderId provider;

  const AddAccountScreen({super.key, required this.provider});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _labelController = TextEditingController();
  final _credentialController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isValidating = false;
  bool _obscureCredential = true;
  String? _validationError;
  bool _validated = false;

  @override
  void dispose() {
    _labelController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.provider.accentColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Add ${widget.provider.shortName} Account'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Provider badge
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    widget.provider.shortName[0],
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Label field
            _FieldLabel(label: 'Account Label'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _labelController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Work, Personal, Side Project',
                prefixIcon: const Icon(Icons.label_outline_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Label is required' : null,
            ),
            const SizedBox(height: 20),

            // Credential field
            _FieldLabel(label: widget.provider.credentialLabel),
            const SizedBox(height: 8),
            TextFormField(
              controller: _credentialController,
              obscureText: _obscureCredential,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.provider.credentialHint,
                prefixIcon: const Icon(Icons.key_rounded,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCredential
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCredential = !_obscureCredential),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Credential is required' : null,
            ),
            const SizedBox(height: 8),

            if (_validationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error.withOpacity(0.3), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (_validated)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.3), width: 0.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppTheme.success, size: 16),
                    SizedBox(width: 8),
                    Text('Credential verified ✓',
                        style: TextStyle(
                            color: AppTheme.success, fontSize: 12)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // How to get your key
            _HowToGetKey(
              provider: widget.provider,
              color: color,
            ),

            const SizedBox(height: 32),

            // Verify & Save button
            FilledButton(
              onPressed: _isValidating ? null : _validateAndSave,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify & Save',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isValidating ? null : _saveWithoutVerify,
              child: const Text('Save without verifying',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isValidating = true;
      _validationError = null;
      _validated = false;
    });

    try {
      final provider = providerForId(widget.provider.rawValue);
      await provider.fetchUsage(_credentialController.text.trim());
      setState(() {
        _validated = true;
        _isValidating = false;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      await _save();
    } catch (e) {
      setState(() {
        _validationError = e.toString();
        _isValidating = false;
      });
    }
  }

  Future<void> _saveWithoutVerify() async {
    if (!_formKey.currentState!.validate()) return;
    await _save();
  }

  Future<void> _save() async {
    final account = AccountProfile(
      label: _labelController.text.trim(),
      providerId: widget.provider.rawValue,
    );
    await ref.read(accountsProvider.notifier).addAccount(
          account,
          _credentialController.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _HowToGetKey extends StatefulWidget {
  final ProviderId provider;
  final Color color;

  const _HowToGetKey({required this.provider, required this.color});

  @override
  State<_HowToGetKey> createState() => _HowToGetKeyState();
}

class _HowToGetKeyState extends State<_HowToGetKey> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      color: widget.color, size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'How to get your key',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding:
                  const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.provider.setupInstructions,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(widget.provider.setupUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.open_in_new_rounded, size: 16, color: widget.color),
                    label: Text(
                      'Open Console',
                      style: TextStyle(color: widget.color),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.color.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
