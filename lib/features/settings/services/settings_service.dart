import 'package:flutter/foundation.dart';
import '../data/settings_repository.dart';

class SettingsService {
  SettingsService._(this._repo);
  static final SettingsService instance = SettingsService._(
    SettingsRepository(),
  );

  final SettingsRepository _repo;

  // UI から listen できるようにする
  final ValueNotifier<bool> srsPreviewEnabled = ValueNotifier<bool>(true);

  Future<void> load() async {
    srsPreviewEnabled.value = await _repo.getSrsPreviewEnabled();
  }

  Future<void> setSrsPreviewEnabled(bool value) async {
    srsPreviewEnabled.value = value;
    await _repo.setSrsPreviewEnabled(value);
  }
}
