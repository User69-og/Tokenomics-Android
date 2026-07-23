import 'package:flutter/material.dart';
import 'package:tokenomics/theme/app_theme.dart';

enum ProviderId {
  claude,
  openai,
  gemini,
  copilot,
  cursor,
  elevenlabs,
  runway,
  stableDiffusion,
}

extension ProviderIdExtension on ProviderId {
  String get displayName {
    switch (this) {
      case ProviderId.claude:
        return 'Claude';
      case ProviderId.openai:
        return 'OpenAI';
      case ProviderId.gemini:
        return 'Gemini';
      case ProviderId.copilot:
        return 'GitHub Copilot';
      case ProviderId.cursor:
        return 'Cursor';
      case ProviderId.elevenlabs:
        return 'ElevenLabs';
      case ProviderId.runway:
        return 'Runway';
      case ProviderId.stableDiffusion:
        return 'Stability AI';
    }
  }

  String get shortName {
    switch (this) {
      case ProviderId.claude:
        return 'Claude';
      case ProviderId.openai:
        return 'OpenAI';
      case ProviderId.gemini:
        return 'Gemini';
      case ProviderId.copilot:
        return 'Copilot';
      case ProviderId.cursor:
        return 'Cursor';
      case ProviderId.elevenlabs:
        return 'ElevenLabs';
      case ProviderId.runway:
        return 'Runway';
      case ProviderId.stableDiffusion:
        return 'Stability';
    }
  }

  Color get accentColor {
    switch (this) {
      case ProviderId.claude:
        return AppTheme.accentClaude;
      case ProviderId.openai:
        return AppTheme.accentOpenAI;
      case ProviderId.gemini:
        return AppTheme.accentGemini;
      case ProviderId.copilot:
        return AppTheme.accentCopilot;
      case ProviderId.cursor:
        return AppTheme.accentCursor;
      case ProviderId.elevenlabs:
        return AppTheme.accentElevenLabs;
      case ProviderId.runway:
        return AppTheme.accentRunway;
      case ProviderId.stableDiffusion:
        return AppTheme.accentStability;
    }
  }

  String get credentialLabel {
    switch (this) {
      case ProviderId.claude:
        return 'Session Token';
      case ProviderId.openai:
        return 'API Key';
      case ProviderId.gemini:
        return 'API Key';
      case ProviderId.copilot:
        return 'GitHub Token';
      case ProviderId.cursor:
        return 'API Key';
      case ProviderId.elevenlabs:
        return 'API Key';
      case ProviderId.runway:
        return 'API Key';
      case ProviderId.stableDiffusion:
        return 'API Key';
    }
  }

  String get credentialHint {
    switch (this) {
      case ProviderId.claude:
        return 'sk-ant-...';
      case ProviderId.openai:
        return 'sk-...';
      case ProviderId.gemini:
        return 'AIza...';
      case ProviderId.copilot:
        return 'ghp_...';
      case ProviderId.cursor:
        return 'key_...';
      case ProviderId.elevenlabs:
        return 'xi_...';
      case ProviderId.runway:
        return 'key_...';
      case ProviderId.stableDiffusion:
        return 'sk-...';
    }
  }

  String get setupInstructions {
    switch (this) {
      case ProviderId.claude:
        return '── Option A: Live Usage (Chrome Sync) ──\n1. Log into claude.ai with the extension active\n2. Look at the usage bars at the bottom\n3. Click the "ID: ... (Copy)" button\n4. Paste it here\n\n── Option B: Console API Key ──\n1. Go to console.anthropic.com\n2. Click API Keys → Create Key\n3. Copy the key (starts with "sk-ant-api...")';
      case ProviderId.openai:
        return '1. Go to platform.openai.com\n2. Click your profile → API keys\n3. Create a new secret key\n4. Copy and paste it here';
      case ProviderId.gemini:
        return '1. Go to aistudio.google.com\n2. Click "Get API key"\n3. Create a new key\n4. Copy and paste it here';
      case ProviderId.copilot:
        return '1. Go to github.com/settings/tokens\n2. Generate new token (classic)\n3. Select "read:user" scope\n4. Copy and paste it here';
      case ProviderId.cursor:
        return '1. Open Cursor app\n2. Go to Settings → Account\n3. Copy your API key\n4. Paste it here';
      case ProviderId.elevenlabs:
        return '1. Go to elevenlabs.io\n2. Click your profile icon\n3. Go to Profile + API key\n4. Copy and paste it here';
      case ProviderId.runway:
        return '1. Go to app.runwayml.com\n2. Go to Account Settings\n3. Find API Keys section\n4. Copy and paste it here';
      case ProviderId.stableDiffusion:
        return '1. Go to platform.stability.ai\n2. Go to Account → API Keys\n3. Copy your key\n4. Paste it here';
    }
  }

  String get setupUrl {
    switch (this) {
      case ProviderId.claude:
        return 'https://console.anthropic.com';
      case ProviderId.openai:
        return 'https://platform.openai.com';
      case ProviderId.gemini:
        return 'https://aistudio.google.com';
      case ProviderId.copilot:
        return 'https://github.com/settings/tokens';
      case ProviderId.cursor:
        return 'https://www.cursor.com';
      case ProviderId.elevenlabs:
        return 'https://elevenlabs.io';
      case ProviderId.runway:
        return 'https://app.runwayml.com';
      case ProviderId.stableDiffusion:
        return 'https://platform.stability.ai';
    }
  }

  String get rawValue => name;

  String get category {
    switch (this) {
      case ProviderId.claude:
      case ProviderId.openai:
      case ProviderId.gemini:
        return 'AI Platforms';
      case ProviderId.copilot:
      case ProviderId.cursor:
        return 'Coding Tools';
      case ProviderId.elevenlabs:
      case ProviderId.runway:
      case ProviderId.stableDiffusion:
        return 'Creative Tools';
    }
  }
}
