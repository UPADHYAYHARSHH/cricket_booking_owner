import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:turfpro_owner/firebase_options.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart' as di;
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/login_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/otp_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/signup_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/forgot_password_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/email_verification_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/document_upload_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/main_navbar.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/personal_info_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/venue_type_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/amenities_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/slot_config_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/pricing_setup_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/kyc_documentation_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/photos_media_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/review_submit_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/venue_details_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/ground_court_info_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://qcybnzopffyzmpiaxwbc.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
    ),
  );

  await di.init();
  await AppConfigService.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => di.getIt<AuthCubit>()),
        BlocProvider<GroundCubit>(create: (_) => di.getIt<GroundCubit>()),
        BlocProvider<LocationCubit>(create: (_) => di.getIt<LocationCubit>()),
        BlocProvider<SlotCubit>(create: (_) => di.getIt<SlotCubit>()),
        BlocProvider<BookingsCubit>(create: (_) => di.getIt<BookingsCubit>()),
        BlocProvider<DashboardCubit>(create: (_) => di.getIt<DashboardCubit>()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          title: 'TurfPro Owner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF6B00),
            ),
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/email-verification': (context) => const EmailVerificationScreen(),
            '/otp': (context) => const OtpScreen(),
            '/upload-documents': (context) => const DocumentUploadScreen(),
            '/dashboard': (context) => const MainNavbar(),
            '/personal-info': (context) => const PersonalInfoScreen(),
            '/venue-type': (context) => const VenueTypeScreen(),
            '/venue-details': (context) => const VenueDetailsScreen(),
            '/ground-court-info': (context) => const GroundCourtInfoScreen(),
            '/amenities': (context) => const AmenitiesScreen(),
            '/amenities-settings': (context) =>
                const AmenitiesScreen(isSettingsMode: true),
            '/slot-config': (context) => const SlotConfigScreen(),
            '/pricing-setup': (context) => const PricingSetupScreen(),
            '/kyc-documentation': (context) => const KycDocumentationScreen(),
            '/photos-media': (context) => const PhotosMediaScreen(),
            '/review-submit': (context) => const ReviewSubmitScreen(),
          },
        ),
      ),
    );
  }
}
