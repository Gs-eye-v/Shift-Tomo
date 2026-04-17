// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$focusedMonthHash() => r'a47d7db6611c026d43d37b5361a33bd044d8b275';

/// See also [FocusedMonth].
@ProviderFor(FocusedMonth)
final focusedMonthProvider =
    AutoDisposeNotifierProvider<FocusedMonth, DateTime>.internal(
  FocusedMonth.new,
  name: r'focusedMonthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$focusedMonthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FocusedMonth = AutoDisposeNotifier<DateTime>;
String _$calendarNotifierHash() => r'c98cf897c327e21d8e6c7bac1005bb26560965b0';

/// See also [CalendarNotifier].
@ProviderFor(CalendarNotifier)
final calendarNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CalendarNotifier, Map<DateTime, List<Shift>>>.internal(
  CalendarNotifier.new,
  name: r'calendarNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CalendarNotifier
    = AutoDisposeAsyncNotifier<Map<DateTime, List<Shift>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
