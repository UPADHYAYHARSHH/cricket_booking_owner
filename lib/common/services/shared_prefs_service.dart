import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  SharedPrefsService._();
  static final SharedPrefsService instance = SharedPrefsService._();

  late SharedPreferences _prefs;

  static const String _kSelectedLocationId = 'selected_location_id';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get selectedLocationId {
    return _prefs.getString(_kSelectedLocationId);
  }

  Future<void> setSelectedLocationId(String locationId) async {
    await _prefs.setString(_kSelectedLocationId, locationId);
  }
}
