import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';


class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  double _platformFee = 0.0;
  bool _isPlatformFeeFree = false;
  double _gstRate = 0.0;
  bool _isGstEnabled = false;
  double _commissionRate = 0.0;
  bool _commissionIsPercentage = true;
  bool _ownerAppMaintenance = false;
  String _androidMinVersion = '';
  String _iosMinVersion = '';
  String _androidStoreUrl = '';
  String _iosStoreUrl = '';

  final StreamController<bool> _maintenanceController = StreamController<bool>.broadcast();
  StreamSubscription? _remoteConfigSubscription;

  double get platformFee => _platformFee;
  bool get isPlatformFeeFree => _isPlatformFeeFree;
  double get gstRate => _gstRate;
  bool get isGstEnabled => _isGstEnabled;
  double get commissionRate => _commissionRate;
  bool get commissionIsPercentage => _commissionIsPercentage;
  bool get ownerAppMaintenance => _ownerAppMaintenance;
  String get androidMinVersion => _androidMinVersion;
  String get iosMinVersion => _iosMinVersion;
  String get androidStoreUrl => _androidStoreUrl;
  String get iosStoreUrl => _iosStoreUrl;

  Stream<bool> get maintenanceModeStream => _maintenanceController.stream;

  Future<void> load() async {
    try {
      debugPrint('🚀 OWNER CONFIG INIT STARTED (Firebase & Supabase)');
      
      // 1. Try Firebase Remote Config
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ));
        await remoteConfig.fetchAndActivate();
        _readFromFirebase(remoteConfig);

        _remoteConfigSubscription = remoteConfig.onConfigUpdated.listen((event) async {
          debugPrint('🚀 FIREBASE REMOTE CONFIG UPDATED (Owner App)');
          await remoteConfig.activate();
          _readFromFirebase(remoteConfig);
          _maintenanceController.add(_ownerAppMaintenance);
        });
      } catch (e) {
        debugPrint('⚠️ FIREBASE REMOTE CONFIG OWNER INIT NOTICE: $e');
      }

      await _fetchValues();
      _maintenanceController.add(_ownerAppMaintenance);

      Supabase.instance.client
          .channel('public:app_config')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (payload) async {
              debugPrint('🚀 CONFIG UPDATED: ${payload.newRecord}');
              await _fetchValues();
              _maintenanceController.add(_ownerAppMaintenance);
            },
          )
          .subscribe((status, [error]) {
            debugPrint('🚀 REALTIME STATUS: $status');
            if (error != null) {
              debugPrint('❌ REALTIME ERROR: $error');
            }
          });
    } catch (e, stack) {
      debugPrint('❌ OWNER CONFIG INITIALIZATION FAILED: $e');
      debugPrint(stack.toString());
    }
  }

  void _readFromFirebase(FirebaseRemoteConfig remoteConfig) {
    try {
      final pfStr = remoteConfig.getString('platform_fee');
      if (pfStr.isNotEmpty) {
        final parsed = double.tryParse(pfStr);
        if (parsed != null) _platformFee = parsed;
      }

      final pfFreeStr = remoteConfig.getString('platform_fee_is_free');
      if (pfFreeStr.isNotEmpty) {
        _isPlatformFeeFree = pfFreeStr.toLowerCase() == 'true' || pfFreeStr == '1';
      } else {
        final convFreeStr = remoteConfig.getString('convenience_fee_is_free');
        if (convFreeStr.isNotEmpty) {
          _isPlatformFeeFree = convFreeStr.toLowerCase() == 'true' || convFreeStr == '1';
        }
      }

      final gstStr = remoteConfig.getString('gst_rate');
      if (gstStr.isNotEmpty) {
        final parsed = double.tryParse(gstStr);
        if (parsed != null) _gstRate = parsed;
      }

      final gstEnabledStr = remoteConfig.getString('is_gst_enabled');
      if (gstEnabledStr.isNotEmpty) {
        _isGstEnabled = gstEnabledStr.toLowerCase() == 'true' || gstEnabledStr == '1';
      }

      final commStr = remoteConfig.getString('commission_rate');
      if (commStr.isNotEmpty) {
        final parsed = double.tryParse(commStr);
        if (parsed != null) _commissionRate = parsed;
      }

      final commPercStr = remoteConfig.getString('commission_is_percentage');
      if (commPercStr.isNotEmpty) {
        _commissionIsPercentage = commPercStr.toLowerCase() == 'true' || commPercStr == '1';
      }

      final maintStr = remoteConfig.getString('owner_app_maintenance');
      if (maintStr.isNotEmpty) {
        _ownerAppMaintenance = maintStr.toLowerCase() == 'true' || maintStr == '1';
      }

      final androidVer = remoteConfig.getString('owner_android_min_version');
      if (androidVer.isNotEmpty) _androidMinVersion = androidVer;

      final iosVer = remoteConfig.getString('owner_ios_min_version');
      if (iosVer.isNotEmpty) _iosMinVersion = iosVer;

      final androidUrl = remoteConfig.getString('owner_android_store_url');
      if (androidUrl.isNotEmpty) _androidStoreUrl = androidUrl;

      final iosUrl = remoteConfig.getString('owner_ios_store_url');
      if (iosUrl.isNotEmpty) _iosStoreUrl = iosUrl;

      debugPrint('🔥 OWNER CONFIG LOADED FROM FIREBASE: platformFee=$_platformFee, isFree=$_isPlatformFeeFree, commission=$_commissionRate ($_commissionIsPercentage%), gst=$_gstRate');
    } catch (e) {
      debugPrint('⚠️ Error reading Firebase Remote Config values: $e');
    }
  }

  Future<void> _fetchValues() async {
    try {
      final rows = await Supabase.instance.client.from('app_config').select('key, value');
      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
            final parsedFee = double.tryParse(val);
            if (parsedFee != null) _platformFee = parsedFee;
            break;
          case 'platform_fee_is_free':
          case 'convenience_fee_is_free':
          case 'is_platform_fee_free':
            _isPlatformFeeFree = val == 'true' || val == '1';
            break;
          case 'gst_rate':
            final parsedGst = double.tryParse(val);
            if (parsedGst != null) _gstRate = parsedGst;
            break;
          case 'is_gst_enabled':
            _isGstEnabled = val == 'true' || val == '1';
            break;
          case 'commission_rate':
            final parsedComm = double.tryParse(val);
            if (parsedComm != null) _commissionRate = parsedComm;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'owner_app_maintenance':
            _ownerAppMaintenance = val == 'true' || val == '1';
            break;
          case 'owner_android_min_version':
            if (val.isNotEmpty) _androidMinVersion = val;
            break;
          case 'owner_ios_min_version':
            if (val.isNotEmpty) _iosMinVersion = val;
            break;
          case 'owner_android_store_url':
            if (val.isNotEmpty) _androidStoreUrl = val;
            break;
          case 'owner_ios_store_url':
            if (val.isNotEmpty) _iosStoreUrl = val;
        }
      }
      debugPrint('🚀 FETCH OWNER CONFIG SUCCESS: platformFee=$_platformFee, isFree=$_isPlatformFeeFree, gstRate=$_gstRate');
    } catch (e) {
      debugPrint('❌ FETCH OWNER CONFIG FAILED: $e');
    }
  }

  Future<void> refresh() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();
      _readFromFirebase(remoteConfig);
      _maintenanceController.add(_ownerAppMaintenance);
    } catch (e) {
      debugPrint('ℹ️ Remote Config refresh error in owner app: $e');
    }
    await _fetchValues();
  }

  void dispose() {
    _remoteConfigSubscription?.cancel();
    _maintenanceController.close();
  }
}
