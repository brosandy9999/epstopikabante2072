import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eps_topik_app/core/services/cloud_sync_service.dart';

void main() {
  test('Export master sync dataset to data/eps_sync_data.json', () {
    final payload = CloudSyncService.instance.generateFullSyncPayload(channelId: 'epstopikabante2072_main');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = Directory('data');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('data/eps_sync_data.json').writeAsStringSync(jsonStr);

    final docsDir = Directory('docs/data');
    if (!docsDir.existsSync()) {
      docsDir.createSync(recursive: true);
    }
    File('docs/data/eps_sync_data.json').writeAsStringSync(jsonStr);

    expect(File('data/eps_sync_data.json').existsSync(), true);
    expect(File('docs/data/eps_sync_data.json').existsSync(), true);
  });
}
