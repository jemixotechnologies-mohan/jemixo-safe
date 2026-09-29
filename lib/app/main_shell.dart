import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/privacy/app_detail_page.dart';
import '../features/privacy/privacy_page.dart';
import '../features/scam_scanner/scam_scanner_page.dart';
import '../features/scam_scanner/screenshot_check_page.dart';
import '../features/security/apk_analyzer_page.dart';
import '../features/security/security_page.dart';
import '../features/simple/simple_home_page.dart';
import '../features/more/more_page.dart';
import '../features/storage/storage_page.dart';
import '../features/url_checker/url_checker_page.dart';
import '../services/platform/native_bridge.dart';
import '../state/dashboard_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import 'jemixo_safe_app.dart';

/// Five-tab shell. Each tab keeps its own navigation state so switching tabs
/// never resets a half-finished scan or list. In simple mode the shell is
/// replaced by the large-button home.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<SharedContent>? _shareSubscription;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.shield_outlined),
      selectedIcon: Icon(Icons.shield_rounded),
      label: 'Safety',
    ),
    NavigationDestination(
      icon: Icon(Icons.privacy_tip_outlined),
      selectedIcon: Icon(Icons.privacy_tip_rounded),
      label: 'Privacy',
    ),
    NavigationDestination(
      icon: Icon(Icons.cleaning_services_outlined),
      selectedIcon: Icon(Icons.cleaning_services_rounded),
      label: 'Clean',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shareSubscription = NativeBridge.instance.sharedContent.listen(_onShared);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = await NativeBridge.instance.pendingShare();
      if (pending != null && mounted) _onShared(pending);
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  /// Routes a hand-off (share sheet, text selection, tile, notification).
  Future<void> _onShared(SharedContent content) async {
    final navigator = appNavigatorKey.currentState ?? Navigator.of(context);
    switch (content.kind) {
      case SharedKind.text:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ScamScannerPage(initialText: content.text),
          ),
        );
      case SharedKind.apk:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ApkAnalyzerPage(initialPath: content.apkPath),
          ),
        );
      case SharedKind.app:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => AppDetailPage(packageName: content.packageName!),
          ),
        );
      case SharedKind.clipboard:
        await _checkClipboard(navigator);
      case SharedKind.image:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ScreenshotCheckPage(initialImagePath: content.imagePath),
          ),
        );
    }
  }

  Future<void> _checkClipboard(NavigatorState navigator) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      showAppSnack(context, 'Nothing is copied right now. Copy the message first.');
      return;
    }
    final looksLikeUrl = !text.contains(' ') &&
        RegExp(
          r'^(https?://|www\.)|^[a-z0-9-]+(\.[a-z0-9-]+)+(/|$)',
          caseSensitive: false,
        ).hasMatch(text);
    if (looksLikeUrl) {
      context.read<ToolsController>().analyzeUrl(text);
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const UrlCheckerPage()),
      );
    } else {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ScamScannerPage(initialText: text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final simple = context.select<SettingsController, bool>((s) => s.simpleMode);
    if (simple) return const SimpleHomePage();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardPage(),
          SecurityPage(),
          PrivacyPage(),
          StoragePage(),
          MorePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        destinations: _destinations,
      ),
    );
  }
}
