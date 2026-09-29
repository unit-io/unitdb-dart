## Unreleased

Works with unitdb v0.4.0 and v0.5.0, which require the server to have an
encryption key of its own.

### Fixes

- Reconnecting works. With auto reconnect (the default), a client whose
  connection is lost now:
  - resumes its session, so reliable messages in flight are delivered,
  - subscribes again to its topics, and
  - sends again what the server had not acknowledged.

  Before, it reconnected but received nothing on its subscriptions.
- A publish, subscribe, unsubscribe or relay made while the client
  reconnects waits for the connection, up to the write timeout. Before, it
  was sent into the lost connection and never completed.
- `disconnect` while reconnecting stops the reconnect, and the client stays
  closed.
- Without auto reconnect, a client whose connection is lost closes: its
  calls fail at once, instead of never completing.
- Message identifiers are per client. They were shared by every client in
  the process, so one client losing its connection failed the other
  clients' pending calls.

### Added

- `Options.withSessionKey`, as unitdb-go's `WithSessionKey`: the server keys
  a session by the client ID and this key, so clients sharing a client ID
  can keep separate sessions.

### Tests

- The Go-server tests run against unitdb v0.4.0 and later. They use a key
  of their own, and ask the server for client IDs.
- Reconnection tests against the Go server, ported from unitdb-go: a
  server restart, a publish made while reconnecting, `disconnect` while
  reconnecting, auto reconnect off, and the next server when the first is
  down.
- A reconnect resumes the session: reliable messages whose notifications
  the client lost with its connection are delivered after it reconnects.
  With a clean session on reconnect, the test fails.

## 0.2.0

First tagged release. Earlier builds could not talk to the unitdb server, so
upgrade from any git revision before this one.

### Breaking changes

- The client now uses the server's schema (`unitdb.schema.Unitdb`). Earlier
  builds called `/unitdb.Unitdb/Stream`, which the server rejects as
  UNIMPLEMENTED, and sent several fields under the wrong numbers.
- `connect` completes its result with an error and the server's return code
  when the connection is refused. It used to throw a string.
- `Result.get` returns once the call completes, and returns `false` on
  timeout.

### Deprecated

- `withSessionData` and relay request tags. The server does not support them,
  so they are no longer sent.

### Fixes

- Publish sends the delivery mode you ask for. It was dropped, so every
  message went out as express and reliable and batch delivery never happened.
- Received messages are acknowledged to the server: ACKNOWLEDGE for express,
  RECEIPT for reliable and batch.
- `connect` sends the keep-alive interval, and credentials in the server URL
  no longer crash it.
- `disconnect` sends DISCONNECT before closing the stream, and writing after
  close is safe.
- Disconnecting with calls still pending no longer throws
  "Future already completed".
- A stream closed by the server is reported as a lost connection, and unknown
  packet types are skipped instead of stopping the read loop.
- A trailing `...` wildcard matches deeper topics and the parent topic, and a
  topic after a key prefix keeps any further `/`.
- Lengths of 128 bytes and more are encoded correctly.
- Batch thresholds you set are kept, and `withStoreLogReleaseDuration` works
  before a write timeout is set.

### Compatibility

- Tested against the unitdb server v0.3.0.
