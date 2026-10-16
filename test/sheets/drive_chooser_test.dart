import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/core/sync_issue_codec.dart';
import 'package:forgelink/sheets/drive_chooser.dart';

void main() {
  const base =
      "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false";

  test('no search term → all spreadsheets', () {
    expect(DriveChooser.query(''), base);
    expect(DriveChooser.query('   '), base);
  });

  test('search term is added as name contains', () {
    expect(DriveChooser.query(' nutri '), "$base and name contains 'nutri'");
  });

  test('quotes and backslashes are escaped', () {
    expect(
      DriveChooser.query(r"Tom's \plan"),
      "$base and name contains 'Tom\\'s \\\\plan'",
    );
  });

  test('DriveApiDisabled persists', () {
    final back = SyncIssueCodec.decode(
      SyncIssueCodec.encode(const DriveApiDisabled()),
    );
    expect(back, isA<DriveApiDisabled>());
  });
}
