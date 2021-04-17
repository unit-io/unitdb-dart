## The unitdb server is an open source messaging system for microservice, and real-time internet connected devices. The unitdb messaging API is built for speed and security.

The unitdb server is a real-time messaging system for microservices, and real-tme internet connected devices, it is based on Grpc communication. The unitdb satisfy the requirements for low latency and binary messaging, it is perfect messaging system for internet connected devices.

The unitdb_client is an implementation of unitdb messaging system supporting subscription/publishing at all delivery modes, keep alive and synchronous connection. The client is designed to take as messaging protocol work off the user as possible, connection protocol is handled automatically as are the message exchanges needed to support the different delivery modes and the keep alive mechanism. This allows the user to concentrate on publishing/subscribing and not the details of messaging itself.

## Quick Start
To build [unitdb](https://github.com/unit-io/unitdb) from source code use go get command and copy unitdb.conf to the path unitdb binary is placed.

> go get -u github.com/unit-io/unitdb/server

### Usage
Make use of the client by importing the packet to your Flutter or Dart project. For example,

import "package:unitdb_client"

Samples are available in the example directory for reference.

## Contributing
If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are welcome.

## Licensing
This project is licensed under [MIT License](https://github.com/unit-io/unitdb-dart/blob/master/LICENSE).