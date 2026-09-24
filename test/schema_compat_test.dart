// Pins the wire format to the unitdb server's schema (server/proto/unitdb.proto
// in github.com/unit-io/unitdb). The client's schema.proto is a copy of it; if
// they drift apart the client can no longer talk to the server, so these tests
// check the gRPC service name and the field numbers the server reads.

import 'package:test/test.dart';
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/src/v1/unitdb/schema.pbgrpc.dart';

/// Returns the protobuf tag byte for a field number and wire type.
int tag(int field, int wireType) => (field << 3) | wireType;
const varint = 0, lengthDelimited = 2;

void main() {
  test('uses the server gRPC service', () {
    expect(_ServiceName().$name, 'unitdb.schema.Unitdb');
  });

  test('PublishMessage: Topic=1, Payload=2, Ttl=3', () {
    final b = (pbx.PublishMessage()..ttl = 'x').writeToBuffer();
    expect(b.first, tag(3, lengthDelimited));
  });

  test('RelayRequest: Topic=1, Last=2', () {
    final b = (pbx.RelayRequest()..last = 'x').writeToBuffer();
    expect(b.first, tag(2, lengthDelimited));
  });

  test('Relay: MessageID=1, RelayRequests=2', () {
    final b = (pbx.Relay()..relayRequests.add(pbx.RelayRequest())).writeToBuffer();
    expect(b.first, tag(2, lengthDelimited));
  });

  test('Connect: KeepAlive=4, SessKey=6, BatchDuration=9, BatchCountThreshold=11', () {
    expect((pbx.Connect()..keepAlive = 1).writeToBuffer().first, tag(4, varint));
    expect((pbx.Connect()..sessKey = 1).writeToBuffer().first, tag(6, varint));
    expect((pbx.Connect()..batchDuration = 1).writeToBuffer().first, tag(9, varint));
    expect((pbx.Connect()..batchCountThreshold = 1).writeToBuffer().first,
        tag(11, varint));
  });

  test('Publish: MessageID=1, DeliveryMode=2, Messages=3', () {
    expect((pbx.Publish()..deliveryMode = 1).writeToBuffer().first, tag(2, varint));
    expect((pbx.Publish()..messages.add(pbx.PublishMessage())).writeToBuffer().first,
        tag(3, lengthDelimited));
  });
}

class _ServiceName extends UnitdbServiceBase {
  @override
  Stream<pbx.Packet> stream(call, Stream<pbx.Packet> request) => request;
}
