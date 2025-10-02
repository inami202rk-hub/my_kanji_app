import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_kanji_app/features/settings/data/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default is true when not set', () async {
    final repo = SettingsRepository();
    final enabled = await repo.getSrsPreviewEnabled();
    expect(enabled, isTrue);
  });

  test('set and get persists value', () async {
    final repo = SettingsRepository();
    await repo.setSrsPreviewEnabled(false);
    final enabled = await repo.getSrsPreviewEnabled();
    expect(enabled, isFalse);
  });
}
