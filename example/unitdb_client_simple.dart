import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:unitdb_client/unitdb_client.dart';

class Result {
  Result(
      {this.returnCode,
      this.sessionPresent,
      this.messageID,
      this.errorMessage});

  int returnCode;
  bool sessionPresent;
  int messageID;

  String errorMessage;
}

class TestClient {
  TestClient(this.clientID, {this.server = _defaultServer});

  String clientID;

  String server;

  dynamic dbclient;

  static const _defaultServer = '127.0.0.1:6080';

  final opts =
      Options().withKeepAlive(30).withPingTimeout(Duration(seconds: 10));

  Future<Result> connect() async {
    dbclient = Client(server, clientID, opts);
    Result result;

    _connectCompleter = Completer();
    try {
      final connectResult = await dbclient.connect();
      // result.get(opts.connectTimeout);
      result = Result(errorMessage: connectResult.error());
      _connectCompleter.complete(result);
    } catch (e) {
      _connectCompleter.completeError(e);
    }
    return result;
  }

  Completer<Result> _connectCompleter;
}

MessageHandler onMessage = (Connection client, Stream<Message> msgStream) {
  msgStream.listen((msg) {
    print("TOPIC: ${msg.topic}\n");
    print("MSG: ${utf8.decode(msg.payload)}\n");
  });
};

ConnectionLostHandler onConnectionLost = (Connection client) {
  print("Connection lost: \n");
  exit(-1);
};

void main() async {
  var opts = Options();
  opts
      .withInsecure()
      .withKeepAlive(30)
      .withPingTimeout(Duration(seconds: 10))
      // .withDefaultMessageHandler(onMessage)
      .withConnectionLostHandler(onConnectionLost);

  var client = Client("127.0.0.1:6080",
      "UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ", opts);

  try {
    await client.connect();
  } catch (e) {
    print("connection failed: ${e.toString()}");
    return;
  }

  var msgResult = client.subscribe("groups.private.673651407196578720.*",
      deliveryMode: DeliveryMode.express);
  try {
    await msgResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  var notificationResult = client.subscribe(
      "groups.private.673651407196578720.*.notification",
      deliveryMode: DeliveryMode.express);
  try {
    await notificationResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  final msgFilter =
      TopicFilter("groups.private.673651407196578720.*", client.messageStream);
  msgFilter.messageStream.listen((List<Message> e) {
    print("TOPIC: ${e[0].topic}\n");
    print("MSG: ${utf8.decode(e[0].payload)}\n");
  });

  final notificationFilter = TopicFilter(
      "groups.private.673651407196578720.*.notification", client.messageStream);
  notificationFilter.messageStream.listen((List<Message> e) {
    print("TOPIC: ${e[0].topic}\n");
    print("MSG: ${utf8.decode(e[0].payload)}\n");
  });

  for (var i = 0; i < 3; i++) {
    var msg = "Hi msg #${i}!";
    var pubResult = client.publish(
        "ADcABeFRBDJKe/groups.private.673651407196578720.message",
        utf8.encode(msg),
        deliveryMode: DeliveryMode.express);
    try {
      await pubResult.get(Duration(seconds: 1));
    } catch (e) {
      print(e.toString());
    }
  }

  for (var i = 0; i < 3; i++) {
    var msg = "Hi notification #${i}!";
    var pubResult = client.publish(
        "ADcABeFRBDJKe/groups.private.673651407196578720.1.notification",
        utf8.encode(msg),
        deliveryMode: DeliveryMode.express);
    try {
      await pubResult.get(Duration(seconds: 1));
    } catch (e) {
      print(e.toString());
    }
  }

  await Future.delayed(Duration(seconds: 10));

  List<String> topics = [
    "ADcABeFRBDJKe/groups.private.673651407196578720.*",
    "ADcABeFRBDJKe/groups.private.673651407196578720.*.notification"
  ];
  var unsubResult = client.unsubscribe(topics);
  try {
    await unsubResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  await client.disconnect();
  exit(-1);
}
