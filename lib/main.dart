import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:turfpro_owner/firebase_options.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/screens/auth/login_screen.dart';
import 'package:turfpro_owner/screens/auth/otp_screen.dart';
import 'package:turfpro_owner/screens/auth/signup_screen.dart';
import 'package:turfpro_owner/screens/auth/forgot_password_screen.dart';
import 'package:turfpro_owner/screens/auth/email_verification_screen.dart';
import 'package:turfpro_owner/screens/onboarding/document_upload_screen.dart';
import 'package:turfpro_owner/screens/dashboard/main_navbar.dart';
import 'package:turfpro_owner/screens/sports/add_sport_screen.dart';
import 'package:turfpro_owner/screens/onboarding/personal_info_screen.dart';
import 'package:turfpro_owner/screens/onboarding/venue_type_screen.dart';
import 'package:turfpro_owner/screens/onboarding/amenities_screen.dart';
import 'package:turfpro_owner/screens/onboarding/slot_config_screen.dart';
import 'package:turfpro_owner/screens/onboarding/pricing_setup_screen.dart';
import 'package:turfpro_owner/screens/onboarding/kyc_documentation_screen.dart';
import 'package:turfpro_owner/screens/onboarding/photos_media_screen.dart';
import 'package:turfpro_owner/screens/onboarding/review_submit_screen.dart';
import 'package:turfpro_owner/screens/onboarding/venue_details_screen.dart';
import 'package:turfpro_owner/screens/onboarding/ground_court_info_screen.dart';
import 'package:turfpro_owner/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://qcybnzopffyzmpiaxwbc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<GroundCubit>(create: (context) => GroundCubit()),
        BlocProvider<SlotCubit>(create: (context) => SlotCubit()),
        BlocProvider<BookingsCubit>(create: (context) => BookingsCubit()),
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
            '/add-sport': (context) => const AddSportScreen(),
            '/personal-info': (context) => const PersonalInfoScreen(),
            '/venue-type': (context) => const VenueTypeScreen(),
            '/venue-details': (context) => const VenueDetailsScreen(),
            '/ground-court-info': (context) => const GroundCourtInfoScreen(),
            '/amenities': (context) => const AmenitiesScreen(),
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
