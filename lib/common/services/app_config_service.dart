import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

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
      debugPrint('?? OWNER CONFIG INIT STARTED (Supabase)');
      
      await _fetchValues();
      _maintenanceController.add(_ownerAppMaintenance);

      if (!kIsWeb) {
        Supabase.instance.client
            .channel('public:app_config')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'app_config',
              callback: (payload) async {
                debugPrint('?? CONFIG UPDATED: ${payload.newRecord}');
                await _fetchValues();
                _maintenanceController.add(_ownerAppMaintenance);
              },
            )
            .subscribe();
      }
    } catch (e, stack) {
      debugPrint('? OWNER CONFIG INITIALIZATION FAILED: $e');
      debugPrint(stack.toString());
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
            _platformFee = double.tryParse(val) ?? 25.0;
            break;
          case 'commission_rate':
            _commissionRate = double.tryParse(val) ?? 0.0;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'is_owner_under_maintenance':
            _ownerAppMaintenance = val == 'true' || val == '1';
            break;
          case 'owner_android_min_version':
            _androidMinVersion = val;
            break;
          case 'owner_ios_min_version':
            _iosMinVersion = val;
            break;
          case 'owner_android_store_url':
            _androidStoreUrl = val;
            break;
          case 'owner_ios_store_url':
            _iosStoreUrl = val;
            break;
        }
      }
      debugPrint('?? FETCH OWNER CONFIG SUCCESS');
    } catch (e) {
      debugPrint('? FETCH OWNER CONFIG FAILED: $e');
    }
  }
}
