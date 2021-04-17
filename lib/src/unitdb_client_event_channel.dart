part of unitdb_client;

class Event {
  const Event();

  static const List<Event> any = <Event>[Event()];

  static const List<Event> none = <Event>[];
}

abstract class IEventChannel<E extends Event> {
  final EventChannel<E> _delegate = EventChannel<E>();

  Stream<List<E>> get changes => _delegate.changes;

  @protected
  @mustCallSuper
  @Deprecated('User EventChannel instead to have this method available')
  void observed() => _delegate.observed();

  @protected
  @mustCallSuper
  @Deprecated('User EventChannel instead to have this method available')
  void unobserved() => _delegate.unobserved();

  @Deprecated('User EventChannel instead to have this method available')
  bool get hasObservers => _delegate.hasObservers;

  @Deprecated('User EventChannel instead to have this method available')
  bool emit() => _delegate.emit();

  @Deprecated('User EventChannel instead to have this method available')
  void notify([E event]) => _delegate.notify(event);
}

class EventChannel<E extends Event> implements IEventChannel<E> {
  EventChannel<E> _delegate;

  StreamController<List<E>> _changes;

  bool _scheduled = false;
  List<E> _queue;

  @override
  Stream<List<E>> get changes =>
      (_changes ??= StreamController<List<E>>.broadcast(
              sync: true, onListen: observed, onCancel: unobserved))
          .stream;

  @override
  @mustCallSuper
  void observed() {}

  @override
  @mustCallSuper
  void unobserved() {
    _changes = _queue = null;
  }

  @override
  @mustCallSuper
  bool emit() {
    List<E> changes;
    if (_scheduled && hasObservers) {
      if (_queue != null) {
        changes = _queue;
        _queue = null;
      } else {
        changes = Event.any;
      }
      _scheduled = false;
      _changes.add(changes);
    }
    return changes != null;
  }

  @override
  bool get hasObservers => _changes?.hasListener == true;

  @override
  void notify([E event]) {
    if (!hasObservers) {
      return;
    }
    if (event != null) {
      (_queue ??= <E>[]).add(event);
    }
    if (!_scheduled) {
      scheduleMicrotask(emit);
      _scheduled = true;
    }
  }
}
