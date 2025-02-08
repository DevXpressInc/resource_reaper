import 'package:riverpod/riverpod.dart';

import 'fake_database.dart';

void userListener<T>(AsyncValue<T>? prev, AsyncValue<T> curr) {
  switch (curr) {
    case AsyncData(:final value):
      print('User $value loaded');
      break;
    case AsyncLoading():
      print('User loading');
      break;
    case AsyncError(:final error):
      print('User error: $error');
      break;
  }
}

main() async {
  final container = ProviderContainer();

  final firstUserProviderSubscription =
      container.listen(userProvider('123'), userListener);
  await container.read(userProvider('123').future);
  firstUserProviderSubscription.close();
  await Future(() {});

  // User is kept alive even after the listener is closed.
  print(container.read(userProvider('123')));

  final secondUserProviderSubscription =
      container.listen(userProvider('456'), userListener);
  await container.read(userProvider('456').future);
  secondUserProviderSubscription.close();
  await Future(() {});

  /// Second user is now cached
  print(container.read(userProvider('456')));

  /// First user is now loading, because it was disposed of.
  print(container.read(userProvider('123')));
}
