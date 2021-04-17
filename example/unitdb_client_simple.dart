import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:unitdb_client/unitdb_client.dart';
import 'package:unitdb_client/unitdb_client_web.dart';

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
      // .withInsecure()
      .withKeepAlive(30)
      .withPingTimeout(Duration(seconds: 10))
      // .withDefaultMessageHandler(onMessage)
      .withConnectionLostHandler(onConnectionLost);

  var client = WebClient("127.0.0.1:6080",
      "UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ", opts);

  print('inside main');

  try {
    await client.connect();
  } catch (e) {
    print("connection failed: ${e.toString()}");
    return;
  }

  print('connection successful');

  var subResult = client.subscribe("AZQAMYFYXeEMa/teams.alpha.*",
      deliveryMode: DeliveryMode.express);
  try {
    subResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  final topicFilter = TopicFilter("teams.alpha.*", client.messageStream);
  topicFilter.messageStream.listen((List<Message> e) {
    print("TOPIC: ${e[0].topic}\n");
    print("MSG: ${utf8.decode(e[0].payload)}\n");
  });

  for (var i = 0; i < 5; i++) {
    var msg = "Hi #${i} time!";
    var pubResult = client.publish(
        "AbYANcEGXRTLC/teams.alpha.user1", utf8.encode(msg),
        deliveryMode: DeliveryMode.express);
    try {
      await pubResult.get(Duration(seconds: 1));
    } catch (e) {
      print(e.toString());
    }
  }

  Future.delayed(Duration(seconds: 10));

  List<String> topics = ["AbYANcEGXRTLC/teams.alpha.user1"];
  var unsubResult = client.unsubscribe(topics);
  try {
    await unsubResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  await client.disconnect();
  exit(-1);
}
