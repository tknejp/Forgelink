import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import '../widgets/issue_notice.dart';
import '../widgets/section_card.dart';
import 'kt_controller.dart';

class KtSection extends StatefulWidget {
  const KtSection({super.key});

  @override
  State<KtSection> createState() => _KtSectionState();
}

class _KtSectionState extends State<KtSection> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<KtController>();
    final hasStored = c.status.state != IntegrationState.notConfigured;
    final showForm = !hasStored || _editing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!showForm) ...[
          KvRow(l10n.rowAccount, c.storedEmail ?? '—'),
          KvRow(l10n.rowReads, l10n.ktReadsValue),
        ],
        if (c.status.issue case final issue?) ...[
          const SizedBox(height: 10),
          IssueNotice(issue: issue, isError: true),
        ],
        if (showForm)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: KtLoginForm(
              initialEmail: c.storedEmail,
              onCancel: _editing
                  ? () => setState(() => _editing = false)
                  : null,
              onSuccess: () {
                setState(() => _editing = false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.ktLoginSuccess)));
              },
            ),
          )
        else
          CardActions([
            CardAction(
              label: l10n.ktChangeCredentials,
              icon: Icons.edit_rounded,
              onPressed: () => setState(() => _editing = true),
            ),
            CardAction(
              label: l10n.ktLogoutButton,
              icon: Icons.logout_rounded,
              onPressed: c.busy ? null : c.logout,
            ),
          ]),
      ],
    );
  }
}

/// E-mail + password form with validation and the login result; shared by
/// Settings and onboarding.
class KtLoginForm extends StatefulWidget {
  const KtLoginForm({
    super.key,
    this.initialEmail,
    this.onCancel,
    this.onSuccess,
    this.showButton = true,
    this.controller,
  });

  final String? initialEmail;
  final VoidCallback? onCancel;
  final VoidCallback? onSuccess;

  /// False when the caller drives submission through [controller].
  final bool showButton;
  final KtLoginFormController? controller;

  @override
  State<KtLoginForm> createState() => _KtLoginFormState();
}

/// Lets a parent (onboarding's main button) submit the form.
class KtLoginFormController {
  Future<bool> Function()? _submit;
  Future<bool> submit() => _submit?.call() ?? Future.value(false);
}

class _KtLoginFormState extends State<KtLoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _missingFields = false;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail ?? '';
    widget.controller?._submit = _submit;
  }

  @override
  void dispose() {
    widget.controller?._submit = null;
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    final c = context.read<KtController>();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _missingFields = true);
      return false;
    }
    setState(() => _missingFields = false);
    final ok = await c.login(_email.text, _password.text);
    if (!mounted) return ok;
    if (ok) {
      _password.clear();
      widget.onSuccess?.call();
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<KtController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          enabled: !c.busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: l10n.ktEmailLabel,
            hintText: l10n.onbEmailHint,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          enabled: !c.busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.ktPasswordLabel),
          onSubmitted: (_) => _submit(),
        ),
        if (_missingFields)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_rounded, size: 18, color: p.err),
                const SizedBox(width: 8),
                Text(
                  l10n.ktFieldsRequired,
                  style: TextStyle(fontSize: 13, color: p.err),
                ),
              ],
            ),
          ),
        if (c.lastAttemptIssue != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IssueNotice(issue: c.lastAttemptIssue!, isError: true),
          ),
        if (widget.showButton)
          CardActions([
            CardAction(
              label: l10n.ktLoginButton,
              icon: Icons.login_rounded,
              primary: true,
              busy: c.busy,
              onPressed: _submit,
            ),
            if (widget.onCancel != null)
              CardAction(
                label: l10n.ktCancel,
                icon: Icons.close_rounded,
                onPressed: c.busy ? null : widget.onCancel,
              ),
          ]),
      ],
    );
  }
}
