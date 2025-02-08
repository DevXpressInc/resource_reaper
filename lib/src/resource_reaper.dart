import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:resource_reaper/src/logger.dart';

/// [ResourceReaper] is a resource manager that handles lifecycle and disposal of items of type [T].
///
/// If the [size] limit is reached, older resources are disposed through the [onDisposeItem] callback.
///
/// If set, items added to this resource manager are tracked for [itemDuration] and will be purged at [purgeInterval] if they are expired.
///
/// This allows for keeping cached resources alive for longer, while preventing memory leaks if too many are cached.
///
/// ⚠️ **Important:**
///
/// Always call [dispose] when the reaper is no longer needed to release timers and free up system resources.
///
/// Failing to call [dispose] may lead to memory leaks due to lingering timers.
///
/// ⚠️ **Thread Safety Notice:**
///
/// [ResourceReaper] is designed for single-threaded environments, like typical Flutter apps.
///
/// It is **not thread-safe** for concurrent access across multiple isolates.
/// If you plan to use this class in a multi-isolate environment, you are responsible for
/// implementing appropriate synchronization mechanisms.
///
/// For most Flutter use cases, this class is safe to use without additional thread safety measures.
class ResourceReaper<T> {
  /// The name identifier for the Reaper. Useful for logging and debugging
  final String name;

  /// The max amount of items the Reaper can hold before is starts disposing of older items.
  final int size;

  /// Callback invoked whenever an item is disposed.
  final void Function(T item) onDisposeItem;

  /// The duration after which an item is considered expired and eligible for purging.
  ///
  /// If null, items never expire.
  final Duration? itemDuration;

  /// The interval at which the Reaper checks and purges expired items.
  /// Defaults to [itemDuration] if not explicitly set.
  final Duration? purgeInterval;

  /// Enables detailed logging when set to `true`.
  final bool verbose;

  /// Callback invoked whenever the Reaper is empty and receives an item.
  final void Function()? onFirstItemAdded;

  /// Callback invoked whenever the Reaper's last item is removed.
  final void Function()? onLastItemRemoved;

  Timer? _timer;

  final _queue = Queue<(T, DateTime)>();

  static const _minSize = 1;

  /// Creates a new instance of [ResourceReaper].
  ResourceReaper({
    required this.name,
    required this.size,
    required this.onDisposeItem,
    this.itemDuration,
    Duration? purgeInterval,
    this.onFirstItemAdded,
    this.onLastItemRemoved,
    this.verbose = false,
  }) : purgeInterval = purgeInterval ?? itemDuration {
    if (itemDuration?.isNegative ?? false) {
      throw ArgumentError.value(itemDuration, 'itemDuration',
          'itemDuration for $name Reaper cannot be negative');
    }
    if (purgeInterval?.isNegative ?? false) {
      throw ArgumentError.value(purgeInterval, 'purgeInterval',
          'purgeInterval for $name Reaper cannot be negative');
    }
    if (size < _minSize) {
      throw ArgumentError.value(size, 'size',
          'size for $name Reaper must be greater or equal than $_minSize');
    }
  }

  /// The amount of items currently tracked by the Reaper.
  int get trackedItemCount => _queue.length;

  /// Whether any items are currently tracked by the Reaper.
  bool get isEmpty => _queue.isEmpty;

  /// Whether no items are currently tracked by the Reaper.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Adds an [item] to the Reaper for tracking.
  ///
  /// If the reaper exceed the [size] limit, the oldest [item] will be disposed of automatically through the invokation of [onDisposeItem].
  void add(T item) {
    if (_queue.isEmpty) _onFirstItemAdded();
    _queue.addLast((item, clock.now().add(itemDuration ?? Duration())));
    if (verbose) {
      reaperLog('Added $item to $name Reaper');
    }
    if (_queue.length > size) {
      if (verbose) {
        reaperLog('$name Reaper is full. Dropping oldest item.');
      }
      onDisposeItem(_queue.removeFirst().$1);
    }
  }

  /// Removes an [item] from the Reaper manually.
  ///
  /// The item is identified using the `==` operator. For custom classes,
  /// ensure that the `==` operator (and `hashCode`) are properly overridden
  /// to guarantee accurate item removal.
  ///
  /// If multiple items in the Reaper match [item], they will all be removed.
  ///
  /// If [dispose] is set to `true`, the [onDisposeItem] callback is invoked immediately on that [item].
  void remove(T item, {bool dispose = false}) {
    List<T> removedItems = [];
    _queue.removeWhere((tuple) {
      final isMatch = tuple.$1 == item;
      if (isMatch) {
        removedItems.add(tuple.$1);
      }
      return isMatch;
    });

    if (verbose) {
      if (removedItems.isEmpty) {
        reaperLog('No item match found for $item', Level.warning);
      }
      for (final item in removedItems) {
        reaperLog('Removed $item from $name Reaper', Level.debug);
      }
    }

    if (dispose) {
      onDisposeItem(item);
    }

    if (_queue.isEmpty) _onLastItemRemoved();
  }

  /// Clears all the items from the Reaper and disposes of them.
  void clear() {
    for (final provider in _queue) {
      onDisposeItem(provider.$1);
    }
    _queue.clear();
    _onLastItemRemoved();

    if (verbose) {
      reaperLog('Cleared $name Reaper.');
    }
  }

  /// Purges expired items from the reaper based on their expiration timestamps.
  ///
  /// This is triggered automatically based on [purgeInterval], but can also be called manually.
  void purge() {
    final now = clock.now();
    int i = 0;
    while (_queue.isNotEmpty) {
      if (now.isBefore(_queue.first.$2)) {
        break;
      }
      onDisposeItem(_queue.removeFirst().$1);
      i++;
    }
    if (_queue.isEmpty) _onLastItemRemoved();

    if (verbose && i > 0) {
      reaperLog('Purged $i expired items from $name Reaper.', Level.debug);
    }
  }

  /// Disposes of the reaper, cancelling any active timers.
  ///
  /// This should be called when the reaper is no longer needed to clean up resources.
  ///
  /// By default, this disposes of all remaining items, unless [disposeItems] is explicitely set to false.
  void dispose({bool disposeItems = true}) {
    _timer?.cancel();
    if (disposeItems) {
      clear();
    }
    if (verbose) {
      reaperLog('Disposing $name Reaper.');
    }
  }

  void _onLastItemRemoved() {
    onLastItemRemoved?.call();
    if (verbose && _timer != null) {
      reaperLog('Clearing Timer on $name Reaper', Level.debug);
    }
    _timer?.cancel();
  }

  void _onFirstItemAdded() {
    onFirstItemAdded?.call();
    if (purgeInterval != null) {
      _timer = Timer.periodic(purgeInterval!, (_) => purge());
      if (verbose) {
        reaperLog('Started Timer on $name Reaper', Level.debug);
      }
    }
  }
}
