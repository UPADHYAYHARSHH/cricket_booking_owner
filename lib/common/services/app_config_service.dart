import 'package:firebase_remote_config/firebase_remote_config.dart';

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
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      await remoteConfig.setDefaults({
        'platform_fee': 25.0,
        'commission_rate': 0.0,
        'commission_is_percentage': true,
        'owner_app_maintenance': false,
        'owner_android_min_version': '',
        'owner_ios_min_version': '',
        'owner_android_store_url': '',
        'owner_ios_store_url': '',
      });

      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();

      _platformFee = remoteConfig.getDouble('platform_fee');
      _commissionRate = remoteConfig.getDouble('commission_rate');
      _commissionIsPercentage = remoteConfig.getBool('commission_is_percentage');
      _ownerAppMaintenance = remoteConfig.getBool('is_owner_under_maintenance');
      _androidMinVersion = remoteConfig.getString('owner_android_min_version');
      _iosMinVersion = remoteConfig.getString('owner_ios_min_version');
      _androidStoreUrl = remoteConfig.getString('owner_android_store_url');
      _iosStoreUrl = remoteConfig.getString('owner_ios_store_url');
      
    } catch (_) {
      // Keep defaults — app remains functional offline.
    }
  }
}
