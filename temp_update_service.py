from pathlib import Path
path = Path('lib/services/srs_service.dart')
text = path.read_text()
old_prefix = "class SrsService {\r\n  static const _storageKey = 'srs.v2';\r\n\r\n  static PickDueFn? _pickDueOverride;\r\n  static SrsConfigStore _configStore = SharedPrefsSrsConfigStore();\r\n\r\n  @visibleForTesting\r\n  static void setPickDueOverride(PickDueFn? override) {\r\n    _pickDueOverride = override;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void resetPickDueOverride() {\r\n    _pickDueOverride = null;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void setConfigStoreForTesting(SrsConfigStore store) {\r\n    _configStore = store;\r\n  }\r\n"
if old_prefix not in text:
    raise SystemExit('prefix not found')
new_prefix = "class SrsService {\r\n  static const _storageKey = 'srs.v2';\r\n\r\n  static PickDueFn? _pickDueOverride;\r\n  static SrsSimulateFn? _simulateOverride;\r\n  static SrsConfigStore _configStore = SharedPrefsSrsConfigStore();\r\n\r\n  @visibleForTesting\r\n  static void setPickDueOverride(PickDueFn? override) {\r\n    _pickDueOverride = override;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void setSimulateOverride(SrsSimulateFn? override) {\r\n    _simulateOverride = override;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void resetPickDueOverride() {\r\n    _pickDueOverride = null;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void resetSimulateOverride() {\r\n    _simulateOverride = null;\r\n  }\r\n\r\n  @visibleForTesting\r\n  static void setConfigStoreForTesting(SrsConfigStore store) {\r\n    _configStore = store;\r\n  }\r\n"
text = text.replace(old_prefix, new_prefix, 1)
path.write_text(text)
