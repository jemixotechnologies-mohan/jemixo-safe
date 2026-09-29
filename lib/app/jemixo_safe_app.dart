import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/database/app_database.dart';
import '../data/repositories/scan_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../services/app_scanner/app_scanner_service.dart';
import '../services/apk_analyzer/apk_analyzer_service.dart';
import '../services/device_service/device_service.dart';
import '../services/ocr/ocr_service.dart';
import '../services/storage_analyzer/storage_service.dart';
import '../services/threat_data/threat_data.dart';
import '../state/dashboard_controller.dart';
import '../state/history_controller.dart';
import '../state/security_controller.dart';
import '../state/settings_controller.dart';
import '../features/onboarding/welcome_page.dart';
import 'main_shell.dart';

/// Root navigator, so share-sheet hand-offs can push a page from outside the
/// widget tree.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class JemixoSafeApp extends StatelessWidget {
  const JemixoSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppEntry();
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  final AppDatabase _database = AppDatabase();
  late final SettingsRepository _settingsRepository;
  late final ScanRepository _scanRepository;
  late final SettingsController _settings;
  late final ThreatDataService _threatData;
  late final AppScannerService _scanner;
  late final StorageService _storage;
  late final DeviceService _device;
  late final ApkAnalyzerService _apk;
  late final OcrService _ocr;
  late final SecurityController _security;
  late final HistoryController _history;
  late final ToolsController _tools;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settingsRepository = SettingsRepository(_database);
    _scanRepository = ScanRepository(_database);
    _settings = SettingsController(_settingsRepository);
    _threatData = ThreatDataService(_settingsRepository);
    _scanner = AppScannerService(
      flagDebuggable: () => _settings.showDebuggable,
    );
    _storage = StorageService();
    _device = DeviceService();
    _apk = ApkAnalyzerService();
    _ocr = OcrService();
    _security = SecurityController(
      _scanner,
      _scanRepository,
      () => _settings.saveHistory,
    );
    _history = HistoryController(_scanRepository);
    _tools = ToolsController();

    _boot();
  }

  Future<void> _boot() async {
    try {
      // Threat data first so the very first scan already has the brand rules.
      await _threatData.load();
      await _settings.load();
    } catch (error) {
      if (mounted) setState(() => _startupError = error.toString());
      return;
    }
    _device.refresh();
    _storage.checkStorageAccess();
    // Weekly refresh of scam phrases / app lists from the project's own JSON.
    _threatData.maybeRefresh().then((_) {
      if (_scanner.hasScanned) _scanner.reassess();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have just come back from a Settings screen.
      _storage.checkStorageAccess();
      _device.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.dispose();
    _threatData.dispose();
    _scanner.dispose();
    _storage.dispose();
    _device.dispose();
    _apk.dispose();
    _ocr.dispose();
    _security.dispose();
    _history.dispose();
    _tools.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: _database),
        Provider<SettingsRepository>.value(value: _settingsRepository),
        Provider<ScanRepository>.value(value: _scanRepository),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        ChangeNotifierProvider<ThreatDataService>.value(value: _threatData),
        ChangeNotifierProvider<AppScannerService>.value(value: _scanner),
        ChangeNotifierProvider<StorageService>.value(value: _storage),
        ChangeNotifierProvider<DeviceService>.value(value: _device),
        ChangeNotifierProvider<ApkAnalyzerService>.value(value: _apk),
        ChangeNotifierProvider<OcrService>.value(value: _ocr),
        ChangeNotifierProvider<SecurityController>.value(value: _security),
        ChangeNotifierProvider<HistoryController>.value(value: _history),
        ChangeNotifierProvider<ToolsController>.value(value: _tools),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Jemixo Safe',
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: _startupError != null
                ? _StartupError(message: _startupError!)
                : !settings.isLoaded
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : !settings.onboardingComplete
                ? const WelcomePage()
                : const MainShell(),
          );
        },
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Jemixo Safe could not open its local database.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
