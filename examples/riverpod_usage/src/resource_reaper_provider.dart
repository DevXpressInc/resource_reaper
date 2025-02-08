import 'package:resource_reaper/resource_reaper.dart';
import 'package:riverpod/riverpod.dart';
import 'provider_reaper.dart';

/// Provides ResourceReaper to automatically dispose of providers when too many exist.
///
/// Can also manage disposal by time-based sweeps.
final resourceReaperProvider = Provider.family((ref, ProviderReaper reaper) {
  final resourceReaper = ResourceReaper<KeepAliveLink>(
    name: reaper.name,
    size: reaper.size,
    itemDuration: reaper.duration,
    purgeInterval: reaper.purgeInterval,
    onDisposeItem: (link) => link.close(),
    verbose: true,
  );

  ref.onDispose(resourceReaper.dispose);

  print('Built ${reaper.name} Reaper with size ${reaper.size}');

  return resourceReaper;
});

/// Allows for easily listening to an AutoDispose ref to keep it alive for longer.
extension AutoDisposeRefExtensions on Ref {
  /// Registers provider for managed disposal with the provided [reaper].
  void listenWithReaper([ProviderReaper reaper = ProviderReaper.global]) {
    final resourceReaper = watch(resourceReaperProvider(reaper));
    final link = keepAlive();

    onCancel(() => resourceReaper.add(link));
    onResume(() => resourceReaper.remove(link));
  }
}
