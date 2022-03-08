@REM protoc proto\unitdb.proto --proto_path=proto --plugin=protoc-gen-dart=C:\flutter\.pub-cache\bin\protoc-gen-dart.bat  --dart_out=grpc:v1

protoc --proto_path=unitdb --dart_out=grpc:unitdb -Iprotos unitdb/schema.proto
