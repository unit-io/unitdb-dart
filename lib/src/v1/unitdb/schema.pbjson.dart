///
//  Generated code. Do not modify.
//  source: schema.proto
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
    const {'1': 'MessageType', '3': 1, '4': 1, '5': 14, '6': '.unitdb.MessageType', '10': 'MessageType'},
    const {'1': 'FlowControl', '3': 2, '4': 1, '5': 14, '6': '.unitdb.FlowControl', '10': 'FlowControl'},
    const {'1': 'MessageLength', '3': 3, '4': 1, '5': 5, '10': 'MessageLength'},
  ],
};

/// Descriptor for `FixedHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fixedHeaderDescriptor = $convert.base64Decode('CgtGaXhlZEhlYWRlchI1CgtNZXNzYWdlVHlwZRgBIAEoDjITLnVuaXRkYi5NZXNzYWdlVHlwZVILTWVzc2FnZVR5cGUSNQoLRmxvd0NvbnRyb2wYAiABKA4yEy51bml0ZGIuRmxvd0NvbnRyb2xSC0Zsb3dDb250cm9sEiQKDU1lc3NhZ2VMZW5ndGgYAyABKAVSDU1lc3NhZ2VMZW5ndGg=');
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
    const {'1': 'SessionData', '3': 9, '4': 1, '5': 9, '10': 'SessionData'},
    const {'1': 'BatchDuration', '3': 10, '4': 1, '5': 5, '10': 'BatchDuration'},
    const {'1': 'BatchByteThreshold', '3': 11, '4': 1, '5': 5, '10': 'BatchByteThreshold'},
    const {'1': 'BatchCountThreshold', '3': 12, '4': 1, '5': 5, '10': 'BatchCountThreshold'},
  ],
};

/// Descriptor for `Connect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectDescriptor = $convert.base64Decode('CgdDb25uZWN0EhgKB1ZlcnNpb24YASABKAVSB1ZlcnNpb24SIgoMSW5zZWN1cmVGbGFnGAIgASgIUgxJbnNlY3VyZUZsYWcSGgoIQ2xpZW50SUQYAyABKAlSCENsaWVudElEEhwKCUtlZXBBbGl2ZRgEIAEoBVIJS2VlcEFsaXZlEiQKDUNsZWFuU2Vzc0ZsYWcYBSABKAhSDUNsZWFuU2Vzc0ZsYWcSGAoHU2Vzc0tleRgGIAEoBVIHU2Vzc0tleRIaCghVc2VybmFtZRgHIAEoCVIIVXNlcm5hbWUSGgoIUGFzc3dvcmQYCCABKAxSCFBhc3N3b3JkEiAKC1Nlc3Npb25EYXRhGAkgASgJUgtTZXNzaW9uRGF0YRIkCg1CYXRjaER1cmF0aW9uGAogASgFUg1CYXRjaER1cmF0aW9uEi4KEkJhdGNoQnl0ZVRocmVzaG9sZBgLIAEoBVISQmF0Y2hCeXRlVGhyZXNob2xkEjAKE0JhdGNoQ291bnRUaHJlc2hvbGQYDCABKAVSE0JhdGNoQ291bnRUaHJlc2hvbGQ=');
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
    const {'1': 'Tags', '3': 3, '4': 3, '5': 11, '6': '.unitdb.PublishMessage.TagsEntry', '10': 'Tags'},
    const {'1': 'Ttl', '3': 4, '4': 1, '5': 9, '10': 'Ttl'},
  ],
  '3': const [PublishMessage_TagsEntry$json],
};

@$core.Deprecated('Use publishMessageDescriptor instead')
const PublishMessage_TagsEntry$json = const {
  '1': 'TagsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `PublishMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishMessageDescriptor = $convert.base64Decode('Cg5QdWJsaXNoTWVzc2FnZRIUCgVUb3BpYxgBIAEoCVIFVG9waWMSGAoHUGF5bG9hZBgCIAEoDFIHUGF5bG9hZBI0CgRUYWdzGAMgAygLMiAudW5pdGRiLlB1Ymxpc2hNZXNzYWdlLlRhZ3NFbnRyeVIEVGFncxIQCgNUdGwYBCABKAlSA1R0bBo3CglUYWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use publishDescriptor instead')
const Publish$json = const {
  '1': 'Publish',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'DeliveryMode', '3': 2, '4': 1, '5': 5, '10': 'DeliveryMode'},
    const {'1': 'Messages', '3': 3, '4': 3, '5': 11, '6': '.unitdb.PublishMessage', '10': 'Messages'},
  ],
};

/// Descriptor for `Publish`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDescriptor = $convert.base64Decode('CgdQdWJsaXNoEhwKCU1lc3NhZ2VJRBgBIAEoBVIJTWVzc2FnZUlEEiIKDERlbGl2ZXJ5TW9kZRgCIAEoBVIMRGVsaXZlcnlNb2RlEjIKCE1lc3NhZ2VzGAMgAygLMhYudW5pdGRiLlB1Ymxpc2hNZXNzYWdlUghNZXNzYWdlcw==');
@$core.Deprecated('Use relayRequestDescriptor instead')
const RelayRequest$json = const {
  '1': 'RelayRequest',
  '2': const [
    const {'1': 'Topic', '3': 1, '4': 1, '5': 9, '10': 'Topic'},
    const {'1': 'Tags', '3': 2, '4': 3, '5': 11, '6': '.unitdb.RelayRequest.TagsEntry', '10': 'Tags'},
    const {'1': 'Last', '3': 3, '4': 1, '5': 9, '10': 'Last'},
  ],
  '3': const [RelayRequest_TagsEntry$json],
};

@$core.Deprecated('Use relayRequestDescriptor instead')
const RelayRequest_TagsEntry$json = const {
  '1': 'TagsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `RelayRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayRequestDescriptor = $convert.base64Decode('CgxSZWxheVJlcXVlc3QSFAoFVG9waWMYASABKAlSBVRvcGljEjIKBFRhZ3MYAiADKAsyHi51bml0ZGIuUmVsYXlSZXF1ZXN0LlRhZ3NFbnRyeVIEVGFncxISCgRMYXN0GAMgASgJUgRMYXN0GjcKCVRhZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');
@$core.Deprecated('Use relayDescriptor instead')
const Relay$json = const {
  '1': 'Relay',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'RelayRequests', '3': 2, '4': 3, '5': 11, '6': '.unitdb.RelayRequest', '10': 'RelayRequests'},
  ],
};

/// Descriptor for `Relay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayDescriptor = $convert.base64Decode('CgVSZWxheRIcCglNZXNzYWdlSUQYASABKAVSCU1lc3NhZ2VJRBI6Cg1SZWxheVJlcXVlc3RzGAIgAygLMhQudW5pdGRiLlJlbGF5UmVxdWVzdFINUmVsYXlSZXF1ZXN0cw==');
@$core.Deprecated('Use subscriptionDescriptor instead')
const Subscription$json = const {
  '1': 'Subscription',
  '2': const [
    const {'1': 'DeliveryMode', '3': 1, '4': 1, '5': 5, '10': 'DeliveryMode'},
    const {'1': 'Delay', '3': 2, '4': 1, '5': 5, '10': 'Delay'},
    const {'1': 'Topic', '3': 3, '4': 1, '5': 9, '10': 'Topic'},
  ],
};

/// Descriptor for `Subscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionDescriptor = $convert.base64Decode('CgxTdWJzY3JpcHRpb24SIgoMRGVsaXZlcnlNb2RlGAEgASgFUgxEZWxpdmVyeU1vZGUSFAoFRGVsYXkYAiABKAVSBURlbGF5EhQKBVRvcGljGAMgASgJUgVUb3BpYw==');
@$core.Deprecated('Use subscribeDescriptor instead')
const Subscribe$json = const {
  '1': 'Subscribe',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'Subscriptions', '3': 2, '4': 3, '5': 11, '6': '.unitdb.Subscription', '10': 'Subscriptions'},
  ],
};

/// Descriptor for `Subscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeDescriptor = $convert.base64Decode('CglTdWJzY3JpYmUSHAoJTWVzc2FnZUlEGAEgASgFUglNZXNzYWdlSUQSOgoNU3Vic2NyaXB0aW9ucxgCIAMoCzIULnVuaXRkYi5TdWJzY3JpcHRpb25SDVN1YnNjcmlwdGlvbnM=');
@$core.Deprecated('Use unsubscribeDescriptor instead')
const Unsubscribe$json = const {
  '1': 'Unsubscribe',
  '2': const [
    const {'1': 'MessageID', '3': 1, '4': 1, '5': 5, '10': 'MessageID'},
    const {'1': 'Subscriptions', '3': 2, '4': 3, '5': 11, '6': '.unitdb.Subscription', '10': 'Subscriptions'},
  ],
};

/// Descriptor for `Unsubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unsubscribeDescriptor = $convert.base64Decode('CgtVbnN1YnNjcmliZRIcCglNZXNzYWdlSUQYASABKAVSCU1lc3NhZ2VJRBI6Cg1TdWJzY3JpcHRpb25zGAIgAygLMhQudW5pdGRiLlN1YnNjcmlwdGlvblINU3Vic2NyaXB0aW9ucw==');
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
