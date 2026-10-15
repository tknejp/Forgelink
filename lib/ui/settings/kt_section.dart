import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import 'kt_controller.dart';
import '../widgets/issue_notice.dart';

class KtSection extends StatefulWidget {
  const KtSection({super.key});

  @override
  State<KtSection> createState() => _KtSectionState();
}

class _KtSectionState extends State<KtSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _editing = false;
  bool _missingFields = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(KtController c) async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _missingFields = true);
      return;
    }
    setState(() => _missingFields = false);
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.l10n.ktLoginSuccess;
    final ok = await c.login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      _password.clear();
      setState(() => _editing = false);
      messenger.showSnackBar(SnackBar(content: Text(successText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<KtController>();
    final hasStored = c.status.state != IntegrationState.notConfigured;
    final showForm = !hasStored || _editing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.status.issue case final issue?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IssueNotice(issue: issue, isError: true),
          ),
        if (c.storedEmail != null && hasStored)
          Text(l10n.ktSignedInAs(c.storedEmail!)),
        if (showForm) ...[
          if (hasStored) const SizedBox(height: 12),
          TextField(
            controller: _email,
            enabled: !c.busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.ktEmailLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            enabled: !c.busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l10n.ktPasswordLabel),
            onSubmitted: (_) => _submit(c),
          ),
          if (_missingFields)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.ktFieldsRequired,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (c.lastAttemptIssue != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: IssueNotice(issue: c.lastAttemptIssue!, isError: true),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: c.busy ? null : () => _submit(c),
                child: c.busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.ktLoginButton),
              ),
              if (_editing) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: c.busy
                      ? null
                      : () => setState(() {
                            _editing = false;
                            _password.clear();
                          }),
                  child: Text(l10n.ktCancel),
                ),
              ],
            ],
          ),
        ] else
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _editing = true;
                  _email.text = c.storedEmail ?? '';
                }),
                child: Text(l10n.ktChangeCredentials),
              ),
              TextButton(
                onPressed: c.busy ? null : c.logout,
                child: Text(l10n.ktLogoutButton),
              ),
            ],
          ),
      ],
    );
  }
}
