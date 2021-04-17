import 'package:unitdb_client/unitdb_client.dart' as unitdb;

class Message {
  final String topic;
  final String message;
  final unitdb.DeliveryMode deliveryMode;

  Message({this.topic, this.message, this.deliveryMode});
}
