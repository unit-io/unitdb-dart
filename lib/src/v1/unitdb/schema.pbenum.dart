///
//  Generated code. Do not modify.
//  source: schema.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FlowControl extends $pb.ProtobufEnum {
  static const FlowControl NONE = FlowControl._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NONE');
  static const FlowControl ACKNOWLEDGE = FlowControl._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ACKNOWLEDGE');
  static const FlowControl NOTIFY = FlowControl._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NOTIFY');
  static const FlowControl RECEIVE = FlowControl._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RECEIVE');
  static const FlowControl RECEIPT = FlowControl._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RECEIPT');
  static const FlowControl COMPLETE = FlowControl._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'COMPLETE');

  static const $core.List<FlowControl> values = <FlowControl> [
    NONE,
    ACKNOWLEDGE,
    NOTIFY,
    RECEIVE,
    RECEIPT,
    COMPLETE,
  ];

  static final $core.Map<$core.int, FlowControl> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FlowControl? valueOf($core.int value) => _byValue[value];

  const FlowControl._($core.int v, $core.String n) : super(v, n);
}

class MessageType extends $pb.ProtobufEnum {
  static const MessageType RERSERVED = MessageType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RERSERVED');
  static const MessageType CONNECT = MessageType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CONNECT');
  static const MessageType PUBLISH = MessageType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH');
  static const MessageType RELAY = MessageType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RELAY');
  static const MessageType SUBSCRIBE = MessageType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SUBSCRIBE');
  static const MessageType UNSUBSCRIBE = MessageType._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNSUBSCRIBE');
  static const MessageType PINGREQ = MessageType._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PINGREQ');
  static const MessageType DISCONNECT = MessageType._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DISCONNECT');

  static const $core.List<MessageType> values = <MessageType> [
    RERSERVED,
    CONNECT,
    PUBLISH,
    RELAY,
    SUBSCRIBE,
    UNSUBSCRIBE,
    PINGREQ,
    DISCONNECT,
  ];

  static final $core.Map<$core.int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._($core.int v, $core.String n) : super(v, n);
}

