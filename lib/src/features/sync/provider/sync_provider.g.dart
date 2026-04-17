// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncRepositoryHash() => r'0e713c3b3f10f4e1a434c47386f4b3b7b2a917a0';

/// See also [syncRepository].
@ProviderFor(syncRepository)
final syncRepositoryProvider = AutoDisposeProvider<SyncRepository>.internal(
  syncRepository,
  name: r'syncRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncRepositoryRef = AutoDisposeProviderRef<SyncRepository>;
String _$isSyncRequiredHash() => r'415fedfc958285c4100658ac6ab3e01d092b2118';

/// 同期が必要かどうかをデータ差分で自動判定するプロバイダー
///
/// Copied from [isSyncRequired].
@ProviderFor(isSyncRequired)
final isSyncRequiredProvider = Provider<bool>.internal(
  isSyncRequired,
  name: r'isSyncRequiredProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSyncRequiredHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSyncRequiredRef = ProviderRef<bool>;
String _$syncSnapshotHash() => r'54626568e5c3f3ecb86950cb500790f5edea3c2e';

/// 最後に同期（または起動時に読み込み）に成功したデータのスナップショットを保持
///
/// Copied from [SyncSnapshot].
@ProviderFor(SyncSnapshot)
final syncSnapshotProvider = NotifierProvider<SyncSnapshot, String?>.internal(
  SyncSnapshot.new,
  name: r'syncSnapshotProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncSnapshotHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncSnapshot = Notifier<String?>;
String _$syncNotifierHash() => r'fcdae6eae06abd2413f42dff32dfe5f9b2037912';

/// See also [SyncNotifier].
@ProviderFor(SyncNotifier)
final syncNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SyncNotifier, void>.internal(
  SyncNotifier.new,
  name: r'syncNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
