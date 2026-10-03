part of unitdb_client;

// The server's API requests: a client publishes a request to a topic of the
// `unitdb` key, such as `unitdb/keygen`, and the server answers with a JSON
// message on the same topic, to that connection only. Connection.keygen,
// requestClientId, revoke, revokeAll and vouch send them, and complete
// their results with the answers.

/// KeyRequest asks for a topic key: what a `unitdb/keygen` request lists.
class KeyRequest {
  KeyRequest(this.topic, {this.type = 'rw', this.ttl = ''});

  /// The topic, or wildcard pattern, the key opens. A v2 key opens exactly
  /// it; a key for "..." opens every topic of the contract.
  final String topic;

  /// What the key allows: `r` (read), `w` (write), `a` (admin) or `o`
  /// (owner), combined, such as `rw`.
  final String type;

  /// How long the key lasts, as a Go duration such as "24h" or "90m"; "0"
  /// never expires. Empty, the default, is the server's `topic_key_ttl`,
  /// which never expires unless set. A cluster with nodes that don't read
  /// v2 keys yet refuses a ttl with status 503.
  final String ttl;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'type': type,
        if (ttl.isNotEmpty) 'ttl': ttl,
      };
}

/// TopicKey is a key the server issued for a topic, as `unitdb/keygen`
/// answers it.
class TopicKey {
  TopicKey(this.status, this.key, this.topic, this.uuid);

  TopicKey.fromJson(Map<String, dynamic> json)
      : status = json['status'] as int? ?? 0,
        key = json['key'] as String? ?? '',
        topic = json['topic'] as String? ?? '',
        uuid = json['uuid'] as String? ?? '';

  final int status;

  /// The key, opaque: publish and subscribe to `<key>/<topic>`. The server
  /// issues v2 keys, 48 characters of base64url (`A-Z`, `a-z`, `0-9`, `-`,
  /// `_`); a cluster with nodes that don't read v2 keys yet issues v1 ones,
  /// of 26 characters.
  final String key;

  final String topic;

  /// The key's uuid, in decimal, to revoke it with Connection.revoke; empty
  /// for a v1 key, which has none.
  final String uuid;
}

/// ApiResult is the result of a request to the server's API: it completes
/// when the server answers, with an error unless the answer's status is 200.
class ApiResult extends Result {
  int? _status;
  String? _message;

  /// The status the server answered with, as HTTP's: 200 when it took the
  /// request; null until it answers, or if it did not.
  int? get status => _status;

  /// The message of an answer that refused the request.
  String? get message => _message;

  /// _take completes the result with the server's answer.
  void _take(Object? answer) {
    if (answer is Map) {
      _status = answer['status'] as int?;
      _message = answer['message'] as String?;
      if (_status != 200) {
        setError('status $_status: ${_message ?? 'refused'}');
        return;
      }
      _takeAnswer(answer);
      flowComplete();
      return;
    }
    setError('unexpected answer: $answer');
  }

  /// _takeAnswer takes the fields of an answer with status 200.
  void _takeAnswer(Map answer) {}
}

/// KeyGenResult is the result of Connection.keygen: the keys the server
/// issued, one for each request, in order.
class KeyGenResult extends ApiResult {
  List<TopicKey> _keys = const [];

  List<TopicKey> get keys => _keys;

  @override
  void _take(Object? answer) {
    // Keys are answered as a list; a refusal as one object.
    if (answer is List) {
      _keys = [
        for (final k in answer)
          if (k is Map<String, dynamic>) TopicKey.fromJson(k)
      ];
      _status = _keys.isEmpty ? 200 : _keys.first.status;
      flowComplete();
      return;
    }
    super._take(answer);
  }
}

/// ClientIdResult is the result of Connection.requestClientId: a new
/// secondary client ID of the contract.
class ClientIdResult extends ApiResult {
  String _clientId = '';
  String _uuid = '';

  /// The new client ID, opaque. The server issues v2 IDs, 94 characters of
  /// base64url (`A-Z`, `a-z`, `0-9`, `-`, `_`), or v1 ones, of 52, in a
  /// cluster with nodes that don't read v2 IDs yet.
  String get clientId => _clientId;

  /// The ID's uuid, in decimal, to revoke it with Connection.revoke; empty
  /// for a v1 ID, which has none.
  String get uuid => _uuid;

  @override
  void _takeAnswer(Map answer) {
    _clientId = answer['key'] as String? ?? '';
    _uuid = answer['uuid'] as String? ?? '';
  }
}

/// _ApiRequest is a request waiting for the server's answer: r, completed
/// by the answer, and p, the publish that carries it, completed when the
/// server acknowledges it.
class _ApiRequest {
  _ApiRequest(this.r, this.p);
  final ApiResult r;
  final PublishResult p;
}
