import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../issue_presenter.dart';
import 'sheet_controller.dart';
import '../widgets/issue_notice.dart';

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
        if (c.status.issue case final issue?
            when c.status.state != IntegrationState.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IssueNotice(issue: issue),
          ),
        TextField(
          controller: _input,
          enabled: !c.busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.sheetUrlLabel,
            errorText: c.invalidInput ? l10n.sheetInvalidId : null,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _tab,
          enabled: !c.busy,
          decoration: InputDecoration(labelText: l10n.sheetTabLabel),
        ),
        if (c.lastIssue != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IssueNotice(issue: c.lastIssue!, isError: true),
          ),
        if (v != null) ...[
          const SizedBox(height: 10),
          Text(v.days == 0
              ? l10n.sheetVerifyNoDates
              : l10n.sheetVerifyResult(
                  v.weekTables,
                  v.days,
                  presenter.formatDate(v.first!),
                  presenter.formatDate(v.last!),
                )),
        ],
        if (v != null && v.duplicates.isNotEmpty) ...[
          const SizedBox(height: 4),
          Builder(builder: (_) {
            final dates = v.duplicates.keys.toList()..sort();
            final rows = (v.duplicates.values.expand((r) => r).toSet().toList()
                  ..sort())
                .join(', ');
            return Text(
              l10n.sheetDuplicates(dates.length, presenter.formatDate(dates.first),
                  presenter.formatDate(dates.last), rows),
              style: errorStyle,
            );
          }),
        ],
        if (readOk && c.status.state != IntegrationState.verified)
          Text(l10n.sheetEditAccessNote,
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
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
