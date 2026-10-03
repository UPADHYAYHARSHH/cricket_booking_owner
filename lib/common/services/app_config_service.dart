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

  // Cancellation Policy & Coin Recovery (Loaded dynamically from app_config)
  double _cancellationTier1Hours = 24.0;
  double _cancellationTier1Percent = 100.0;
  double _cancellationTier2Hours = 12.0;
  double _cancellationTier2Percent = 75.0;
  double _cancellationTier3Hours = 3.0;
  double _cancellationTier3Percent = 50.0;
  double _cancellationTier4Percent = 25.0;
  int _coinExpiryDays = 60;
  double _maxCoinRedemptionPercent = 40.0;

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

  // Cancellation Getters
  double get cancellationTier1Hours => _cancellationTier1Hours;
  double get cancellationTier1Percent => _cancellationTier1Percent;
  double get cancellationTier2Hours => _cancellationTier2Hours;
  double get cancellationTier2Percent => _cancellationTier2Percent;
  double get cancellationTier3Hours => _cancellationTier3Hours;
  double get cancellationTier3Percent => _cancellationTier3Percent;
  double get cancellationTier4Percent => _cancellationTier4Percent;
  int get coinExpiryDays => _coinExpiryDays;
  double get maxCoinRedemptionPercent => _maxCoinRedemptionPercent;

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

      // Cancellation & Coin Recovery
      final t1h = double.tryParse(remoteConfig.getString('cancellation_tier1_hours'));
      if (t1h != null) _cancellationTier1Hours = t1h;
      final t1p = double.tryParse(remoteConfig.getString('cancellation_tier1_percent'));
      if (t1p != null) _cancellationTier1Percent = t1p;

      final t2h = double.tryParse(remoteConfig.getString('cancellation_tier2_hours'));
      if (t2h != null) _cancellationTier2Hours = t2h;
      final t2p = double.tryParse(remoteConfig.getString('cancellation_tier2_percent'));
      if (t2p != null) _cancellationTier2Percent = t2p;

      final t3h = double.tryParse(remoteConfig.getString('cancellation_tier3_hours'));
      if (t3h != null) _cancellationTier3Hours = t3h;
      final t3p = double.tryParse(remoteConfig.getString('cancellation_tier3_percent'));
      if (t3p != null) _cancellationTier3Percent = t3p;

      final t4p = double.tryParse(remoteConfig.getString('cancellation_tier4_percent'));
      if (t4p != null) _cancellationTier4Percent = t4p;

      final exp = int.tryParse(remoteConfig.getString('coin_expiry_days'));
      if (exp != null) _coinExpiryDays = exp;

      final maxRedeem = double.tryParse(remoteConfig.getString('max_coin_redemption_percent'));
      if (maxRedeem != null) _maxCoinRedemptionPercent = maxRedeem;

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
            break;
          case 'cancellation_tier1_hours':
            final t1h = double.tryParse(val);
            if (t1h != null) _cancellationTier1Hours = t1h;
            break;
          case 'cancellation_tier1_percent':
            final t1p = double.tryParse(val);
            if (t1p != null) _cancellationTier1Percent = t1p;
            break;
          case 'cancellation_tier2_hours':
            final t2h = double.tryParse(val);
            if (t2h != null) _cancellationTier2Hours = t2h;
            break;
          case 'cancellation_tier2_percent':
            final t2p = double.tryParse(val);
            if (t2p != null) _cancellationTier2Percent = t2p;
            break;
          case 'cancellation_tier3_hours':
            final t3h = double.tryParse(val);
            if (t3h != null) _cancellationTier3Hours = t3h;
            break;
          case 'cancellation_tier3_percent':
            final t3p = double.tryParse(val);
            if (t3p != null) _cancellationTier3Percent = t3p;
            break;
          case 'cancellation_tier4_percent':
            final t4p = double.tryParse(val);
            if (t4p != null) _cancellationTier4Percent = t4p;
            break;
          case 'coin_expiry_days':
            final exp = int.tryParse(val);
            if (exp != null) _coinExpiryDays = exp;
            break;
          case 'max_coin_redemption_percent':
            final mr = double.tryParse(val);
            if (mr != null) _maxCoinRedemptionPercent = mr;
            break;
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
