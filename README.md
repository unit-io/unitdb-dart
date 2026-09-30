## The unitdb server is an open source messaging system for microservice, and real-time internet connected devices. The unitdb messaging API is built for speed and security.

The unitdb server is a real-time messaging system for microservices, and real-tme internet connected devices, it is based on Grpc communication. The unitdb satisfy the requirements for low latency and binary messaging, it is perfect messaging system for internet connected devices.

The unitdb_client is an implementation of unitdb messaging system supporting subscription/publishing at all delivery modes, keep alive and synchronous connection. The client is designed to take as messaging protocol work off the user as possible, connection protocol is handled automatically as are the message exchanges needed to support the different delivery modes and the keep alive mechanism. This allows the user to concentrate on publishing/subscribing and not the details of messaging itself.

## Quick Start
To build [unitdb](https://github.com/unit-io/unitdb) from source code use go get command and copy unitdb.conf to the path unitdb binary is placed.

> go get -u github.com/unit-io/unitdb/server

The server needs an encryption key of its own: set `encryption_config`'s `key` in unitdb.conf, or the `UNITDB_ENCRYPTION_KEY` environment variable, to 32 random characters, for example the output of `openssl rand -base64 24`. Client IDs are signed with it, so clients need IDs issued by that server.

### Usage
Make use of the client by importing the packet to your Flutter or Dart project. For example,

import "package:unitdb_client"

Samples are available in the example directory for reference.

### Reconnecting
With auto reconnect, which is on by default, a client whose connection is lost connects again by itself, trying each server in turn (the target, after any added with `addServer`), and pausing longer after each failed round, up to `withMaxReconnectDuration`:

```dart
final client = Client(
    'grpc://node-one:6080',
    clientID,
    Options()
      ..addServer('grpc://node-two:6080')
      ..withMaxReconnectDuration(const Duration(seconds: 10))
      ..withConnectionLostHandler(() => print('connection lost'))
      ..withConnectionHandler((_) => print('connected')));
```

Once connected, it resumes its session, so reliable messages in flight are delivered, subscribes again to its topics, and sends again what the server had not acknowledged. Calls made while it reconnects wait for the connection, up to the write timeout. A message in flight when the connection drops can be delivered twice. With `withAutoReconnect(false)`, a client closes when its connection is lost, and its calls fail from then on.

## Contributing
If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are welcome.

## Licensing
This project is licensed under [MIT License](https://github.com/unit-io/unitdb-dart/blob/master/LICENSE).