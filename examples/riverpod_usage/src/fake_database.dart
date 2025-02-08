import 'package:riverpod/riverpod.dart';

import 'provider_reaper.dart';
import 'resource_reaper_provider.dart';

class FakeDatabase {
  const FakeDatabase({required Map<String, String> users}) : _users = users;

  final Map<String, String> _users;

  Future<String?> getUser(String id) => Future.value(_users[id]);
}

final dbProvider = Provider((ref) => FakeDatabase(users: {
      '123': 'Remi Rousselet',
      '456': 'Randal Schwartz',
      '789': 'David Morgan',
    }));

// Normally disposed whenever it loses it's last listener.
final userProvider =
    FutureProvider.family.autoDispose((ref, String userId) async {
  final db = ref.watch(dbProvider);

  // Instead, we set up managed disposal with users Reaper.
  ref.listenWithReaper(ProviderReaper.users);

  final user = await db.getUser(userId);
  if (user == null) {
    throw Exception('User "$userId" not found');
  }
  return user;
});
