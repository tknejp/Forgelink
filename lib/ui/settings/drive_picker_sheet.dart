import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sheets/drive_chooser.dart';
import '../sync_text.dart';
import '../widgets/issue_notice.dart';

/// Bottom sheet listing the account's spreadsheets; returns the picked ID.
Future<String?> showDrivePicker(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _DrivePicker(),
    );

class _DrivePicker extends StatefulWidget {
  const _DrivePicker();

  @override
  State<_DrivePicker> createState() => _DrivePickerState();
}

class _DrivePickerState extends State<_DrivePicker> {
  List<DriveSpreadsheet>? _files;
  SyncIssue? _issue;
  bool _loading = true;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load(String term) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _issue = null;
    });
    try {
      final files = await context.read<DriveChooser>().list(nameContains: term);
      if (!mounted || id != _request) return;
      setState(() => _files = files);
    } on SyncIssueException catch (e) {
      if (!mounted || id != _request) return;
      setState(() => _issue = e.issue);
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  void _onSearch(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(term));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = SyncText(l10n);
    final files = _files ?? const <DriveSpreadsheet>[];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.driveChooserTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                autofocus: false,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: l10n.driveSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading) const LinearProgressIndicator(),
              if (_issue != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IssueNotice(issue: _issue!, isError: true),
                ),
              Expanded(
                child: !_loading && _issue == null && files.isEmpty
                    ? Center(child: Text(l10n.driveEmpty))
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (_, i) {
                          final f = files[i];
                          final subtitle = [
                            if (f.owner != null && f.modified != null)
                              l10n.driveOwnerModified(
                                f.owner!,
                                text.when(
                                  f.modified!.toLocal(),
                                  now: DateTime.now(),
                                ),
                              ),
                            if (!f.canEdit) l10n.driveReadOnly,
                          ].join(' · ');
                          return ListTile(
                            enabled: f.canEdit,
                            leading: Icon(
                              Icons.table_chart_outlined,
                              color: f.canEdit
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                            title: Text(f.name),
                            subtitle: subtitle.isEmpty ? null : Text(subtitle),
                            onTap: () => Navigator.of(context).pop(f.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
