## The unitdb server is an open source messaging system for microservice, and real-time internet connected devices. The unitdb messaging API is built for speed and security.

The unitdb server is a real-time messaging system for microservices, and real-tme internet connected devices, it is based on Grpc communication. The unitdb satisfy the requirements for low latency and binary messaging, it is perfect messaging system for internet connected devices.

The unitdb_client is an implementation of unitdb messaging system supporting subscription/publishing at all delivery modes, keep alive and synchronous connection. The client is designed to take as messaging protocol work off the user as possible, connection protocol is handled automatically as are the message exchanges needed to support the different delivery modes and the keep alive mechanism. This allows the user to concentrate on publishing/subscribing and not the details of messaging itself.

## Quick Start
To build [unitdb](https://github.com/unit-io/unitdb) from source code use go get command and copy unitdb.conf to the path unitdb binary is placed.

> go get -u github.com/unit-io/unitdb/server

The server needs an encryption key of its own: set `encryption_config`'s `key` in unitdb.conf, or the `UNITDB_ENCRYPTION_KEY` environment variable, to 32 random characters, for example the output of `openssl rand -base64 24`. Client IDs are signed with it, so clients need IDs issued by that server.

Clients publish and subscribe with topic keys, which a primary client generates with a `unitdb/keygen` request. Since unitdb v0.6.0 the server refuses a client that connects with `withInsecure()` (Connect Return Code 4, `ConnectReturnCode.ErrNotAuthorized`), unless its unitdb.conf sets `"allow_insecure": true`, which is for development only and which a cluster node refuses to start with. A trusted backend needs no topic keys either: give it a service client ID, which the server's `mintid` command issues (`go run ./server/cmd/mintid -config server/unitdb.conf -contract <contract> -service`). Keep service IDs on servers, never on clients or devices.

Topics whose first part starts with `$` are reserved for the server, and a session belongs to the client ID that started it.

### Client IDs, topic keys and revocation
Since unitdb's security stage 2, the server issues v2 client IDs, of 94 characters, and v2 topic keys, of 48, both base64url (`A-Z`, `a-z`, `0-9`, `-`, `_`). Treat them as opaque strings; the client takes them as they are. Since unitdb v0.7.0, the server refuses v1 client IDs (52 characters), at connect with `ConnectReturnCode.ErrRefusedIDRejected` and without a new ID, and v1 topic keys (26 characters) and unsigned ones (13), with status 401. A v0.6.0 server still takes v1 IDs and keys (unsigned keys only when its config sets `accept_unsigned_keys`), and renews a v1 ID as v2 when its client connects; for an ID kept in a config, the server's `mintid -from <v1 id>` seals it again as v2, the same ID.

A client ID may expire (the server's `client_id_ttl` and `primary_id_ttl`). When a client connects with an ID sealed with a key being retired, or with one past 80% of its lifetime (or, on a v0.6.0 server, with a v1 ID), the server sends it the same ID sealed again, with a new expiry, on `unitdb/clientid/`. The client takes it, and connects with it from then on, reconnects included; `client.clientId` returns it. Keep it, to connect with it the next time the app starts: an expired ID is refused with `ConnectReturnCode.ErrRefusedIDRejected`.

```dart
final client = Client('grpc://localhost:6080', storedClientId,
    Options()..withClientIdHandler((id) => saveClientId(id)));
```

The client's local store (`PersistenceStore.Localdb`) is kept by user name, and its session on the server by the ID's contract and identity, so both stay across a renewal.

A primary client manages its contract's IDs and keys with the server's API requests. Each returns a result that completes with the server's answer, and fails with its `status` (as HTTP's) when the server refuses it:

```dart
// Topic keys, with an optional ttl (a Go duration); each has a uuid.
final keys = client.keygen([KeyRequest('teams.alpha...', type: 'rw', ttl: '24h')]);
await keys.get(const Duration(seconds: 5));
client.subscribe('${keys.keys.single.key}/teams.alpha...');

// A secondary client ID, and its uuid.
final id = client.requestClientId();
await id.get(const Duration(seconds: 5)); // id.clientId, id.uuid

// Revoke an ID or a key by its uuid, for ever or until a time; or
// everything the contract was issued before now, the caller's ID included.
await client.revoke(keys.keys.single.uuid).get(const Duration(seconds: 5));
await client.revoke(id.uuid, until: DateTime.now().add(const Duration(days: 1)))
    .get(const Duration(seconds: 5));
await client.revokeAll().get(const Duration(seconds: 5));
```

A backend that opens a connection for a user can have its service ID vouch for it, so that it publishes and subscribes without topic keys: `client.vouch(serviceClientId)`. Keep service IDs on servers.

### Connect return codes
`ConnectResult.returnCode` is the code of the server's CONNACK, an index of `ConnectReturnCode`, as unitdb's docs/utp.md lists them: 0 `Accepted`, 1 `ErrRefusedBadProtocolVersion`, 2 `ErrRefusedIDRejected` (a missing, invalid, expired or revoked client ID), 3 `ErrRefusedBadID`, 4 `ErrNotAuthorized` (a refused key, or `withInsecure()` without `allow_insecure`), 5 `ErrServerError`, 6 `ErrBadToken`, 7 `ErrForbidden`, 8 `ErrSessionInUse`, 9 `ErrUnknownEpoch`. A connect that no server answered reports `ErrServerUnavailable`, 10, the client's own.

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