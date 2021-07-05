part of unitdb_web_client;

class WebClient extends Connection {
  WebClient(String target, String clientID, Options opts)
      : super(target, clientID, opts) {
    connectionHandler = WebsocketConnectionHandler();
  }
}
