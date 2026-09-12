class AiCache {
  final int _maxEntries;
  final _LinkedHashMap<String, dynamic> _cache = _LinkedHashMap<String, dynamic>();

  AiCache({int maxEntries = 200}) : _maxEntries = maxEntries;

  dynamic get(String key) {
    final normalized = _normalize(key);
    final value = _cache[normalized];
    if (value != null) {
      _cache.remove(normalized);
      _cache[normalized] = value;
    }
    return value;
  }

  void set(String key, dynamic value) {
    final normalized = _normalize(key);
    _cache[normalized] = value;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  void invalidate() => _cache.clear();

  String _normalize(String input) => input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

class _LinkedHashMap<K, V> {
  final Map<K, _Node<K, V>> _map = {};
  _Node<K, V>? _head;
  _Node<K, V>? _tail;

  V? operator [](K key) => _map[key]?.value;

  void operator []=(K key, V value) {
    remove(key);
    final node = _Node<K, V>(key: key, value: value);
    _map[key] = node;
    if (_tail != null) {
      _tail!.next = node;
      node.prev = _tail;
    } else {
      _head = node;
    }
    _tail = node;
  }

  void remove(K key) {
    final node = _map.remove(key);
    if (node == null) return;
    if (node.prev != null) node.prev!.next = node.next;
    if (node.next != null) node.next!.prev = node.prev;
    if (_head == node) _head = node.next;
    if (_tail == node) _tail = node.prev;
  }

  void clear() {
    _map.clear();
    _head = null;
    _tail = null;
  }

  K get first => _head!.key;
  bool get isEmpty => _map.isEmpty;
  int get length => _map.length;
  Iterable<K> get keys => _map.keys;
}

class _Node<K, V> {
  final K key;
  final V value;
  _Node<K, V>? prev;
  _Node<K, V>? next;
  _Node({required this.key, required this.value});
}
