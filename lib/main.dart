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

void main() {
  final apiClient = ApiClient();
  runApp(AyoHostApp(apiClient: apiClient));
}

class AyoHostApp extends StatelessWidget {
  const AyoHostApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
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
