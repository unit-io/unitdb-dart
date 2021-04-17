///
//  Generated code. Do not modify.
//  source: schema.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'schema.pb.dart' as $0;
export 'schema.pb.dart';

class UnitdbClient extends $grpc.Client {
  static final _$stream = $grpc.ClientMethod<$0.Packet, $0.Packet>(
      '/unitdb.schema.Unitdb/Stream',
      ($0.Packet value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Packet.fromBuffer(value));

  UnitdbClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseStream<$0.Packet> stream($async.Stream<$0.Packet> request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$stream, request, options: options);
  }
}

abstract class UnitdbServiceBase extends $grpc.Service {
  $core.String get $name => 'unitdb.schema.Unitdb';

  UnitdbServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Packet, $0.Packet>(
        'Stream',
        stream,
        true,
        true,
        ($core.List<$core.int> value) => $0.Packet.fromBuffer(value),
        ($0.Packet value) => value.writeToBuffer()));
  }

  $async.Stream<$0.Packet> stream(
      $grpc.ServiceCall call, $async.Stream<$0.Packet> request);
}
