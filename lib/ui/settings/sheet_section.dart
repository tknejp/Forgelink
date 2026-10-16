import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../issue_presenter.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import '../widgets/issue_notice.dart';
import '../widgets/section_card.dart';
import 'drive_picker_sheet.dart';
import 'sheet_controller.dart';

class SheetSection extends StatelessWidget {
  const SheetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SheetController>();
    final presenter = IssuePresenter(l10n);

    final v = c.verification;
    final readOk =
        c.status.state == IntegrationState.readVerified ||
        c.status.state == IntegrationState.verified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.title case final t?) KvRow(l10n.rowSheetFile, t),
        KvRow(l10n.rowSheetId, c.spreadsheetId ?? '—', mono: true),
        KvRow(l10n.rowTab, c.tab),
        if (v != null)
          KvRow(
            l10n.rowCoverage,
            v.days == 0
                ? l10n.sheetVerifyNoDates
                : l10n.sheetCoverage(
                    v.weekTables,
                    presenter.formatDate(v.first!),
                    presenter.formatDate(v.last!),
                  ),
          ),
        if (c.status.issue case final issue?
            when c.status.state != IntegrationState.error) ...[
          const SizedBox(height: 10),
          IssueNotice(issue: issue),
        ],
        if (c.lastIssue != null) ...[
          const SizedBox(height: 10),
          IssueNotice(issue: c.lastIssue!, isError: true),
        ],
        if (v != null && v.duplicates.isNotEmpty)
          Builder(
            builder: (_) {
              final dates = v.duplicates.keys.toList()..sort();
              final rows =
                  (v.duplicates.values.expand((r) => r).toSet().toList()
                        ..sort())
                      .join(', ');
              return CardNote(
                l10n.sheetDuplicates(
                  dates.length,
                  presenter.formatDate(dates.first),
                  presenter.formatDate(dates.last),
                  rows,
                ),
                color: p.err,
              );
            },
          ),
        if (readOk && c.status.state != IntegrationState.verified)
          CardNote(l10n.sheetEditAccessNote),
        CardActions([
          if (c.googleConnected)
            CardAction(
              label: l10n.sheetPickDrive,
              icon: Icons.folder_open_rounded,
              primary: c.spreadsheetId == null,
              onPressed: c.busy
                  ? null
                  : () async {
                      final id = await showDrivePicker(context);
                      if (id == null) return;
                      await c.saveAndVerify(id, c.tab);
                    },
            ),
          CardAction(
            label: l10n.sheetEditManual,
            icon: Icons.edit_rounded,
            onPressed: c.busy ? null : () => showSheetEditor(context),
          ),
          if (c.spreadsheetId != null && c.googleConnected)
            CardAction(
              label: l10n.sheetVerify,
              icon: Icons.fact_check_rounded,
              busy: c.busy,
              onPressed: c.verify,
            ),
        ]),
      ],
    );
  }
}

/// "Upravit tabulku": link or ID + tab, saved and verified on confirm.
Future<void> showSheetEditor(BuildContext context) =>
    showDesignSheet<void>(context, builder: (_) => const _SheetEditor());

class _SheetEditor extends StatefulWidget {
  const _SheetEditor();

  @override
  State<_SheetEditor> createState() => _SheetEditorState();
}

class _SheetEditorState extends State<_SheetEditor> {
  final _input = TextEditingController();
  final _tab = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = context.read<SheetController>();
    _input.text = c.spreadsheetId ?? '';
    _tab.text = c.tab;
  }

  @override
  void dispose() {
    _input.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = context.read<SheetController>();
    await c.saveAndVerify(_input.text, _tab.text);
    if (!mounted) return;
    if (!c.invalidInput && c.lastIssue == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<SheetController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sheetEditTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _input,
          enabled: !c.busy,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 13),
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
        if (c.lastIssue != null) ...[
          const SizedBox(height: 10),
          IssueNotice(issue: c.lastIssue!, isError: true),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            SoftButton(
              label: l10n.ktCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: c.busy ? null : _save,
                child: c.busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.sheetSaveVerify),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
