import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';


class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  double _platformFee = 25.0;
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
      final keys = remoteConfig.getAll();
      if (keys.containsKey('platform_fee')) {
        _platformFee = remoteConfig.getDouble('platform_fee');
        if (_platformFee == 0) {
          _platformFee = double.tryParse(remoteConfig.getString('platform_fee')) ?? 25.0;
        }
      }
      if (keys.containsKey('commission_rate')) {
        _commissionRate = remoteConfig.getDouble('commission_rate');
        if (_commissionRate == 0) {
          _commissionRate = double.tryParse(remoteConfig.getString('commission_rate')) ?? 0.0;
        }
      }
      if (keys.containsKey('commission_is_percentage')) {
        _commissionIsPercentage = remoteConfig.getBool('commission_is_percentage') ||
            remoteConfig.getString('commission_is_percentage') == 'true';
      }
      if (keys.containsKey('owner_app_maintenance')) {
        _ownerAppMaintenance = remoteConfig.getBool('owner_app_maintenance') ||
            remoteConfig.getString('owner_app_maintenance') == 'true';
      }
      if (keys.containsKey('owner_android_min_version')) {
        _androidMinVersion = remoteConfig.getString('owner_android_min_version');
      }
      if (keys.containsKey('owner_ios_min_version')) {
        _iosMinVersion = remoteConfig.getString('owner_ios_min_version');
      }
      if (keys.containsKey('owner_android_store_url')) {
        _androidStoreUrl = remoteConfig.getString('owner_android_store_url');
      }
      if (keys.containsKey('owner_ios_store_url')) {
        _iosStoreUrl = remoteConfig.getString('owner_ios_store_url');
      }
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
      debugPrint('🚀 FETCH OWNER CONFIG SUCCESS: platformFee=$_platformFee');
    } catch (e) {
      debugPrint('❌ FETCH OWNER CONFIG FAILED: $e');
    }
  }

  void dispose() {
    _remoteConfigSubscription?.cancel();
    _maintenanceController.close();
  }
}
