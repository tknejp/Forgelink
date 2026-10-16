import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/prefs_store.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sources/health/hc_read_client.dart';
import '../../sync/integration_status.dart';
import '../home/home_screen.dart';
import '../settings/auto_sync_controller.dart';
import '../settings/drive_picker_sheet.dart';
import '../settings/google_controller.dart';
import '../settings/health_connect_controller.dart';
import '../settings/kt_controller.dart';
import '../settings/kt_section.dart';
import '../settings/sheet_controller.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import '../widgets/issue_notice.dart';

/// First launch: welcome → Health Connect → Kalorické tabulky → Google +
/// sheet → automatic sync. Every step uses the same controllers as
/// Settings, so anything skipped here can be finished there later.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const _steps = 5;
  int _step = 0;
  bool _working = false;
  final _ktForm = KtLoginFormController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Permissions are granted in Health Connect's own screens.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<HealthConnectController>().refresh();
    context.read<KtController>().load();
    context.read<GoogleController>().load();
    context.read<SheetController>().load();
    context.read<AutoSyncController>().load();
  }

  void _go(int step) => setState(() => _step = step.clamp(0, _steps - 1));

  Future<void> _busy(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _finish() async {
    await context.read<PrefsStore>().setOnboardingDone();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  bool _hcComplete(HealthConnectController hc) =>
      hc.availability == HcAvailability.available &&
      hc.missing.isEmpty &&
      (!hc.historyAvailable || hc.historyAuthorized) &&
      (!hc.backgroundAvailable || hc.backgroundAuthorized);

  bool _ktDone(KtController kt) =>
      kt.status.state != IntegrationState.notConfigured &&
      kt.status.state != IntegrationState.error;

  bool _sheetDone(SheetController s) =>
      s.spreadsheetId != null &&
      (s.status.state == IntegrationState.readVerified ||
          s.status.state == IntegrationState.verified);

  /// Label and action of the main button for the current step.
  (String, Future<void> Function()?) _main(BuildContext context) {
    final l10n = context.l10n;
    final hc = context.watch<HealthConnectController>();
    final kt = context.watch<KtController>();
    final google = context.watch<GoogleController>();
    final sheet = context.watch<SheetController>();

    switch (_step) {
      case 0:
        return (l10n.onbStart, () async => _go(1));
      case 1:
        if (!hc.loaded) return (l10n.onbContinue, null);
        if (hc.availability != HcAvailability.available) {
          return (l10n.onbInstallHc, hc.install);
        }
        if (_hcComplete(hc)) return (l10n.onbContinue, () async => _go(2));
        return (
          l10n.actionGrantPermissions,
          () async {
            if (hc.missing.isNotEmpty) await hc.grantPermissions();
            if (hc.historyAvailable && !hc.historyAuthorized) {
              await hc.grantHistory();
            }
            if (hc.backgroundAvailable && !hc.backgroundAuthorized) {
              await hc.grantBackground();
            }
          },
        );
      case 2:
        if (_ktDone(kt)) return (l10n.onbContinue, () async => _go(3));
        return (
          l10n.ktLoginButton,
          kt.busy ? null : () async => _ktForm.submit(),
        );
      case 3:
        if (google.email == null) {
          return (
            l10n.onbGoogleButton,
            google.busy
                ? null
                : () async {
                    await google.connect();
                    if (context.mounted) {
                      await context.read<SheetController>().load();
                    }
                  },
          );
        }
        if (!_sheetDone(sheet)) {
          return (
            l10n.onbPickSheet,
            sheet.busy
                ? null
                : () async {
                    final id = await showDrivePicker(context);
                    if (id != null) await sheet.saveAndVerify(id, sheet.tab);
                  },
          );
        }
        return (l10n.onbContinue, () async => _go(4));
      default:
        return (l10n.onbFinish, _finish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final (label, action) = _main(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 96,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox.square(
                        dimension: 48,
                        child: _step == 0
                            ? null
                            : IconButton(
                                tooltip: l10n.actionBack,
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () => _go(_step - 1),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _steps; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _step ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i <= _step ? p.accent : p.line,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 104,
                    child: _step >= 1 && _step <= 3
                        ? TextButton(
                            onPressed: () => _go(_step + 1),
                            child: Text(l10n.onbSkip),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                children: [
                  switch (_step) {
                    0 => const _Welcome(),
                    1 => const _HealthStep(),
                    2 => _KtStep(form: _ktForm),
                    3 => const _SheetStep(),
                    _ => const _DoneStep(),
                  },
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: BigButton(
                label: label,
                busy: _working,
                onPressed: action == null || _working
                    ? null
                    : () => _busy(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Steps ──────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, size: 56, radius: 18, iconSize: 30),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14.5, height: 1.5, color: p.muted),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Row with a title, a sub-line and a trailing widget (check icon, button).
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.sub,
    this.leading,
    this.trailing,
    this.last = false,
  });

  final String title;
  final String sub;
  final Widget? leading;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(sub, style: TextStyle(fontSize: 12.5, color: p.muted)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

Widget _check(BuildContext context, bool done) {
  final p = Palette.of(context);
  return Icon(
    done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
    size: 22,
    color: done ? p.ok : p.faint,
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final sources = [
      (
        Icons.favorite_rounded,
        l10n.settingsSectionHealthConnect,
        l10n.onbSourceHcSub,
      ),
      (Icons.restaurant_rounded, l10n.settingsSectionKt, l10n.onbSourceKtSub),
      (
        Icons.table_chart_rounded,
        l10n.onbSourceSheets,
        l10n.onbSourceSheetsSub,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-12, 0),
          child: Image.asset(
            'assets/branding/logo_fg_384.png',
            width: 112,
            height: 112,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onbWelcomeText,
          style: TextStyle(fontSize: 15, height: 1.5, color: p.muted),
        ),
        const SizedBox(height: 18),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < sources.length; i++)
                _ListRow(
                  leading: IconTile(
                    sources[i].$1,
                    size: 38,
                    radius: 12,
                    iconSize: 20,
                  ),
                  title: sources[i].$2,
                  sub: sources[i].$3,
                  last: i == sources.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.onbLocalNote,
          style: TextStyle(fontSize: 12.5, height: 1.45, color: p.muted),
        ),
      ],
    );
  }
}

class _HealthStep extends StatelessWidget {
  const _HealthStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hc = context.watch<HealthConnectController>();
    final available = hc.availability == HcAvailability.available;
    final perms = [
      (
        l10n.fieldLabelWeight,
        l10n.onbPermWeightSub,
        available && !hc.missing.contains(HcDataType.weight),
      ),
      (
        l10n.fieldLabelSteps,
        l10n.onbPermStepsSub,
        available && !hc.missing.contains(HcDataType.steps),
      ),
      if (hc.historyAvailable)
        (l10n.onbPermHistory, l10n.onbPermHistorySub, hc.historyAuthorized),
      if (hc.backgroundAvailable)
        (
          l10n.onbPermBackground,
          l10n.onbPermBackgroundSub,
          hc.backgroundAuthorized,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: Icons.favorite_rounded,
          title: l10n.settingsSectionHealthConnect,
          text: l10n.onbHcText,
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < perms.length; i++)
                _ListRow(
                  title: perms[i].$1,
                  sub: perms[i].$2,
                  trailing: _check(context, perms[i].$3),
                  last: i == perms.length - 1,
                ),
            ],
          ),
        ),
        if (hc.status.issue case final issue? when hc.loaded && !available) ...[
          const SizedBox(height: 14),
          IssueNotice(issue: issue),
        ],
      ],
    );
  }
}

class _KtStep extends StatelessWidget {
  const _KtStep({required this.form});

  final KtLoginFormController form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kt = context.watch<KtController>();
    final done =
        kt.status.state != IntegrationState.notConfigured &&
        kt.status.state != IntegrationState.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: Icons.restaurant_rounded,
          title: l10n.settingsSectionKt,
          text: l10n.onbKtText,
        ),
        if (done)
          Callout(text: l10n.onbKtOk, tone: Tone.ok)
        else
          KtLoginForm(
            initialEmail: kt.storedEmail,
            showButton: false,
            controller: form,
          ),
      ],
    );
  }
}

class _SheetStep extends StatelessWidget {
  const _SheetStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final google = context.watch<GoogleController>();
    final sheet = context.watch<SheetController>();
    final verified =
        sheet.spreadsheetId != null &&
        (sheet.status.state == IntegrationState.readVerified ||
            sheet.status.state == IntegrationState.verified);
    final issue = google.lastIssue ?? sheet.lastIssue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: Icons.table_chart_rounded,
          title: l10n.onbSheetTitle,
          text: l10n.onbSheetText,
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _ListRow(
                leading: _check(context, google.email != null),
                title: google.email ?? l10n.settingsSectionGoogle,
                sub: google.email == null
                    ? l10n.onbGoogleNotConnected
                    : l10n.onbGoogleAccess,
              ),
              _ListRow(
                leading: sheet.busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : _check(context, verified),
                title: l10n.settingsSectionSheet,
                sub: verified ? l10n.onbSheetOk(sheet.tab) : l10n.onbSheetNone,
                last: true,
              ),
            ],
          ),
        ),
        if (issue != null && issue is! GoogleNotConnected) ...[
          const SizedBox(height: 14),
          IssueNotice(issue: issue, isError: true),
        ],
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final auto = context.watch<AutoSyncController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.okBg, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 36, color: p.ok),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.onbDoneTitle,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onbDoneText,
          style: TextStyle(fontSize: 14.5, height: 1.5, color: p.muted),
        ),
        const SizedBox(height: 18),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ToggleRow(
            label: l10n.autoSyncSwitch,
            sub: l10n.autoSyncSub,
            value: auto.enabled,
            onChanged: auto.setEnabled,
            bottomBorder: false,
          ),
        ),
      ],
    );
  }
}
