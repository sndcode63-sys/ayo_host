import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/repositories.dart';
import 'data/services/api_client.dart';
import 'state/controllers.dart';
import 'ui/screens/account/account_details_screen.dart';
import 'ui/screens/auth/sign_in_screen.dart';
import 'ui/screens/auth/splash_screen.dart';
import 'ui/screens/dashboard/main_shell.dart';
import 'ui/screens/documents/vehicle_documents_screen.dart';
import 'ui/screens/menu/more_menu_screen.dart';
import 'ui/screens/onboarding/host_profile_setup_screen.dart';
import 'ui/screens/onboarding/payout_setup_screen.dart';
import 'ui/screens/onboarding/vehicle_details_screen.dart';
import 'ui/screens/onboarding/vehicle_photos_screen.dart';
import 'ui/widgets/toast.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  await ApiClient.initialize();
  runApp(const AyoHostApp());
}

class AyoHostApp extends StatelessWidget {
  const AyoHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient.instance;

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthRepository(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardController(HostRepository(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(HostRepository(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingController(OnboardingRepository(apiClient)),
        ),
      ],
      child: MaterialApp(
        title: 'AYO Host',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppToast.messengerKey,
        theme: AppTheme.light,
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          SignInScreen.route: (_) => const SignInScreen(),
          MainShell.route: (_) => const MainShell(),
          HostProfileSetupScreen.route: (_) => const HostProfileSetupScreen(),
          VehicleDetailsScreen.route: (_) => const VehicleDetailsScreen(),
          VehiclePhotosScreen.route: (_) => const VehiclePhotosScreen(),
          PayoutSetupScreen.route: (_) => const PayoutSetupScreen(),
          VehicleDocumentsScreen.route: (_) => const VehicleDocumentsScreen(),
          MoreMenuScreen.route: (_) => const MoreMenuScreen(),
          AccountDetailsScreen.route: (_) => const AccountDetailsScreen(),
        },
      ),
    );
  }
}
