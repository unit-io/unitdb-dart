part of unitdb_client;

class ByteBuffer {
  ByteBuffer(this.buffer);

  ByteBuffer.fromList(List<int> data) {
    buffer = typed.Uint8Buffer();
    buffer.addAll(data);
  }

  int _position = 0;

  typed.Uint8Buffer buffer;

  int get position => _position;

  int get length => buffer.length;

  int get availableBytes => length - _position;

  set skipBytes(int nBytes) => _position += nBytes;

  void addAll(List<int> data) {
    buffer.addAll(data);
  }

  void shrink() {
    buffer.removeRange(0, _position);
    _position = 0;
  }

  int readByte() {
    final b = buffer[_position];
    if (_position <= (length - 1)) {
      _position++;
    } else {
      return -1;
    }
    return b;
  }

  typed.Uint8Buffer read(int count) {
    if ((length < count) || (_position + count > length)) {
      throw Exception('''unitdb_client::ByteBuffer: The buffer did not have 
      enough bytes for the read operation 
      length $length, count, $count, position $_position, buffer $buffer
      ''');
    }

    final tmp = typed.Uint8Buffer();
    tmp.addAll(buffer.getRange(_position, _position + count));
    _position += count;
    final tmp2 = typed.Uint8Buffer();
    tmp2.addAll((tmp));

    return tmp2;
  }

  typed.Uint8Buffer readAll() {
    final tmp = typed.Uint8Buffer();
    tmp.addAll(buffer.getRange(0, length));
    _position = length;

    return tmp;
  }

  typed.Uint8Buffer getRange(int start, int end) {
    final tmp = typed.Uint8Buffer();
    tmp.addAll(buffer.getRange(start, end));
    return tmp;
  }

  void removeRange(int start, int end) {
    buffer.removeRange(start, end);
  }

  void writeByte(int b) {
    if (buffer.length == _position) {
      buffer.add(b);
    } else {
      buffer[_position] = b;
    }
    _position++;
  }

  void write(typed.Uint8Buffer buffer) {
    if (this.buffer == null) {
      this.buffer = buffer;
    } else {
      this.buffer.addAll((buffer));
    }
    _position = length;
  }

  void writeList(List<int> data) {
    this.buffer.addAll((data));
    _position = length;
  }

  void seek(int pos) {
    if ((pos <= _position) && (pos >= 0)) {
      _position = pos;
    } else {
      _position = length;
    }
  }

  void reset() {
    _position = 0;
  }

  @override
  String toString() {
    if (buffer != null && buffer.isNotEmpty) {
      return 'null or empty';
    } else {
      return buffer.toList().toString();
    }
  }
}
