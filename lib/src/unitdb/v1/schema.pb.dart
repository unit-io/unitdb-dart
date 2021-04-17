///
//  Generated code. Do not modify.
//  source: schema.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'schema.pbenum.dart';

export 'schema.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Empty', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  Empty._() : super();
  factory Empty() => create();
  factory Empty.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Empty.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Empty clone() => Empty()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Empty copyWith(void Function(Empty) updates) => super.copyWith((message) => updates(message as Empty)) as Empty; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Empty create() => Empty._();
  Empty createEmptyInstance() => create();
  static $pb.PbList<Empty> createRepeated() => $pb.PbList<Empty>();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
  static Empty? _defaultInstance;
}

class Packet extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Packet', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Packet._() : super();
  factory Packet({
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory Packet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Packet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Packet clone() => Packet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Packet copyWith(void Function(Packet) updates) => super.copyWith((message) => updates(message as Packet)) as Packet; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Packet create() => Packet._();
  Packet createEmptyInstance() => create();
  static $pb.PbList<Packet> createRepeated() => $pb.PbList<Packet>();
  @$core.pragma('dart2js:noInline')
  static Packet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Packet>(create);
  static Packet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);
}

class FixedHeader extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FixedHeader', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..e<MessageType>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageType', $pb.PbFieldType.OE, protoName: 'MessageType', defaultOrMaker: MessageType.RERSERVED, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..e<FlowControl>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'FlowControl', $pb.PbFieldType.OE, protoName: 'FlowControl', defaultOrMaker: FlowControl.NONE, valueOf: FlowControl.valueOf, enumValues: FlowControl.values)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageLength', $pb.PbFieldType.O3, protoName: 'MessageLength')
    ..hasRequiredFields = false
  ;

  FixedHeader._() : super();
  factory FixedHeader({
    MessageType? messageType,
    FlowControl? flowControl,
    $core.int? messageLength,
  }) {
    final _result = create();
    if (messageType != null) {
      _result.messageType = messageType;
    }
    if (flowControl != null) {
      _result.flowControl = flowControl;
    }
    if (messageLength != null) {
      _result.messageLength = messageLength;
    }
    return _result;
  }
  factory FixedHeader.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FixedHeader.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FixedHeader clone() => FixedHeader()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FixedHeader copyWith(void Function(FixedHeader) updates) => super.copyWith((message) => updates(message as FixedHeader)) as FixedHeader; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FixedHeader create() => FixedHeader._();
  FixedHeader createEmptyInstance() => create();
  static $pb.PbList<FixedHeader> createRepeated() => $pb.PbList<FixedHeader>();
  @$core.pragma('dart2js:noInline')
  static FixedHeader getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FixedHeader>(create);
  static FixedHeader? _defaultInstance;

  @$pb.TagNumber(1)
  MessageType get messageType => $_getN(0);
  @$pb.TagNumber(1)
  set messageType(MessageType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageType() => clearField(1);

  @$pb.TagNumber(2)
  FlowControl get flowControl => $_getN(1);
  @$pb.TagNumber(2)
  set flowControl(FlowControl v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFlowControl() => $_has(1);
  @$pb.TagNumber(2)
  void clearFlowControl() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get messageLength => $_getIZ(2);
  @$pb.TagNumber(3)
  set messageLength($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessageLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageLength() => clearField(3);
}

class Connect extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Connect', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Version', $pb.PbFieldType.O3, protoName: 'Version')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'InsecureFlag', protoName: 'InsecureFlag')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ClientID', protoName: 'ClientID')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'KeepAlive', $pb.PbFieldType.O3, protoName: 'KeepAlive')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'CleanSessFlag', protoName: 'CleanSessFlag')
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'SessKey', $pb.PbFieldType.O3, protoName: 'SessKey')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Username', protoName: 'Username')
    ..a<$core.List<$core.int>>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Password', $pb.PbFieldType.OY, protoName: 'Password')
    ..a<$core.int>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'BatchDuration', $pb.PbFieldType.O3, protoName: 'BatchDuration')
    ..a<$core.int>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'BatchByteThreshold', $pb.PbFieldType.O3, protoName: 'BatchByteThreshold')
    ..a<$core.int>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'BatchCountThreshold', $pb.PbFieldType.O3, protoName: 'BatchCountThreshold')
    ..hasRequiredFields = false
  ;

  Connect._() : super();
  factory Connect({
    $core.int? version,
    $core.bool? insecureFlag,
    $core.String? clientID,
    $core.int? keepAlive,
    $core.bool? cleanSessFlag,
    $core.int? sessKey,
    $core.String? username,
    $core.List<$core.int>? password,
    $core.int? batchDuration,
    $core.int? batchByteThreshold,
    $core.int? batchCountThreshold,
  }) {
    final _result = create();
    if (version != null) {
      _result.version = version;
    }
    if (insecureFlag != null) {
      _result.insecureFlag = insecureFlag;
    }
    if (clientID != null) {
      _result.clientID = clientID;
    }
    if (keepAlive != null) {
      _result.keepAlive = keepAlive;
    }
    if (cleanSessFlag != null) {
      _result.cleanSessFlag = cleanSessFlag;
    }
    if (sessKey != null) {
      _result.sessKey = sessKey;
    }
    if (username != null) {
      _result.username = username;
    }
    if (password != null) {
      _result.password = password;
    }
    if (batchDuration != null) {
      _result.batchDuration = batchDuration;
    }
    if (batchByteThreshold != null) {
      _result.batchByteThreshold = batchByteThreshold;
    }
    if (batchCountThreshold != null) {
      _result.batchCountThreshold = batchCountThreshold;
    }
    return _result;
  }
  factory Connect.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Connect.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Connect clone() => Connect()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Connect copyWith(void Function(Connect) updates) => super.copyWith((message) => updates(message as Connect)) as Connect; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Connect create() => Connect._();
  Connect createEmptyInstance() => create();
  static $pb.PbList<Connect> createRepeated() => $pb.PbList<Connect>();
  @$core.pragma('dart2js:noInline')
  static Connect getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Connect>(create);
  static Connect? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get insecureFlag => $_getBF(1);
  @$pb.TagNumber(2)
  set insecureFlag($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInsecureFlag() => $_has(1);
  @$pb.TagNumber(2)
  void clearInsecureFlag() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get clientID => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientID($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasClientID() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientID() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get keepAlive => $_getIZ(3);
  @$pb.TagNumber(4)
  set keepAlive($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasKeepAlive() => $_has(3);
  @$pb.TagNumber(4)
  void clearKeepAlive() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get cleanSessFlag => $_getBF(4);
  @$pb.TagNumber(5)
  set cleanSessFlag($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCleanSessFlag() => $_has(4);
  @$pb.TagNumber(5)
  void clearCleanSessFlag() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get sessKey => $_getIZ(5);
  @$pb.TagNumber(6)
  set sessKey($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSessKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearSessKey() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get username => $_getSZ(6);
  @$pb.TagNumber(7)
  set username($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasUsername() => $_has(6);
  @$pb.TagNumber(7)
  void clearUsername() => clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get password => $_getN(7);
  @$pb.TagNumber(8)
  set password($core.List<$core.int> v) { $_setBytes(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPassword() => $_has(7);
  @$pb.TagNumber(8)
  void clearPassword() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get batchDuration => $_getIZ(8);
  @$pb.TagNumber(9)
  set batchDuration($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasBatchDuration() => $_has(8);
  @$pb.TagNumber(9)
  void clearBatchDuration() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get batchByteThreshold => $_getIZ(9);
  @$pb.TagNumber(10)
  set batchByteThreshold($core.int v) { $_setSignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasBatchByteThreshold() => $_has(9);
  @$pb.TagNumber(10)
  void clearBatchByteThreshold() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get batchCountThreshold => $_getIZ(10);
  @$pb.TagNumber(11)
  set batchCountThreshold($core.int v) { $_setSignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasBatchCountThreshold() => $_has(10);
  @$pb.TagNumber(11)
  void clearBatchCountThreshold() => clearField(11);
}

class ConnectAcknowledge extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConnectAcknowledge', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ReturnCode', $pb.PbFieldType.O3, protoName: 'ReturnCode')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Epoch', $pb.PbFieldType.O3, protoName: 'Epoch')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ConnID', $pb.PbFieldType.O3, protoName: 'ConnID')
    ..hasRequiredFields = false
  ;

  ConnectAcknowledge._() : super();
  factory ConnectAcknowledge({
    $core.int? returnCode,
    $core.int? epoch,
    $core.int? connID,
  }) {
    final _result = create();
    if (returnCode != null) {
      _result.returnCode = returnCode;
    }
    if (epoch != null) {
      _result.epoch = epoch;
    }
    if (connID != null) {
      _result.connID = connID;
    }
    return _result;
  }
  factory ConnectAcknowledge.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectAcknowledge.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectAcknowledge clone() => ConnectAcknowledge()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectAcknowledge copyWith(void Function(ConnectAcknowledge) updates) => super.copyWith((message) => updates(message as ConnectAcknowledge)) as ConnectAcknowledge; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConnectAcknowledge create() => ConnectAcknowledge._();
  ConnectAcknowledge createEmptyInstance() => create();
  static $pb.PbList<ConnectAcknowledge> createRepeated() => $pb.PbList<ConnectAcknowledge>();
  @$core.pragma('dart2js:noInline')
  static ConnectAcknowledge getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectAcknowledge>(create);
  static ConnectAcknowledge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get returnCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set returnCode($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReturnCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearReturnCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get epoch => $_getIZ(1);
  @$pb.TagNumber(2)
  set epoch($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEpoch() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpoch() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get connID => $_getIZ(2);
  @$pb.TagNumber(3)
  set connID($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasConnID() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnID() => clearField(3);
}

class PingRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PingRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  PingRequest._() : super();
  factory PingRequest() => create();
  factory PingRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PingRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PingRequest clone() => PingRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PingRequest copyWith(void Function(PingRequest) updates) => super.copyWith((message) => updates(message as PingRequest)) as PingRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PingRequest create() => PingRequest._();
  PingRequest createEmptyInstance() => create();
  static $pb.PbList<PingRequest> createRepeated() => $pb.PbList<PingRequest>();
  @$core.pragma('dart2js:noInline')
  static PingRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PingRequest>(create);
  static PingRequest? _defaultInstance;
}

class Disconnect extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Disconnect', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageID', $pb.PbFieldType.O3, protoName: 'MessageID')
    ..hasRequiredFields = false
  ;

  Disconnect._() : super();
  factory Disconnect({
    $core.int? messageID,
  }) {
    final _result = create();
    if (messageID != null) {
      _result.messageID = messageID;
    }
    return _result;
  }
  factory Disconnect.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Disconnect.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Disconnect clone() => Disconnect()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Disconnect copyWith(void Function(Disconnect) updates) => super.copyWith((message) => updates(message as Disconnect)) as Disconnect; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Disconnect create() => Disconnect._();
  Disconnect createEmptyInstance() => create();
  static $pb.PbList<Disconnect> createRepeated() => $pb.PbList<Disconnect>();
  @$core.pragma('dart2js:noInline')
  static Disconnect getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Disconnect>(create);
  static Disconnect? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get messageID => $_getIZ(0);
  @$pb.TagNumber(1)
  set messageID($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageID() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageID() => clearField(1);
}

class PublishMessage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PublishMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Topic', protoName: 'Topic')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Payload', $pb.PbFieldType.OY, protoName: 'Payload')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Ttl', protoName: 'Ttl')
    ..hasRequiredFields = false
  ;

  PublishMessage._() : super();
  factory PublishMessage({
    $core.String? topic,
    $core.List<$core.int>? payload,
    $core.String? ttl,
  }) {
    final _result = create();
    if (topic != null) {
      _result.topic = topic;
    }
    if (payload != null) {
      _result.payload = payload;
    }
    if (ttl != null) {
      _result.ttl = ttl;
    }
    return _result;
  }
  factory PublishMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PublishMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PublishMessage clone() => PublishMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PublishMessage copyWith(void Function(PublishMessage) updates) => super.copyWith((message) => updates(message as PublishMessage)) as PublishMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PublishMessage create() => PublishMessage._();
  PublishMessage createEmptyInstance() => create();
  static $pb.PbList<PublishMessage> createRepeated() => $pb.PbList<PublishMessage>();
  @$core.pragma('dart2js:noInline')
  static PublishMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PublishMessage>(create);
  static PublishMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ttl => $_getSZ(2);
  @$pb.TagNumber(3)
  set ttl($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTtl() => $_has(2);
  @$pb.TagNumber(3)
  void clearTtl() => clearField(3);
}

class Publish extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Publish', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageID', $pb.PbFieldType.O3, protoName: 'MessageID')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'DeliveryMode', $pb.PbFieldType.O3, protoName: 'DeliveryMode')
    ..pc<PublishMessage>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Messages', $pb.PbFieldType.PM, protoName: 'Messages', subBuilder: PublishMessage.create)
    ..hasRequiredFields = false
  ;

  Publish._() : super();
  factory Publish({
    $core.int? messageID,
    $core.int? deliveryMode,
    $core.Iterable<PublishMessage>? messages,
  }) {
    final _result = create();
    if (messageID != null) {
      _result.messageID = messageID;
    }
    if (deliveryMode != null) {
      _result.deliveryMode = deliveryMode;
    }
    if (messages != null) {
      _result.messages.addAll(messages);
    }
    return _result;
  }
  factory Publish.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Publish.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Publish clone() => Publish()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Publish copyWith(void Function(Publish) updates) => super.copyWith((message) => updates(message as Publish)) as Publish; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Publish create() => Publish._();
  Publish createEmptyInstance() => create();
  static $pb.PbList<Publish> createRepeated() => $pb.PbList<Publish>();
  @$core.pragma('dart2js:noInline')
  static Publish getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Publish>(create);
  static Publish? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get messageID => $_getIZ(0);
  @$pb.TagNumber(1)
  set messageID($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageID() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageID() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get deliveryMode => $_getIZ(1);
  @$pb.TagNumber(2)
  set deliveryMode($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeliveryMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeliveryMode() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<PublishMessage> get messages => $_getList(2);
}

class Subscription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Subscription', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'DeliveryMode', $pb.PbFieldType.O3, protoName: 'DeliveryMode')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Delay', $pb.PbFieldType.O3, protoName: 'Delay')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Topic', protoName: 'Topic')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Last', protoName: 'Last')
    ..hasRequiredFields = false
  ;

  Subscription._() : super();
  factory Subscription({
    $core.int? deliveryMode,
    $core.int? delay,
    $core.String? topic,
    $core.String? last,
  }) {
    final _result = create();
    if (deliveryMode != null) {
      _result.deliveryMode = deliveryMode;
    }
    if (delay != null) {
      _result.delay = delay;
    }
    if (topic != null) {
      _result.topic = topic;
    }
    if (last != null) {
      _result.last = last;
    }
    return _result;
  }
  factory Subscription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Subscription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Subscription clone() => Subscription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Subscription copyWith(void Function(Subscription) updates) => super.copyWith((message) => updates(message as Subscription)) as Subscription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Subscription create() => Subscription._();
  Subscription createEmptyInstance() => create();
  static $pb.PbList<Subscription> createRepeated() => $pb.PbList<Subscription>();
  @$core.pragma('dart2js:noInline')
  static Subscription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Subscription>(create);
  static Subscription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deliveryMode => $_getIZ(0);
  @$pb.TagNumber(1)
  set deliveryMode($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeliveryMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeliveryMode() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get delay => $_getIZ(1);
  @$pb.TagNumber(2)
  set delay($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDelay() => $_has(1);
  @$pb.TagNumber(2)
  void clearDelay() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get topic => $_getSZ(2);
  @$pb.TagNumber(3)
  set topic($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearTopic() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get last => $_getSZ(3);
  @$pb.TagNumber(4)
  set last($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLast() => $_has(3);
  @$pb.TagNumber(4)
  void clearLast() => clearField(4);
}

class Subscribe extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Subscribe', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageID', $pb.PbFieldType.O3, protoName: 'MessageID')
    ..pc<Subscription>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Subscriptions', $pb.PbFieldType.PM, protoName: 'Subscriptions', subBuilder: Subscription.create)
    ..hasRequiredFields = false
  ;

  Subscribe._() : super();
  factory Subscribe({
    $core.int? messageID,
    $core.Iterable<Subscription>? subscriptions,
  }) {
    final _result = create();
    if (messageID != null) {
      _result.messageID = messageID;
    }
    if (subscriptions != null) {
      _result.subscriptions.addAll(subscriptions);
    }
    return _result;
  }
  factory Subscribe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Subscribe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Subscribe clone() => Subscribe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Subscribe copyWith(void Function(Subscribe) updates) => super.copyWith((message) => updates(message as Subscribe)) as Subscribe; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Subscribe create() => Subscribe._();
  Subscribe createEmptyInstance() => create();
  static $pb.PbList<Subscribe> createRepeated() => $pb.PbList<Subscribe>();
  @$core.pragma('dart2js:noInline')
  static Subscribe getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Subscribe>(create);
  static Subscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get messageID => $_getIZ(0);
  @$pb.TagNumber(1)
  set messageID($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageID() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageID() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Subscription> get subscriptions => $_getList(1);
}

class Unsubscribe extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Unsubscribe', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageID', $pb.PbFieldType.O3, protoName: 'MessageID')
    ..pc<Subscription>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Subscriptions', $pb.PbFieldType.PM, protoName: 'Subscriptions', subBuilder: Subscription.create)
    ..hasRequiredFields = false
  ;

  Unsubscribe._() : super();
  factory Unsubscribe({
    $core.int? messageID,
    $core.Iterable<Subscription>? subscriptions,
  }) {
    final _result = create();
    if (messageID != null) {
      _result.messageID = messageID;
    }
    if (subscriptions != null) {
      _result.subscriptions.addAll(subscriptions);
    }
    return _result;
  }
  factory Unsubscribe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Unsubscribe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Unsubscribe clone() => Unsubscribe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Unsubscribe copyWith(void Function(Unsubscribe) updates) => super.copyWith((message) => updates(message as Unsubscribe)) as Unsubscribe; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Unsubscribe create() => Unsubscribe._();
  Unsubscribe createEmptyInstance() => create();
  static $pb.PbList<Unsubscribe> createRepeated() => $pb.PbList<Unsubscribe>();
  @$core.pragma('dart2js:noInline')
  static Unsubscribe getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Unsubscribe>(create);
  static Unsubscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get messageID => $_getIZ(0);
  @$pb.TagNumber(1)
  set messageID($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageID() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageID() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Subscription> get subscriptions => $_getList(1);
}

class ControlMessage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ControlMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'unitdb.schema'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'MessageID', $pb.PbFieldType.O3, protoName: 'MessageID')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'Message', $pb.PbFieldType.OY, protoName: 'Message')
    ..hasRequiredFields = false
  ;

  ControlMessage._() : super();
  factory ControlMessage({
    $core.int? messageID,
    $core.List<$core.int>? message,
  }) {
    final _result = create();
    if (messageID != null) {
      _result.messageID = messageID;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory ControlMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ControlMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ControlMessage clone() => ControlMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ControlMessage copyWith(void Function(ControlMessage) updates) => super.copyWith((message) => updates(message as ControlMessage)) as ControlMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ControlMessage create() => ControlMessage._();
  ControlMessage createEmptyInstance() => create();
  static $pb.PbList<ControlMessage> createRepeated() => $pb.PbList<ControlMessage>();
  @$core.pragma('dart2js:noInline')
  static ControlMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlMessage>(create);
  static ControlMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get messageID => $_getIZ(0);
  @$pb.TagNumber(1)
  set messageID($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageID() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageID() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get message => $_getN(1);
  @$pb.TagNumber(2)
  set message($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
}

