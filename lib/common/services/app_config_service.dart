import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches and caches app-wide configuration from the `app_config` Supabase
/// table. Call [load] once at startup after Supabase is initialized.
///
/// To update a value without redeploying: edit the relevant row in the
/// `app_config` table from the admin dashboard — the change takes effect on
/// the next app cold-start.
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  // ── Cached values with safe defaults ──────────────────────────────────────
  double _platformFee = 25.0;
  double _commissionRate = 0.0;
  bool _commissionIsPercentage = true;
  bool _ownerAppMaintenance = false;
  String _androidMinVersion = '';
  String _iosMinVersion = '';
  String _androidStoreUrl = '';
  String _iosStoreUrl = '';

  /// Platform fee (₹) deducted from each booking before the owner is paid.
  double get platformFee => _platformFee;

  /// Commission value — interpreted as a percentage when [commissionIsPercentage]
  /// is true, or as a flat ₹ amount otherwise.
  double get commissionRate => _commissionRate;

  /// Whether [commissionRate] is a percentage (true) or a flat ₹ amount (false).
  bool get commissionIsPercentage => _commissionIsPercentage;

  /// Whether the owner app is currently under maintenance.
  bool get ownerAppMaintenance => _ownerAppMaintenance;

  /// Minimum Android build version required. Empty = no forced update.
  String get androidMinVersion => _androidMinVersion;

  /// Minimum iOS build version required. Empty = no forced update.
  String get iosMinVersion => _iosMinVersion;

  /// Play Store URL to redirect Android users for forced update.
  String get androidStoreUrl => _androidStoreUrl;

  /// App Store URL to redirect iOS users for forced update.
  String get iosStoreUrl => _iosStoreUrl;

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Fetches all rows from `app_config` and caches known keys.
  /// Silently keeps defaults on any error so the app works offline.
  Future<void> load() async {
    try {
      final rows = await Supabase.instance.client.from('app_config').select('key, value');
      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
            _platformFee = double.tryParse(val) ?? 25.0;
            break;
          case 'commission_rate':
            _commissionRate = double.tryParse(val) ?? 0.0;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'owner_app_maintenance':
            _ownerAppMaintenance = val == 'true' || val == '1';
            break;
          case 'android_min_version':
            _androidMinVersion = val;
            break;
          case 'ios_min_version':
            _iosMinVersion = val;
            break;
          case 'android_store_url':
            _androidStoreUrl = val;
            break;
          case 'ios_store_url':
            _iosStoreUrl = val;
            break;
        }
      }
    } catch (_) {
      // Keep defaults — app remains functional offline.
    }
  }
}
