import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/firebase_options.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart' as di;
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/login_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/otp_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/signup_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/forgot_password_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/email_verification_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/document_upload_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/step1_personal_info_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/step2_documents_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/onboarding/step3_venue_details_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/main_navbar.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/splash_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/auth/pending_approval_screen.dart';

//"Read MEMORY.md and continue working"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://qcybnzopffyzmpiaxwbc.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
    ),
  );

  await di.init();
  await AppConfigService.instance.load();
  await SharedPrefsService.instance.init();

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
        BlocProvider<SportCubit>(
          create: (_) => di.getIt<SportCubit>()..fetchSports(),
        ),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          title: 'TurfPro Owner',
          debugShowCheckedModeBanner: false,
          theme: AppColors.getLightTheme(),
          darkTheme: AppColors.getDarkTheme(),
          themeMode: ThemeMode.light,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/email-verification': (context) => const EmailVerificationScreen(),
            '/otp': (context) => const OtpScreen(),
            '/document-upload': (context) => const DocumentUploadScreen(),
            '/onboarding/step1': (context) => const Step1PersonalInfoScreen(),
            '/onboarding/step2': (context) => const Step2DocumentsScreen(),
            '/onboarding/step3': (context) => const Step3VenueDetailsScreen(),
            '/dashboard': (context) => const MainNavbar(),
            '/add-location': (context) => const LocationFormScreen(),
            '/pending-approval': (context) => const PendingApprovalScreen(),
          },
        ),
      ),
    );
  }
}
