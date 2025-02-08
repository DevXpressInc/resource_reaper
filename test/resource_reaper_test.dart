import 'package:fake_async/fake_async.dart';
import 'package:resource_reaper/resource_reaper.dart';
import 'package:test/test.dart';

class Connection {
  final String id;
  Connection(this.id);

  bool _isClosed = false;

  bool get isClosed => _isClosed;

  void close() {
    _isClosed = true;
  }

  /// Allows to match resource by id for Reaper.
  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Connection && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('Basic usage', () {
    test('Overflow bucket', () {
      final bucketManager = ResourceReaper<Connection>(
        size: 5,
        name: 'Bucket',
        onDisposeItem: (connection) => connection.close(),
      );
      final connections = List.generate(5, (index) {
        final connection = Connection(index.toString());
        bucketManager.add(connection);

        return connection;
      });

      expect(connections.every((connection) => !connection.isClosed), isTrue);

      final additionalconnections = List.generate(2, (index) {
        final connection = Connection(index.toString());
        bucketManager.add(connection);

        return connection;
      });

      expect(additionalconnections.every((connection) => !connection.isClosed),
          isTrue);

      final expectedIsClosed =
          List.unmodifiable([true, true, false, false, false]);
      final result =
          connections.map((connection) => connection.isClosed).toList();

      expect(result, equals(expectedIsClosed));
    });

    test('Clear bucket', () {
      final bucketManager = ResourceReaper<Connection>(
          name: 'Bucket',
          onDisposeItem: (connection) => connection.close(),
          size: 5);
      final initialconnections = List.generate(5, (index) {
        final connection = Connection(index.toString());
        bucketManager.add(connection);

        return connection;
      });

      bucketManager.clear();

      expect(initialconnections.every((connection) => connection.isClosed),
          isTrue);
    });

    test('Remove from bucket', () {
      final bucketManager = ResourceReaper<Connection>(
          name: 'Bucket',
          onDisposeItem: (connection) => connection.close(),
          size: 5);
      final initialconnections = List.generate(5, (index) {
        final connection = Connection(index.toString());
        bucketManager.add(connection);

        return connection;
      });

      bucketManager.remove(initialconnections[2]);

      bucketManager.clear();

      final expectedIsClosed =
          List.unmodifiable([true, true, false, true, true]);
      final result =
          initialconnections.map((connection) => connection.isClosed).toList();

      expect(result, equals(expectedIsClosed));
    });
  });

  group('Flush usage', () {
    test('items are flushed when too old', () {
      fakeAsync((async) {
        final bucketManager = ResourceReaper<Connection>(
            name: 'Bucket',
            size: 5,
            onDisposeItem: (connection) => connection.close(),
            itemDuration: Duration(minutes: 5),
            purgeInterval: Duration(minutes: 1));
        final initialconnections = List.generate(2, (index) {
          final connection = Connection(index.toString());
          bucketManager.add(connection);

          return connection;
        });
        async.elapse(Duration(minutes: 3));
        final additionalconnections = List.generate(2, (index) {
          final connection = Connection(index.toString());
          bucketManager.add(connection);

          return connection;
        });
        async.elapse(Duration(minutes: 3));

        expect(initialconnections.every((connection) => connection.isClosed),
            isTrue);
        expect(
            additionalconnections.every((connection) => !connection.isClosed),
            isTrue);
      });
    });
  });
}
