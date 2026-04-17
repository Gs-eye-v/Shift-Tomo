// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commonHolidaysHash() => r'03b128a34da6878c7aea152aaf4a334ce0ce3920';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
///
/// Copied from [commonHolidays].
@ProviderFor(commonHolidays)
const commonHolidaysProvider = CommonHolidaysFamily();

/// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
///
/// Copied from [commonHolidays].
class CommonHolidaysFamily extends Family<AsyncValue<List<DateTime>>> {
  /// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
  ///
  /// Copied from [commonHolidays].
  const CommonHolidaysFamily();

  /// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
  ///
  /// Copied from [commonHolidays].
  CommonHolidaysProvider call(
    DateTime month,
  ) {
    return CommonHolidaysProvider(
      month,
    );
  }

  @override
  CommonHolidaysProvider getProviderOverride(
    covariant CommonHolidaysProvider provider,
  ) {
    return call(
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commonHolidaysProvider';
}

/// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
///
/// Copied from [commonHolidays].
class CommonHolidaysProvider extends AutoDisposeFutureProvider<List<DateTime>> {
  /// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
  ///
  /// Copied from [commonHolidays].
  CommonHolidaysProvider(
    DateTime month,
  ) : this._internal(
          (ref) => commonHolidays(
            ref as CommonHolidaysRef,
            month,
          ),
          from: commonHolidaysProvider,
          name: r'commonHolidaysProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commonHolidaysHash,
          dependencies: CommonHolidaysFamily._dependencies,
          allTransitiveDependencies:
              CommonHolidaysFamily._allTransitiveDependencies,
          month: month,
        );

  CommonHolidaysProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<List<DateTime>> Function(CommonHolidaysRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommonHolidaysProvider._internal(
        (ref) => create(ref as CommonHolidaysRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DateTime>> createElement() {
    return _CommonHolidaysProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommonHolidaysProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommonHolidaysRef on AutoDisposeFutureProviderRef<List<DateTime>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _CommonHolidaysProviderElement
    extends AutoDisposeFutureProviderElement<List<DateTime>>
    with CommonHolidaysRef {
  _CommonHolidaysProviderElement(super.provider);

  @override
  DateTime get month => (origin as CommonHolidaysProvider).month;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
