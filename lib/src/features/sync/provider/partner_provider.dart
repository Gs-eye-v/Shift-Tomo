import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/partner.dart';
import 'dart:convert';

part 'partner_provider.g.dart';

@riverpod
class PartnerNotifier extends _$PartnerNotifier {
  static const _keyPartners = 'shared_partners';

  @override
  Future<List<Partner>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyPartners) ?? [];
    return list.map((e) => Partner.fromJson(e)).toList();
  }

  Future<void> addPartner(Partner partner) async {
    final current = state.value ?? [];
    // 同一IDがあれば上書き、なければ追加
    final next = [...current.where((p) => p.id != partner.id), partner];
    state = AsyncValue.data(next);
    await _save(next);
  }

  Future<void> removePartner(String id) async {
    final current = state.value ?? [];
    final next = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(next);
    await _save(next);
  }

  Future<void> renamePartner(String id, String newName) async {
    final current = state.value ?? [];
    final next = current.map((p) {
      if (p.id == id) {
        // Partnerモデルの再生成 (displayNameのみ変更)
        return Partner(
          id: p.id,
          displayName: newName,
          roomId: p.roomId,
          password: p.password,
          profileName: p.profileName,
          isReadOnly: p.isReadOnly,
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(next);
    await _save(next);
  }

  Future<void> _save(List<Partner> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_keyPartners, jsonList);
  }
}
