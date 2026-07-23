import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ClaudeScraperService {
  /// Scrapes claude.ai silently in a headless webview.
  /// Returns the parsed "resets in X" string if found.
  static Future<String?> fetchLimits(String sessionToken) async {
    final completer = Completer<String?>();
    
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
    await cookieManager.setCookie(
      url: WebUri("https://claude.ai/"),
      name: "sessionKey",
      value: sessionToken,
    );

    HeadlessInAppWebView? headlessWebView;
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("https://claude.ai/")),
      onLoadStop: (controller, url) async {
        // Poll for up to 10 seconds to allow React to render the limits
        for (int i = 0; i < 10; i++) {
          if (completer.isCompleted) return;
          await Future.delayed(const Duration(seconds: 1));
          
          try {
            final text = await controller.evaluateJavascript(source: "document.body.innerText;");
            if (text != null) {
              final str = text.toString();
              
              // Let's dump the raw text to the terminal so we can read Claude's native wording!
              print("=== GHOST BROWSER SAW THIS ===");
              print(str.replaceAll('\n', ' '));
              print("==============================");
              
              // Look for "resets in 3h 44m" or similar
              final regex = RegExp(r'resets in (\d+[hmd\s]+)');
              final match = regex.firstMatch(str);
              if (match != null) {
                if (!completer.isCompleted) {
                  completer.complete(match.group(1)?.trim());
                }
                return;
              }
            }
          } catch (e) {
            // Ignore errors and keep polling
          }
        }
        
        // If we didn't find it after 10 seconds, complete with null
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onLoadError: (controller, url, code, message) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onLoadHttpError: (controller, url, statusCode, description) {
         // Keep going, sometimes initial requests fail but it recovers
      }
    );

    try {
      await headlessWebView.run();
      final result = await completer.future.timeout(const Duration(seconds: 15));
      await headlessWebView.dispose();
      return result;
    } catch (e) {
      try {
        await headlessWebView.dispose();
      } catch (_) {}
      return null;
    }
  }
}
