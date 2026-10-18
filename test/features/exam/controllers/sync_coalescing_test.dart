import 'package:flutter_test/flutter_test.dart';

/// Test mock demonstrating coalescing and cooldown behavior implemented in SyncingController.
class MockSyncEngine {
  Future<bool>? inFlightSync;
  DateTime? lastSyncCompletedAt;
  static const Duration syncCooldown = Duration(seconds: 30);
  int actualNetworkRuns = 0;

  Future<bool> syncAll({bool force = false, Duration simulatedDelay = const Duration(milliseconds: 50)}) async {
    // 1. Coalesce in-flight syncs
    if (inFlightSync != null) {
      return inFlightSync!;
    }

    // 2. Cooldown check
    if (!force && lastSyncCompletedAt != null) {
      final elapsed = DateTime.now().difference(lastSyncCompletedAt!);
      if (elapsed < syncCooldown) {
        return true; // Fast path from local cache
      }
    }

    final future = _performSync(simulatedDelay);
    inFlightSync = future;
    try {
      final success = await future;
      if (success) {
        lastSyncCompletedAt = DateTime.now();
      }
      return success;
    } finally {
      inFlightSync = null;
    }
  }

  Future<bool> _performSync(Duration delay) async {
    await Future.delayed(delay);
    actualNetworkRuns++;
    return true;
  }
}

void main() {
  group('Sync Coalescing & Cooldown Tests', () {
    test('coalesces multiple simultaneous sync calls into a single network run', () async {
      final engine = MockSyncEngine();

      // Trigger 3 calls in parallel while the first is in-flight
      final futures = await Future.wait([
        engine.syncAll(),
        engine.syncAll(),
        engine.syncAll(),
      ]);

      expect(futures, equals([true, true, true]));
      // Only 1 network operation should have actually run
      expect(engine.actualNetworkRuns, equals(1));
    });

    test('cooldown prevents redundant network calls during rapid pull-to-refresh', () async {
      final engine = MockSyncEngine();

      // First sync runs
      final first = await engine.syncAll();
      expect(first, isTrue);
      expect(engine.actualNetworkRuns, equals(1));

      // Second sync immediately after (pull-to-refresh) within 30s window
      final second = await engine.syncAll(force: false);
      expect(second, isTrue);
      // Network call counter remains 1 because cooldown served it from local
      expect(engine.actualNetworkRuns, equals(1));
    });

    test('forced sync bypasses cooldown for manual button presses', () async {
      final engine = MockSyncEngine();

      // First sync
      await engine.syncAll();
      expect(engine.actualNetworkRuns, equals(1));

      // Immediate forced sync (e.g. AppBar sync icon tap)
      await engine.syncAll(force: true);
      expect(engine.actualNetworkRuns, equals(2));
    });
  });
}
