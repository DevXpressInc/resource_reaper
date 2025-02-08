/// Finite reaper configurations to avoid dynamically creating too many [resourceReaperProvider]s and causing memory leaks.
///
/// The enhanced enum allows carrying metadata around the constant value of the enum.
enum ProviderReaper {
  global(
      size: 50,
      duration: Duration(minutes: 15),
      purgeInterval: Duration(minutes: 3)),
  users(size: 1);

  static const _minSize = 1;

  static const _maxSize = 500;

  const ProviderReaper(
      {required this.size, this.duration, Duration? purgeInterval})
      : purgeInterval = purgeInterval ?? duration,
        assert(_minSize <= size && size <= _maxSize,
            'Reaper size must be in range [$_minSize, $_maxSize]');

  /// The size of the Reaper.
  ///
  /// When the size limit is reached, older providers are disposed.
  final int size;

  /// Duration of provider before it expires.
  ///
  /// If null, the provider will never expire.
  final Duration? duration;

  /// How often the expired providers are purged from the list.
  ///
  /// Defaults to [duration] if unset.
  final Duration? purgeInterval;
}
