// lib/utils/filter_options.dart

enum FilterOption { favorites, dueToday, unlearned }

extension FilterOptionLabel on FilterOption {
  String get label {
    switch (this) {
      case FilterOption.favorites:
        return 'お気に入りのみ';
      case FilterOption.dueToday:
        return '復習対象のみ';
      case FilterOption.unlearned:
        return '未学習のみ';
    }
  }
}
