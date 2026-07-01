import 'package:turfpro_owner/common/services/app_config_service.dart';

/// Flat platform fee (₹) deducted from each booking before the owner is paid.
/// Loaded from `app_config.platform_fee`. Falls back to ₹25.
double get kPlatformFee => AppConfigService.instance.platformFee;

/// Commission value loaded from `app_config.commission_rate`. Falls back to 0.
/// Interpret using [kCommissionIsPercentage]:
///   true  → percentage of gross booking amount (e.g. 10 = 10%)
///   false → flat ₹ amount deducted per booking (e.g. 50 = ₹50)
double get kCommissionRate => AppConfigService.instance.commissionRate;

/// Whether [kCommissionRate] is a percentage (true) or a flat ₹ amount (false).
/// Loaded from `app_config.commission_is_percentage`. Falls back to true.
bool get kCommissionIsPercentage => AppConfigService.instance.commissionIsPercentage;
