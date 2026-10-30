import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Citește și scrie setările aplicației într-un fișier JSON pe dispozitiv
/// (echivalentul lui `moon_settings.json` din versiunea Python).
///
/// Notă: folosește `dart:io` (fișiere), deci merge pe mobil/desktop. Pe web ar
/// trebui înlocuit cu shared_preferences — dar țintim Android.
class SettingsRepository {
  static const _fileName = 'moon_settings.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Încarcă setările. Întoarce un map gol dacă fișierul nu există sau e corupt.
  Future<Map<String, dynamic>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final txt = await f.readAsString();
      final data = jsonDecode(txt);
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  /// Salvează setările (suprascrie fișierul). Eșecul e ignorat în liniște.
  Future<void> save(Map<String, dynamic> data) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}
