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
