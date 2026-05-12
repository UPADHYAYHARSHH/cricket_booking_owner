import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:developer' as dev;

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    dev.log('Bloc Created: ${bloc.runtimeType}', name: 'BLOC');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    dev.log('Bloc Transition: ${bloc.runtimeType}', name: 'BLOC');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    dev.log('Bloc Error in ${bloc.runtimeType}: $error', name: 'BLOC', error: error, stackTrace: stackTrace);

    // Automatically report all Bloc level errors to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Fatal error in ${bloc.runtimeType}',
      // We can also mark these as non-fatal if they don't crash the app
      fatal: false, 
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    dev.log('Bloc Closed: ${bloc.runtimeType}', name: 'BLOC');
  }
}
