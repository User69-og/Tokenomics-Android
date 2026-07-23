import 'package:flutter/material.dart';
import 'package:tokenomics/theme/app_theme.dart';

enum ProviderId {
  claude,
}

extension ProviderIdExtension on ProviderId {
  String get displayName {
    switch (this) {
      case ProviderId.claude:
        return 'Claude';
    }
  }

  String get shortName {
    switch (this) {
      case ProviderId.claude:
        return 'Claude';
    }
  }

  Color get accentColor {
    switch (this) {
      case ProviderId.claude:
        return AppTheme.accentClaude;
    }
  }

  String get credentialLabel {
    switch (this) {
      case ProviderId.claude:
        return 'Session Token';
    }
  }

  String get credentialHint {
    switch (this) {
      case ProviderId.claude:
        return 'sk-ant-...';
    }
  }

  String get setupInstructions {
    switch (this) {
      case ProviderId.claude:
        return '── Option A: Live Usage (Chrome Sync) ──\n1. Log into claude.ai with the extension active\n2. Look at the usage bars at the bottom\n3. Click the "ID: ... (Copy)" button\n4. Paste it here\n\n── Option B: Console API Key ──\n1. Go to console.anthropic.com\n2. Click API Keys → Create Key\n3. Copy the key (starts with "sk-ant-api...")';
    }
  }

  String get setupUrl {
    switch (this) {
      case ProviderId.claude:
        return 'https://console.anthropic.com';
    }
  }

  String get rawValue => name;

  String get category {
    switch (this) {
      case ProviderId.claude:
        return 'AI Platforms';
    }
  }
}

