// Tests of the local store the client persists messages in (drift, on
// SQLite).
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:unitdb_client/src/store/unitdb_api_store.dart';
import 'package:unitdb_client/unitdb_client.dart';

void main() {
  test('keeps, returns and deletes a message', () async {
    // A database file of its own, in the working directory.
    final user = 'store-test-$pid';
    final store = Store();
    await store.connect(user, reset: true);
    addTearDown(() async {
      await store.disconnect();
      final file = File('db_$user.sqlite');
      if (file.existsSync()) file.deleteSync();
    });

    final pub = Publish(
        7,
        [PublishMessage('store.topic', Uint8List.fromList([1, 2, 3]), '1h')],
        DeliveryMode.reliable);
    await store.persistOutbound(1, pub);
    expect(await store.keys(), [7]);

    final got = await store.getMessage(1, 7);
    expect(got, isA<Publish>());
    final message = (got as Publish).messages.single;
    expect(message.topic, 'store.topic');
    expect(message.payload, [1, 2, 3]);
    expect(await store.getMessage(2, 7), isNull,
        reason: 'another session has no message 7');

    await store.deleteMessage(1, 7);
    expect(await store.keys(), isEmpty);
    expect(await store.getMessage(1, 7), isNull);
  });
}
