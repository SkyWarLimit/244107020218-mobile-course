import 'package:shared_preferences/shared_preferences.dart';

/// Repository untuk menyimpan preferensi pengguna menggunakan SharedPreferences.
/// SharedPreferences dipilih karena data yang disimpan hanya berupa
/// tipe primitif sederhana (bool), sehingga tidak perlu database relasional.
class PrefsRepository {
  static const _darkModeKey = 'dark_mode';

  /// Ambil status dark mode (default: false = Light Mode)
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  /// Simpan status dark mode
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}
