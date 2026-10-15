import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../issue_presenter.dart';
import 'sheet_controller.dart';
import 'status_line.dart';

class SheetSection extends StatefulWidget {
  const SheetSection({super.key});

  @override
  State<SheetSection> createState() => _SheetSectionState();
}

class _SheetSectionState extends State<SheetSection> {
  final _input = TextEditingController();
  final _tab = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _input.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<SheetController>();
    final presenter = IssuePresenter(l10n);
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);

    if (!_seeded && (c.spreadsheetId != null || c.tab.isNotEmpty)) {
      _input.text = c.spreadsheetId ?? '';
      _tab.text = c.tab;
      _seeded = true;
    }

    final v = c.verification;
    final readOk = c.status.state == IntegrationState.readVerified ||
        c.status.state == IntegrationState.verified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusLine(status: c.status),
        const SizedBox(height: 8),
        TextField(
          controller: _input,
          enabled: !c.busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.sheetUrlLabel,
            errorText: c.invalidInput ? l10n.sheetInvalidId : null,
          ),
        ),
        TextField(
          controller: _tab,
          enabled: !c.busy,
          decoration: InputDecoration(labelText: l10n.sheetTabLabel),
        ),
        if (!c.googleConnected)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.sheetNeedsGoogle,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        if (c.lastIssue != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(presenter.message(c.lastIssue!), style: errorStyle),
          ),
        if (v != null) ...[
          const SizedBox(height: 4),
          Text(v.days == 0
              ? l10n.sheetVerifyNoDates
              : l10n.sheetVerifyResult(
                  v.weekTables,
                  v.days,
                  presenter.formatDate(v.first!),
                  presenter.formatDate(v.last!),
                )),
        ],
        if (readOk && c.status.state != IntegrationState.verified)
          Text(l10n.sheetEditAccessNote,
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: c.busy
              ? null
              : () => c.saveAndVerify(_input.text, _tab.text),
          child: c.busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.sheetSaveVerify),
        ),
      ],
    );
  }
}
