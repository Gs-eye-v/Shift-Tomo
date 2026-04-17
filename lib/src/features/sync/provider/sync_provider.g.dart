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
String _$syncNotifierHash() => r'e11a968725fac12ed4f33a76daba0308f6414367';

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
