///
//  Generated code. Do not modify.
//  source: unitdb.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use flowControlDescriptor instead')
const FlowControl$json = const {
  '1': 'FlowControl',
  '2': const [
    const {'1': 'NONE', '2': 0},
    const {'1': 'ACKNOWLEDGE', '2': 1},
    const {'1': 'NOTIFY', '2': 2},
    const {'1': 'RECEIVE', '2': 3},
    const {'1': 'RECEIPT', '2': 4},
    const {'1': 'COMPLETE', '2': 5},
  ],
};

/// Descriptor for `FlowControl`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List flowControlDescriptor = $convert.base64Decode('CgtGbG93Q29udHJvbBIICgROT05FEAASDwoLQUNLTk9XTEVER0UQARIKCgZOT1RJRlkQAhILCgdSRUNFSVZFEAMSCwoHUkVDRUlQVBAEEgwKCENPTVBMRVRFEAU=');
@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = const {
  '1': 'MessageType',
  '2': const [
    const {'1': 'RERSERVED', '2': 0},
    const {'1': 'CONNECT', '2': 1},
    const {'1': 'PUBLISH', '2': 2},
    const {'1': 'RELAY', '2': 3},
    const {'1': 'SUBSCRIBE', '2': 4},
    const {'1': 'UNSUBSCRIBE', '2': 5},
    const {'1': 'PINGREQ', '2': 6},
    const {'1': 'DISCONNECT', '2': 7},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode('CgtNZXNzYWdlVHlwZRINCglSRVJTRVJWRUQQABILCgdDT05ORUNUEAESCwoHUFVCTElTSBACEgkKBVJFTEFZEAMSDQoJU1VCU0NSSUJFEAQSDwoLVU5TVUJTQ1JJQkUQBRILCgdQSU5HUkVREAYSDgoKRElTQ09OTkVDVBAH');
@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = const {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode('CgVFbXB0eQ==');
@$core.Deprecated('Use packetDescriptor instead')
const Packet$json = const {
  '1': 'Packet',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Packet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List packetDescriptor = $convert.base64Decode('CgZQYWNrZXQSEgoEZGF0YRgBIAEoDFIEZGF0YQ==');
@$core.Deprecated('Use fixedHeaderDescriptor instead')
const FixedHeader$json = const {
  '1': 'FixedHeader',
  '2': const [
    const {'1': 'MessageType', '3': 1, '4': 1, '5': 14, '6': '.unitdb.schema.MessageType', '10': 'MessageType'},
    const {'1': 'FlowControl', '3': 2, '4': 1, '5': 14, '6': '.unitdb.schema.FlowControl', '10': 'FlowControl'},
    const {'1': 'MessageLength', '3': 3, '4': 1, '5': 5, '10': 'MessageLength'},
  ],
};

/// Descriptor for `FixedHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fixedHeaderDescriptor = $convert.base64Decode('CgtGaXhlZEhlYWRlchI8CgtNZXNzYWdlVHlwZRgBIAEoDjIaLnVuaXRkYi5zY2hlbWEuTWVzc2FnZVR5cGVSC01lc3NhZ2VUeXBlEjwKC0Zsb3dDb250cm9sGAIgASgOMhoudW5pdGRiLnNjaGVtYS5GbG93Q29udHJvbFILRmxvd0NvbnRyb2wSJAoNTWVzc2FnZUxlbmd0aBgDIAEoBVINTWVzc2FnZUxlbmd0aA==');
@$core.Deprecated('Use connectDescriptor instead')
const Connect$json = const {
  '1': 'Connect',
  '2': const [
    const {'1': 'Version', '3': 1, '4': 1, '5': 5, '10': 'Version'},
    const {'1': 'InsecureFlag', '3': 2, '4': 1, '5': 8, '10': 'InsecureFlag'},
    const {'1': 'ClientID', '3': 3, '4': 1, '5': 9, '10': 'ClientID'},
    const {'1': 'KeepAlive', '3': 4, '4': 1, '5': 5, '10': 'KeepAlive'},
    const {'1': 'CleanSessFlag', '3': 5, '4': 1, '5': 8, '10': 'CleanSessFlag'},
    const {'1': 'SessKey', '3': 6, '4': 1, '5': 5, '10': 'SessKey'},
    const {'1': 'Username', '3': 7, '4': 1, '5': 9, '10': 'Username'},
    const {'1': 'Password', '3': 8, '4': 1, '5': 12, '10': 'Password'},
    const {'1': 'BatchDuration', '3': 9, '4': 1, '5': 5, '10': 'BatchDuration'},
    const {'1': 'BatchByteThreshold', '3': 10, '4': 1, '5': 5, '10': 'BatchByteThreshold'},
    const {'1': 'BatchCountThreshold', '3': 11, '4': 1, '5': 5, '10': 'BatchCountThreshold'},
  ],
};

/// Descriptor for `Connect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectDescriptor = $convert.base64Decode('CgdDb25uZWN0EhgKB1ZlcnNpb24YASABKAVSB1ZlcnNpb24SIgoMSW5zZWN1cmVGbGFnGAIgASgIUgxJbnNlY3VyZUZsYWcSGgoIQ2xpZW50SUQYAyABKAlSCENsaWVudElEEhwKCUtlZXBBbGl2ZRgEIAEoBVIJS2VlcEFsaXZlEiQKDUNsZWFuU2Vzc0ZsYWcYBSABKAhSDUNsZWFuU2Vzc0ZsYWcSGAoHU2Vzc0tleRgGIAEoBVIHU2Vzc0tleRIaCghVc2VybmFtZRgHIAEoCVIIVXNlcm5hbWUSGgoIUGFzc3dvcmQYCCABKAxSCFBhc3N3b3JkEiQKDUJhdGNoRHVyYXRpb24YCSABKAVSDUJhdGNoRHVyYXRpb24SLgoSQmF0Y2hCeXRlVGhyZXNob2xkGAogASgFUhJCYXRjaEJ5dGVUaHJlc2hvbGQSMAoTQmF0Y2hDb3VudFRocmVzaG9sZBgLIAEoBVITQmF0Y2hDb3VudFRocmVzaG9sZA==');
@$core.Deprecated('Use connectAcknowledgeDescriptor instead')
const ConnectAcknowledge$json = const {
  '1': 'ConnectAcknowledge',
  '2': const [
    const {'1': 'ReturnCode', '3': 1, '4': 1, '5': 5, '10': 'ReturnCode'},
    const {'1': 'Epoch', '3': 2, '4': 1, '5': 5, '10': 'Epoch'},
    const {'1': 'ConnID', '3': 3, '4': 1, '5': 5, '10': 'ConnID'},
  ],
};

/// Descriptor for `ConnectAcknowledge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectAcknowledgeDescriptor = $convert.base64Decode('ChJDb25uZWN0QWNrbm93bGVkZ2USHgoKUmV0dXJuQ29kZRgBIAEoBVIKUmV0dXJuQ29kZRIUCgVFcG9jaBgCIAEoBVIFRXBvY2gSFgoGQ29ubklEGAMgASgFUgZDb25uSUQ=');
@$core.Deprecated('Use pingRequestDescriptor instead')
const PingRequest$json = const {
  '1': 'PingRequest',
};

/// Descriptor for `PingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingRequestDescriptor = $convert.base64Decode('CgtQaW5nUmVxdWVzdA==');
@$core.Deprecated('Use disconnectDescriptor instead')
const Disconnect$json = const {
  '1': 'Disconnect',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
  ],
};

/// Descriptor for `Disconnect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectDescriptor = $convert.base64Decode('CgpEaXNjb25uZWN0EhwKCU1lc3NhZ2VJRBgBIAEoBVIJTWVzc2FnZUlE');
@$core.Deprecated('Use publishMessageDescriptor instead')
const PublishMessage$json = const {
  '1': 'PublishMessage',
  '2': const [
    const {'1': 'Topic', '3': 1, '4': 1, '5': 9, '10': 'Topic'},
    const {'1': 'Payload', '3': 2, '4': 1, '5': 12, '10': 'Payload'},
    const {'1': 'Ttl', '3': 3, '4': 1, '5': 9, '10': 'Ttl'},
  ],
};

/// Descriptor for `PublishMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishMessageDescriptor = $convert.base64Decode('Cg5QdWJsaXNoTWVzc2FnZRIUCgVUb3BpYxgBIAEoCVIFVG9waWMSGAoHUGF5bG9hZBgCIAEoDFIHUGF5bG9hZBIQCgNUdGwYAyABKAlSA1R0bA==');
@$core.Deprecated('Use publishDescriptor instead')
const Publish$json = const {
  '1': 'Publish',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'DeliveryMode', '3': 2, '4': 1, '5': 5, '10': 'DeliveryMode'},
    const {'1': 'Messages', '3': 3, '4': 3, '5': 11, '6': '.unitdb.schema.PublishMessage', '10': 'Messages'},
  ],
};

/// Descriptor for `Publish`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDescriptor = $convert.base64Decode('CgdQdWJsaXNoEhwKCU1lc3NhZ2VJRBgBIAEoBVIJTWVzc2FnZUlEEiIKDERlbGl2ZXJ5TW9kZRgCIAEoBVIMRGVsaXZlcnlNb2RlEjkKCE1lc3NhZ2VzGAMgAygLMh0udW5pdGRiLnNjaGVtYS5QdWJsaXNoTWVzc2FnZVIITWVzc2FnZXM=');
@$core.Deprecated('Use relayRequestDescriptor instead')
const RelayRequest$json = const {
  '1': 'RelayRequest',
  '2': const [
    const {'1': 'Topic', '3': 1, '4': 1, '5': 9, '10': 'Topic'},
    const {'1': 'Last', '3': 2, '4': 1, '5': 9, '10': 'Last'},
  ],
};

/// Descriptor for `RelayRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayRequestDescriptor = $convert.base64Decode('CgxSZWxheVJlcXVlc3QSFAoFVG9waWMYASABKAlSBVRvcGljEhIKBExhc3QYAiABKAlSBExhc3Q=');
@$core.Deprecated('Use relayDescriptor instead')
const Relay$json = const {
  '1': 'Relay',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'relayRequests', '3': 2, '4': 3, '5': 11, '6': '.unitdb.schema.RelayRequest', '10': 'relayRequests'},
  ],
};

/// Descriptor for `Relay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayDescriptor = $convert.base64Decode('CgVSZWxheRIcCglNZXNzYWdlSUQYASABKAVSCU1lc3NhZ2VJRBJBCg1yZWxheVJlcXVlc3RzGAIgAygLMhsudW5pdGRiLnNjaGVtYS5SZWxheVJlcXVlc3RSDXJlbGF5UmVxdWVzdHM=');
@$core.Deprecated('Use subscriptionDescriptor instead')
const Subscription$json = const {
  '1': 'Subscription',
  '2': const [
    const {'1': 'DeliveryMode', '3': 1, '4': 1, '5': 5, '10': 'DeliveryMode'},
    const {'1': 'Delay', '3': 2, '4': 1, '5': 5, '10': 'Delay'},
    const {'1': 'Topic', '3': 3, '4': 1, '5': 9, '10': 'Topic'},
    const {'1': 'Last', '3': 4, '4': 1, '5': 9, '10': 'Last'},
  ],
};

/// Descriptor for `Subscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionDescriptor = $convert.base64Decode('CgxTdWJzY3JpcHRpb24SIgoMRGVsaXZlcnlNb2RlGAEgASgFUgxEZWxpdmVyeU1vZGUSFAoFRGVsYXkYAiABKAVSBURlbGF5EhQKBVRvcGljGAMgASgJUgVUb3BpYxISCgRMYXN0GAQgASgJUgRMYXN0');
@$core.Deprecated('Use subscribeDescriptor instead')
const Subscribe$json = const {
  '1': 'Subscribe',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'Subscriptions', '3': 2, '4': 3, '5': 11, '6': '.unitdb.schema.Subscription', '10': 'Subscriptions'},
  ],
};

/// Descriptor for `Subscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeDescriptor = $convert.base64Decode('CglTdWJzY3JpYmUSHAoJTWVzc2FnZUlEGAEgASgFUglNZXNzYWdlSUQSQQoNU3Vic2NyaXB0aW9ucxgCIAMoCzIbLnVuaXRkYi5zY2hlbWEuU3Vic2NyaXB0aW9uUg1TdWJzY3JpcHRpb25z');
@$core.Deprecated('Use unsubscribeDescriptor instead')
const Unsubscribe$json = const {
  '1': 'Unsubscribe',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'Subscriptions', '3': 2, '4': 3, '5': 11, '6': '.unitdb.schema.Subscription', '10': 'Subscriptions'},
  ],
};

/// Descriptor for `Unsubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unsubscribeDescriptor = $convert.base64Decode('CgtVbnN1YnNjcmliZRIcCglNZXNzYWdlSUQYASABKAVSCU1lc3NhZ2VJRBJBCg1TdWJzY3JpcHRpb25zGAIgAygLMhsudW5pdGRiLnNjaGVtYS5TdWJzY3JpcHRpb25SDVN1YnNjcmlwdGlvbnM=');
@$core.Deprecated('Use controlMessageDescriptor instead')
const ControlMessage$json = const {
  '1': 'ControlMessage',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'Message', '3': 2, '4': 1, '5': 12, '10': 'Message'},
  ],
};

/// Descriptor for `ControlMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlMessageDescriptor = $convert.base64Decode('Cg5Db250cm9sTWVzc2FnZRIcCglNZXNzYWdlSUQYASABKAVSCU1lc3NhZ2VJRBIYCgdNZXNzYWdlGAIgASgMUgdNZXNzYWdl');
