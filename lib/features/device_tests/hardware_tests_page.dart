import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/haptics.dart';
import '../../services/device_service/device_service.dart';
import '../../services/platform/native_models.dart';
import '../../widgets/app_widgets.dart';

/// Hardware tests that verify a sensor actually reports plausible data.
///
/// Every test states what a real result looks like and what a failure means,
/// so a "fail" is understood as "the sensor is not reporting", never as a
/// judgement about the device's health.
class HardwareTestsPage extends StatefulWidget {
  const HardwareTestsPage({super.key});

  @override
  State<HardwareTestsPage> createState() => _HardwareTestsPageState();
}

class _HardwareTestsPageState extends State<HardwareTestsPage> {
  final Map<String, HardwareTestResult> _results = {};
  final List<StreamSubscription> _subscriptions = [];
  late final DeviceService _device;
  String? _runningId;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _device = context.read<DeviceService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_device.sensors.isEmpty) _device.refresh();
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    // Never leave the torch burning after the screen closes.
    if (_torchOn) _device.setFlash(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final theme = Theme.of(context);
    final s = Strings.of(context);

    final tests = <HardwareTest>[
      HardwareTest(
        id: 'accelerometer',
        title: s.isHindi ? 'एक्सीलेरोमीटर' : 'Accelerometer',
        description: s.isHindi
            ? 'टेस्ट के दौरान फ़ोन को किसी भी दिशा में हिलाएं। मान बदलने चाहिए।'
            : 'Move the phone in any direction while the test runs. Values '
                'should change and settle near gravity (about 9.8) when it is '
                'lying flat.',
        available: device.hasAccelerometer,
      ),
      HardwareTest(
        id: 'gyroscope',
        title: s.isHindi ? 'जाइरोस्कोप' : 'Gyroscope',
        description: s.isHindi
            ? 'फ़ोन को धीरे-धीरे घुमाएँ। घुमाते समय रोटेशन मान बदलना चाहिए।'
            : 'Twist the phone slowly. Rotation readings should change '
                'while turning and hold steady when still.',
        available: device.hasGyroscope,
      ),
      HardwareTest(
        id: 'magnetometer',
        title: s.isHindi ? 'कंपास' : 'Compass',
        description: s.isHindi
            ? 'फ़ोन को आठ (8) के आकार में घुमाएँ। चुंबकीय शक्ति बदलनी चाहिए।'
            : 'Sweep the phone around in a figure of eight. The field '
                'strength should change as the phone turns.',
        available: device.hasCompass,
      ),
      HardwareTest(
        id: 'proximity',
        title: s.isHindi ? 'प्रॉक्सिमिटी सेंसर' : 'Proximity sensor',
        description: s.isHindi
            ? 'टेस्ट के दौरान फ़ोन के ऊपरी हिस्से को हथेली से ढकें। मान "पास" और "दूर" होना चाहिए।'
            : 'Cover the top of the phone with your palm during the test. '
                'The reading should drop to "near" and return to "far".',
        available: device.hasProximity,
      ),
      HardwareTest(
        id: 'light',
        title: s.isHindi ? 'लाइट सेंसर' : 'Light sensor',
        description: s.isHindi
            ? 'सेंसर को ढकें, फिर रोशनी की ओर करें। लक्स रीडिंग घटनी और बढ़नी चाहिए।'
            : 'Cover the sensor, then point the phone at a light. The lux '
                'reading should fall and rise.',
        available: device.hasLightSensor,
      ),
      HardwareTest(
        id: 'barometer',
        title: s.isHindi ? 'बैरोमीटर' : 'Barometer',
        description: s.isHindi
            ? 'दबाव 300 से 1200 hPa के बीच होना चाहिए।'
            : 'The pressure reading should sit between 300 and 1200 hPa. Only '
                'some phones have this sensor.',
        available: device.hasBarometer,
      ),
      HardwareTest(
        id: 'flash',
        title: s.isHindi ? 'टॉर्च' : 'Flashlight',
        description: s.isHindi
            ? 'टॉर्च चालू करके देखें कि कैमरे की LED जलती है या नहीं।'
            : 'Toggle the torch. It should light up immediately.',
        available: device.hasFlash,
      ),
    ];

    return AppPageScaffold(
      title: s.hardwareTestsTitle,
      subtitle: s.isHindi
          ? '${tests.length} में से ${tests.where((t) => t.available).length} उपलब्ध'
          : '${tests.where((t) => t.available).length} of ${tests.length} available',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          InfoBanner(
            title: s.isHindi ? 'ये टेस्ट क्या बताते हैं' : 'What these tests can tell you',
            message: s.isHindi
                ? 'ये पुष्टि करते हैं कि सेंसर सही डेटा दे रहे हैं। किसी टेस्ट का फ़ेल होना अक्सर सॉफ़्टवेयर या ड्राइवर की कमी होता है।'
                : 'They confirm a sensor is reporting plausible values. A failure '
                    'here is often a missing driver, not a broken device.',
            icon: Icons.build_circle_outlined,
          ),
          const SizedBox(height: AppSpacing.standard),
          for (final test in tests)
            _TestCard(
              test: test,
              result: _results[test.id],
              running: _runningId == test.id,
              busy: _runningId != null,
              torchOn: test.id == 'flash' && _torchOn,
              onRun: () => _run(test),
            ),
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(
            text:
                'Sensor readings are diagnostic. Always confirm a problem with '
                'the manufacturer or an authorised service centre.',
          ),
          const SizedBox(height: AppSpacing.tight),
          Text(
            'Sensors run only while a test is active.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(HardwareTest test) async {
    if (_runningId != null) return;
    AppHaptics.tap(context);
    switch (test.id) {
      case 'accelerometer':
        await _sample(
          test,
          accelerometerEventStream(),
          (event) =>
              '${event.x.toStringAsFixed(2)}, '
              '${event.y.toStringAsFixed(2)}, ${event.z.toStringAsFixed(2)} m/s²',
          (event) =>
              math.sqrt(
                event.x * event.x + event.y * event.y + event.z * event.z,
              ) >
              1,
        );
      case 'gyroscope':
        await _sample(
          test,
          gyroscopeEventStream(),
          (event) =>
              '${event.x.toStringAsFixed(2)}, '
              '${event.y.toStringAsFixed(2)}, ${event.z.toStringAsFixed(2)} rad/s',
          (event) =>
              math.sqrt(
                event.x * event.x + event.y * event.y + event.z * event.z,
              ) >
              0.05,
        );
      case 'magnetometer':
        await _sample(
          test,
          magnetometerEventStream(),
          (event) =>
              '${math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z).toStringAsFixed(1)} µT',
          (event) => event.x.abs() + event.y.abs() + event.z.abs() > 1,
        );
      case 'barometer':
        await _sample(
          test,
          barometerEventStream(),
          (event) => '${event.pressure.toStringAsFixed(2)} hPa',
          (event) => event.pressure > 300 && event.pressure < 1200,
        );
      case 'proximity':
        await _sampleNative(
          test,
          SensorTypes.proximity,
          (sample) {
            final range = sample.maxRange ?? 5;
            final near = (sample.min ?? range) < range;
            final far = (sample.max ?? 0) >= range;
            return near && far
                ? 'Detected near and far'
                : near
                ? 'Only "near" seen — try uncovering the sensor'
                : 'Only "far" seen — try covering the sensor';
          },
          (sample) =>
              sample.min != null &&
              sample.max != null &&
              sample.min! < (sample.maxRange ?? 5) &&
              sample.max! >= (sample.maxRange ?? 5),
        );
      case 'light':
        await _sampleNative(
          test,
          SensorTypes.light,
          (sample) =>
              '${sample.min?.toStringAsFixed(0) ?? '?'} – ${sample.max?.toStringAsFixed(0) ?? '?'} lux',
          (sample) =>
              sample.min != null &&
              sample.max != null &&
              (sample.max! - sample.min!) > 5,
        );
      case 'flash':
        await _toggleFlash();
    }
  }

  /// Collects samples for a few seconds and reports whether any of them looked
  /// plausible. A sensor that never fires is reported as "no data".
  Future<void> _sample<T>(
    HardwareTest test,
    Stream<T> stream,
    String Function(T event) format,
    bool Function(T event) plausible,
  ) async {
    setState(() => _runningId = test.id);
    var readings = 0;
    var plausibleCount = 0;
    var sample = '';
    final completer = Completer<void>();
    late final StreamSubscription subscription;

    subscription = stream.listen(
      (event) {
        readings++;
        sample = format(event);
        if (plausible(event)) plausibleCount++;
        if (readings >= 40 && !completer.isCompleted) completer.complete();
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    _subscriptions.add(subscription);

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    await subscription.cancel();
    _subscriptions.remove(subscription);
    if (!mounted) return;

    setState(() {
      _runningId = null;
      _results[test.id] = HardwareTestResult(
        status: readings == 0
            ? TestStatus.noData
            : plausibleCount > 0
            ? TestStatus.passed
            : TestStatus.noChange,
        detail: readings == 0
            ? 'No data received from this sensor.'
            : 'Last reading: $sample',
        readings: readings,
      );
    });
  }

  Future<void> _sampleNative(
    HardwareTest test,
    int type,
    String Function(SensorSample sample) format,
    bool Function(SensorSample sample) plausible,
  ) async {
    setState(() => _runningId = test.id);
    final sample = await _device.sampleSensor(type, durationMs: 5000);
    if (!mounted) return;
    setState(() {
      _runningId = null;
      _results[test.id] = HardwareTestResult(
        status: !sample.available || sample.readings == 0
            ? TestStatus.noData
            : plausible(sample)
            ? TestStatus.passed
            : TestStatus.noChange,
        detail: !sample.available || sample.readings == 0
            ? 'No data received from this sensor.'
            : format(sample),
        readings: sample.readings,
      );
    });
  }

  Future<void> _toggleFlash() async {
    final next = !_torchOn;
    final result = await _device.setFlash(next);
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _torchOn = false;
        _results['flash'] = const HardwareTestResult(
          status: TestStatus.noData,
          detail:
              'Android refused torch control. Close the camera app if it is open.',
          readings: 0,
        );
        return;
      }
      _torchOn = result;
      _results['flash'] = HardwareTestResult(
        status: TestStatus.passed,
        detail: result
            ? 'Torch is on. Tap again to switch it off.'
            : 'Torch switched off.',
        readings: 1,
      );
    });
  }
}

class HardwareTest {
  const HardwareTest({
    required this.id,
    required this.title,
    required this.description,
    required this.available,
  });

  final String id;
  final String title;
  final String description;
  final bool available;
}

enum TestStatus { passed, noChange, noData }

class HardwareTestResult {
  const HardwareTestResult({
    required this.status,
    required this.detail,
    required this.readings,
  });

  final TestStatus status;
  final String detail;
  final int readings;

  RiskLevel get level => switch (status) {
    TestStatus.passed => RiskLevel.safe,
    TestStatus.noChange => RiskLevel.medium,
    TestStatus.noData => RiskLevel.high,
  };

  String get label => switch (status) {
    TestStatus.passed => 'Working',
    TestStatus.noChange => 'No change detected',
    TestStatus.noData => 'No data',
  };
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.result,
    required this.onRun,
    required this.running,
    required this.busy,
    this.torchOn = false,
  });

  final HardwareTest test;
  final HardwareTestResult? result;
  final VoidCallback onRun;
  final bool running;
  final bool busy;
  final bool torchOn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = result?.level ?? RiskLevel.low;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(test.title, style: AppTypography.cardTitle)),
              if (!test.available)
                const StatusPill(
                  label: 'Not present',
                  color: AppColors.info,
                  dense: true,
                )
              else if (running)
                const StatusPill(
                  label: 'Testing…',
                  color: AppColors.royalBlue,
                  dense: true,
                )
              else if (result != null)
                StatusPill(
                  label: result!.label,
                  color: RiskPalette.color(context, status),
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            test.description,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!test.available) ...[
            const SizedBox(height: AppSpacing.tight),
            Text(
              'Android did not report this hardware on your device.',
              style: AppTypography.small.copyWith(color: AppColors.info),
            ),
          ],
          if (result != null && !running) ...[
            const SizedBox(height: AppSpacing.tight),
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: RiskPalette.color(context, status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.id == 'flash'
                        ? result!.detail
                        : '${result!.detail} (${result!.readings} samples)',
                    style: AppTypography.small.copyWith(
                      color: RiskPalette.color(context, status),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (test.available) ...[
            const SizedBox(height: AppSpacing.tight),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy && !running ? null : (running ? null : onRun),
                icon: running
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        test.id == 'flash'
                            ? (torchOn
                                  ? Icons.flashlight_off_rounded
                                  : Icons.flashlight_on_rounded)
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                label: Text(
                  test.id == 'flash'
                      ? (torchOn ? 'Turn torch off' : 'Turn torch on')
                      : running
                      ? 'Testing for 5 seconds…'
                      : 'Run test',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
