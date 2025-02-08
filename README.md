A lightweight resource manager for Dart and Flutter applications that handles the lifecycle and disposal of resources. Automatically purges expired items, disposes of old resources when capacity is reached, and helps prevent memory leaks.

## Features

✅ Automatic Disposal: Dispose of items when exceeding a maximum size limit.

⏱️ Time-Based Purging: Automatically purge items after a configurable expiration duration.

🗑️ Manual Control: Clear, purge, or remove items manually when needed.

⚡ Lightweight & Simple: Minimal dependencies, easy to integrate into existing projects.

## Usage

```dart
import 'package:resource_reaper/resource_reaper.dart';

class Connection {
  final String id;
  Connection(this.id);
  void close() => print('Connection $id closed.');
}

void main() {
  final reaper = ResourceReaper<Connection>(
    name: 'ConnectionReaper',
    size: 3,
    onDisposeItem: (conn) => conn.close(),
    verbose: true,
  );

  reaper.add(Connection('A'));
  reaper.add(Connection('B'));
  reaper.add(Connection('C'));
  reaper.add(Connection('D')); // Exceeds limit, disposes Connection A

  reaper.dispose(); // Clean up when done
}
```

## API Overview

| **Parameter**        | **Type**                      | **Required** | **Description**                                                                 |
|:---------------------|:------------------------------|:------------|:-------------------------------------------------------------------------------|
| `name`               | `String`                      | ✅ Yes       | Identifier for the Reaper, useful for logging and debugging.                   |
| `size`               | `int`                         | ✅ Yes       | Maximum number of items before the oldest ones are automatically disposed.     |
| `onDisposeItem`      | `void Function(T item)`       | ✅ Yes       | Callback invoked when an item is disposed.                                     |
| `itemDuration`       | `Duration?`                   | ❌ No        | Duration after which items expire and are eligible for purging.                |
| `purgeInterval`      | `Duration?`                   | ❌ No        | Frequency at which expired items are purged. Defaults to `itemDuration` if not set.|
| `verbose`            | `bool`                        | ❌ No        | Enables detailed debug logging if set to `true`. Defaults to `false`.          |
| `onFirstItemAdded`   | `void Function()?`            | ❌ No        | Optional callback triggered when the first item is added to an empty Reaper.   |
| `onLastItemRemoved`  | `void Function()?`            | ❌ No        | Optional callback triggered when the last item is removed from the Reaper.     |


## Important Notes

- Always call `dispose()` when the ResourceReaper is no longer needed to prevent memory leaks due to lingering timers.
- For custom classes, ensure `==` and `hashCode` are properly overridden for accurate item removal.
