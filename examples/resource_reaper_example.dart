import 'dart:async';
import 'package:resource_reaper/resource_reaper.dart';

/// Example resource that needs disposal 
class Connection {
  final String id;
  Connection(this.id);

  void close() {
    print('Connection $id closed.');
  }
  
  @override
  /// Allows to match resource by id for Reaper.
  bool operator ==(Object other) {
    return identical(this, other) || 
      (other is Connection && other.id == id);
  }
  
  @override
  int get hashCode => id.hashCode;
}

void main() {
  // Create a ResourceReaper to manage Connection instances
  final reaper = ResourceReaper<Connection>(
    name: 'ConnectionReaper',
    size: 3, // Max 3 items tracked at a time
    itemDuration: Duration(seconds: 5), // Items expire after 5 seconds
    purgeInterval: Duration(seconds: 2), // Purge runs every 2 seconds
    onDisposeItem: (connection) => connection.close(), // Disposal callback
    verbose: true, // Enable debug logging
  );

  // Adding connections
  reaper.add(Connection('A'));
  reaper.add(Connection('B'));
  reaper.add(Connection('C'));

  // Adding a 4th connection exceeds the size limit,
  // automatically disposing of the oldest one (Connection A)
  reaper.add(Connection('D'));

  // Removing a connection manually
  final connectionE = Connection('C');
  reaper.add(connectionE);
  reaper.remove(connectionE, dispose: true); // Immediately disposes Connection C

  // Purging expired connections manually (optional)
  Timer(Duration(seconds: 6), () {
    reaper.purge(); // Purges items that exceeded itemDuration
  });

  Timer(Duration(seconds: 10), () {
    reaper.dispose();
    print('Reaper disposed.');
  });
}
