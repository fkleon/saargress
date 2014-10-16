import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:saargress/saargress_server.dart' show SlackImporter, SlackDatabase, SlackLog, SlackMessage;

void main() {
  group('SlackImporter', () {
    test('import (sucess)', () => _shouldImport());
    test('import (fail)', () => _shouldFailToImport());
  });
  group('SlackDatabase', () {
    test('search by name', () => _shouldSearchLogByName());
  });
  group('SlackLog', () {
    test('search by text', () => _shouldSearchMessageByText());
  });
}

void _shouldImport() {
  String testDataDir = '../data/';
  expect(
    SlackImporter.buildFromDir(testDataDir).then((sdb) {
      expect(sdb.logs.length, equals(1));
      expect(sdb.users.length, equals(2));
      expect(sdb.findLogByName('test'), isNotNull);
      expect(sdb.findLogByName('test').searchByText('a message'), hasLength(equals(1)));
  }), completes);
}

void _shouldFailToImport() {
  String invalidDataDir = '\invalid\asfas';
  expect(SlackImporter.buildFromDir(invalidDataDir), throws);
}

void _shouldSearchLogByName() {
  expect(_getTestDatabase().then((sdb) {
    List<SlackLog> logs = sdb.searchLogByName('channel');
    expect(logs, isEmpty);
    logs = sdb.searchLogByName('test');
    expect(logs.length, equals(1));
  }), completes);
}

void _shouldSearchMessageByText() {
  SlackLog sl = _getSlackLog();
  List<SlackMessage> msgs = sl.searchByText('46437437');
  expect(msgs, isEmpty);
  msgs = sl.searchByText('message text');
  expect(msgs.length, equals(1));
}

/// Creates a dummy slack log with one message
SlackLog _getSlackLog() {
  var sl = new SlackLog.build('cID', name: 'channel');
  var sm = new SlackMessage.build('mID', text: 'message text', userId: 'uID', type: 'message');
  sl.messages.add(sm);
  return sl;
}

/// Creates a slack database with the test fixtures
Future<SlackDatabase> _getTestDatabase() {
  String testDataDir = '../data/';
  return SlackImporter.buildFromDir(testDataDir);
}