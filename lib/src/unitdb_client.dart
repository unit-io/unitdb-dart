part of unitdb_client;

class Client extends Connection {
  Client(String target, String clientID, Options opts)
      : super(target, clientID, opts) {
    connectionHandler = GrpcConnectionHandler();
  }
}
