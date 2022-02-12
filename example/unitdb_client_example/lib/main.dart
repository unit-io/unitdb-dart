import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:unitdb_client/unitdb_client.dart' as udb;
// import 'package:unitdb_client/unitdb_web_client.dart' as web;
import 'package:unitdb_client_example/models/message.dart';
import 'package:unitdb_client_example/dialogs/send_message.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _internetConnectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  PageController _pageController;
  int _page = 0;

  String server = 'grpc://10.0.2.2:6080';
  udb.Client client;
  // String server = 'ws://localhost:6060';
  // web.WebClient client;

  StreamSubscription subscription;

  TextEditingController topicController = TextEditingController();
  Set<String> topics = Set<String>();

  List<Message> messages = <Message>[];
  ScrollController messageController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _internetConnectionStatus = result.toString();
        if (_internetConnectionStatus != "ConnectivityResult.none") {
          _connect();
        }
      });
    });
  }

  bool disconnected;

  @override
  void dispose() {
    _pageController = PageController();
    _connectivitySubscription.cancel();
    subscription?.cancel();
    super.dispose();
  }

  void Ttimer() async {
    do {
      await _connect().catchError((e) async {
        print(e);
        print("not connecting");
        await _connect();
      });
    } while (disconnected);
  }

  @override
  Widget build(BuildContext context) {
    IconData connectionStateIcon;
    if (client != null) {
      connectionStateIcon = Icons.cloud_done;
    } else {
      connectionStateIcon = Icons.cloud_off;
    }
    void navigationTapped(int page) {
      _pageController.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }

    void onPageChanged(int page) {
      setState(() {
        this._page = page;
      });
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(server),
              SizedBox(
                width: 8.0,
              ),
              Icon(connectionStateIcon),
            ],
          ),
        ),
        floatingActionButton: _page == 2
            ? Builder(builder: (BuildContext context) {
                return FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute<String>(
                          builder: (BuildContext context) =>
                              SendMessageDialog(client: client),
                          fullscreenDialog: true,
                        ));
                  },
                );
              })
            : null,
        bottomNavigationBar: BottomNavigationBar(
          onTap: navigationTapped,
          currentIndex: _page,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              title: Text('Server'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_add),
              title: Text('Subscriptions'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              title: Text('Messages'),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: onPageChanged,
          children: <Widget>[
            _buildServerPage(connectionStateIcon),
            _buildSubscriptionsPage(),
            _buildMessagesPage(),
          ],
        ),
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<Null> initConnectivity() async {
    String connectionStatus;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      connectionStatus = (await _connectivity.checkConnectivity()).toString();
    } on PlatformException catch (e) {
      print(e.toString());
      connectionStatus = 'Failed to get connectivity.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    setState(() {
      _internetConnectionStatus = connectionStatus;
    });
  }

  Column _buildServerPage(IconData connectionStateIcon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              server,
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(width: 8.0),
            Icon(connectionStateIcon),
          ],
        ),
        SizedBox(height: 8.0),
        RaisedButton(
          child: Text(client != null ? 'Disconnect' : 'Connect'),
          onPressed: _internetConnectionStatus != "ConnectivityResult.none"
              ? () {
                  if (client != null) {
                    _disconnect();
                  } else {
                    _connect();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Column _buildMessagesPage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: messageController,
            children: _buildMessageList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
            child: Text('Clear'),
            onPressed: () {
              setState(() {
                messages.clear();
              });
            },
          ),
        )
      ],
    );
  }

  Column _buildSubscriptionsPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200.0,
              child: TextField(
                controller: topicController,
                onSubmitted: (String topic) {
                  _subscribeToTopic(topic);
                },
                decoration: InputDecoration(hintText: 'Please enter a topic'),
              ),
            ),
            SizedBox(width: 8.0),
            RaisedButton(
              child: Text('add topic'),
              onPressed: () {
                _subscribeToTopic(topicController.value.text);
              },
            ),
          ],
        ),
        SizedBox(height: 16.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.start,
          children: _buildTopicList(),
        )
      ],
    );
  }

  List<Widget> _buildMessageList() {
    return messages
        .map((Message message) => Card(
              color: Colors.white70,
              child: ListTile(
                trailing: CircleAvatar(
                    radius: 14.0,
                    backgroundColor: Theme.of(context).accentColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'DeliveryMode',
                          style: TextStyle(fontSize: 8.0),
                        ),
                        Text(
                          message.deliveryMode.index.toString(),
                          style: TextStyle(fontSize: 8.0),
                        ),
                      ],
                    )),
                title: Text(message.topic),
                subtitle: Text(message.message),
                dense: true,
              ),
            ))
        .toList()
        .reversed
        .toList();
  }

  List<Widget> _buildTopicList() {
    // Sort topics
    final List<String> sortedTopics = topics.toList()
      ..sort((String a, String b) {
        return compareNatural(a, b);
      });
    return sortedTopics
        .map((String topic) => Chip(
              label: Text(topic),
              onDeleted: () {
                _unsubscribeFromTopic(topic);
              },
            ))
        .toList();
  }

  Future _connect() async {
    var opts = udb.Options();
    opts
        // .withInsecure()
        .withKeepAlive(300)
        .withPingTimeout(Duration(seconds: 60))
        // .withDefaultMessageHandler(onMessage)
        .withConnectionLostHandler(onConnectionLost);

    /// First create a client, the client is constructed with a server name, client identifier
    /// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
    /// client connecting to Unite server. As the word identifier already suggests, it should be unique per server.
    /// The server uses it for identifying the client and the current state of the client.
    /// A condition is that clean session connect flag is true, otherwise the connection will be rejected.
    /// The client identifier can be a maximum length of 23 characters. If a port is not specified the standard port
    /// of 1883 is used.
    /// If you want to use websockets rather than TCP see below.
    client = udb.Client(
        server, "UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ", opts);

    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception.
    /// To use websockets add the following lines -:
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the server will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client.connect();
    } catch (e) {
      print("connection failed: ${e.toString()}");
      return;
    }

    print('connection successful');

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    final topicFilter = udb.TopicFilter(
        "AbcANeDcBcKXS/LivingIndia.Groups.Private.Saffat",
        client.messageStream);
    subscription = topicFilter.messageStream.listen(_onMessage);
  }

  void _disconnect() {
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    setState(() {
      topics.clear();
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('Unite client disconnected');
    setState(() {
      disconnected = true;
    });
    // Ttimer();
  }

  udb.ConnectionLostHandler onConnectionLost = () {
    print("Connection lost: \n");
  };

  void _onMessage(List<udb.Message> e) {
    print(e.length);
    print("TOPIC: ${e[0].topic}\n");
    print("MSG: ${utf8.decode(e[0].payload)}\n");
    // print("DeliveryMode: ${e[0].deliveryMode}\n");

    final String message = utf8.decode(e[0].payload);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print('Unite message: topic is <${e[0].topic}>, '
        'payload is <-- ${message} -->');
    setState(() {
      messages.add(Message(
          topic: e[0].topic,
          message: message,
          deliveryMode: udb.DeliveryMode.values[0]));
      try {
        messageController.animateTo(
          0.0,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } catch (_) {
        // ScrollController not attached to any scroll views.
      }
    });
  }

  void _subscribeToTopic(String topic) {
    setState(() {
      if (topics.add(topic.trim())) {
        print('Subscribing to ${topic.trim()}');
        client.subscribe(topic, deliveryMode: udb.DeliveryMode.express);
      }
    });
  }

  void _unsubscribeFromTopic(String topic) {
    setState(() {
      if (topics.remove(topic.trim())) {
        print('Unsubscribing from ${topic.trim()}');
        client.unsubscribe(topics.toList());
      }
    });
  }
}
