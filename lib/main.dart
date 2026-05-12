import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/screens/login_screen.dart';
import 'package:turfpro_owner/screens/otp_screen.dart';
import 'package:turfpro_owner/screens/document_upload_screen.dart';
import 'package:turfpro_owner/screens/main_navbar.dart';
import 'package:turfpro_owner/screens/add_sport_screen.dart';
import 'package:turfpro_owner/screens/personal_info_screen.dart';
import 'package:turfpro_owner/screens/venue_type_screen.dart';
import 'package:turfpro_owner/screens/venue_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/otp': (context) => const OtpScreen(),
            '/upload-documents': (context) => const DocumentUploadScreen(),
            '/dashboard': (context) => const MainNavbar(),
            '/add-sport': (context) => const AddSportScreen(),
            '/personal-info': (context) => const PersonalInfoScreen(),
            '/venue-type': (context) => const VenueTypeScreen(),
            '/venue-details': (context) => const VenueDetailsScreen(),
          },
        ),
      ),
    );
  }
}
