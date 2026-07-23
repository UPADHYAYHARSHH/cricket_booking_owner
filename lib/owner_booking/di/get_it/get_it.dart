import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/auth_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/booking_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/ground_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/location_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/owner_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/slot_repository_impl.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/auth_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/sport_repository.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/notification_repository.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/notification/notification_cubit.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  final supabase = Supabase.instance.client;
  final firebaseAuth = FirebaseAuth.instance;

  // External
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);
  getIt.registerLazySingleton<FirebaseAuth>(() => firebaseAuth);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<FirebaseAuth>()),
  );
  getIt.registerLazySingleton<OwnerRepository>(
    () => OwnerRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<GroundRepository>(
    () => GroundRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<SlotRepository>(
    () => SlotRepositoryImpl(getIt<SupabaseClient>()),
  );

  // Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>(), getIt<OwnerRepository>(), getIt<LocationRepository>()),
  );
  getIt.registerFactory<BookingsCubit>(
    () => BookingsCubit(getIt<BookingRepository>()),
  );
  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(
      getIt<OwnerRepository>(),
      getIt<BookingRepository>(),
      getIt<LocationRepository>(),
    ),
  );
  getIt.registerLazySingleton<GroundCubit>(
    () => GroundCubit(getIt<GroundRepository>()),
  );
  getIt.registerLazySingleton<LocationCubit>(
    () => LocationCubit(getIt<LocationRepository>()),
  );
  getIt.registerLazySingleton<SlotCubit>(
    () => SlotCubit(getIt<SlotRepository>()),
  );
  getIt.registerFactory<RevenueCubit>(
    () => RevenueCubit(getIt<BookingRepository>(), getIt<LocationRepository>()),
  );

  getIt.registerLazySingleton<SportRepository>(
    () => SportRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<SportCubit>(
    () => SportCubit(getIt<SportRepository>()),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<SupabaseClient>()),
  );
  getIt.registerFactory<NotificationCubit>(
    () => NotificationCubit(getIt<NotificationRepository>()),
  );
}
