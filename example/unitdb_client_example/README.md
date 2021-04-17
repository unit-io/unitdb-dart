# Unite Messaging in the Flutter Project

Flutter is Google’s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase. Flutter provides a rich set of components and interfaces, the developer can quickly add native expansion for Flutter. At the same time, Flutter also uses a Native engine to render view. There is no doubt that it can provide a good experience for users.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

Unite Messaging is a lightweight and high performance publish-subscribe messaging system. It can enable stable transmission over severely restricted device hardware and high-latency / low-bandwidth network.

## Getting Started

### Create a new project, add dependencies into file pubspec.yaml:
dependencies: 
  unitdb_client: ^0.1.0

### Install dependencies:
flutter pub get

### Import
import 'package:unitdb_client/unitdb_client.dart';

### Use of unitdb_client
Connect to Unite messaging server

```

var opts = Options();
  opts
      // .withInsecure()
      .withKeepAlive(30)
      .withPingTimeout(Duration(seconds: 10))
      // .withDefaultMessageHandler(onMessage)
      .withConnectionLostHandler(onConnectionLost);

  var client = Client("127.0.0.1:6061",
      "UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ", opts);

```

#### The callback methods

```

MessageHandler onMessage = (Connection client, Stream<Message> msgStream) {
  msgStream.listen((msg) {
    print("TOPIC: ${msg.topic}\n");
    print("MSG: ${msg.payload}\n");
  });
};

ConnectionLostHandler onConnectionLost = (Connection client) {
  print("Connection lost: \n");
  exit(-1);
};

```

#### The connection to Unite messaging server

```

try {
    await client.connect();
  } catch (e) {
    print("connection failed: ${e.toString()}");
    return;
  }

```

#### The description of subscribing, publishing and unsubscribing to topic.

```

var subResult =
      client.subscribe("AZQAMYFYXeEMa/teams.alpha.*", qos: Qos.atLeastOnce);
  try {
    subResult.get(Duration(seconds: 1));
  } catch (e) {
    print(e.toString());
  }

  final topicFilter = TopicFilter("teams.alpha.*", client.messageStream);
  topicFilter.messageStream.listen((List<Message> e) {
    print("TOPIC: ${e[0].topic}\n");
    print("MSG: ${e[0].payload}\n");
  });

  for (var i = 0; i < 5; i++) {
    var msg = "Hi #${i} time!";
    var pubResult = client.publish("AbYANcEGXRTLC/teams.alpha.user1", msg,
        qos: Qos.atLeastOnce);
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

```

#### Disconnect

```

client.disconnect();

```