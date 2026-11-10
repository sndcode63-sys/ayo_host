import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/animation_utils.dart';
import 'data/repositories/repositories.dart';
import 'data/services/api_client.dart';
import 'state/controllers.dart';
import 'ui/screens/account/account_details_screen.dart';
import 'ui/screens/auth/sign_in_screen.dart';
import 'ui/screens/auth/splash_screen.dart';
import 'ui/screens/dashboard/main_shell.dart';
import 'ui/screens/documents/vehicle_documents_screen.dart';
import 'ui/screens/insights/performance_insights_screen.dart';
import 'ui/screens/earnings/earnings_screen.dart';
import 'ui/screens/menu/more_menu_screen.dart';
import 'ui/screens/notifications/notifications_screen.dart';
import 'ui/screens/onboarding/host_profile_setup_screen.dart';
import 'ui/screens/onboarding/payout_setup_screen.dart';
import 'ui/screens/onboarding/vehicle_details_screen.dart';
import 'ui/screens/onboarding/vehicle_photos_screen.dart';
import 'ui/widgets/toast.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/push_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushService.init();
  } catch (e) {
    debugPrint('Firebase/Push init error: $e');
  }
  await ApiClient.initialize();
  ApiClient.onUnauthorized = () {
    AyoHostApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      SignInScreen.route,
      (route) => false,
    );
  };
  runApp(const AyoHostApp());
}

class AyoHostApp extends StatelessWidget {
  const AyoHostApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => EarningsController()),
        ChangeNotifierProvider(
          create: (_) => OnboardingController(OnboardingRepository(apiClient)),
        ),
      ],
      child: MaterialApp(
        title: 'AYO Host',
        debugShowCheckedModeBanner: false,
        navigatorKey: AyoHostApp.navigatorKey,
        scaffoldMessengerKey: AppToast.messengerKey,
        theme: AppTheme.light,
        initialRoute: SplashScreen.route,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case SplashScreen.route:
              return AnimationUtils.fadeThroughRoute(
                const SplashScreen(),
                settings: settings,
                duration: AnimationUtils.splashExitDuration,
              );
            case SignInScreen.route:
              return AnimationUtils.fadeThroughRoute(
                const SignInScreen(),
                settings: settings,
                duration: AnimationUtils.pageDuration,
              );
            case MainShell.route:
              return AnimationUtils.fadeThroughRoute(
                const MainShell(),
                settings: settings,
                duration: AnimationUtils.splashExitDuration,
              );
            case HostProfileSetupScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const HostProfileSetupScreen(),
                settings: settings,
              );
            case VehicleDetailsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const VehicleDetailsScreen(),
                settings: settings,
              );
            case VehiclePhotosScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const VehiclePhotosScreen(),
                settings: settings,
              );
            case PayoutSetupScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const PayoutSetupScreen(),
                settings: settings,
              );
            case VehicleDocumentsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const VehicleDocumentsScreen(),
                settings: settings,
              );
            case MoreMenuScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const MoreMenuScreen(),
                settings: settings,
              );
            case AccountDetailsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const AccountDetailsScreen(),
                settings: settings,
              );
            case PerformanceInsightsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const PerformanceInsightsScreen(),
                settings: settings,
              );
            case NotificationsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const NotificationsScreen(),
                settings: settings,
              );
            case EarningsScreen.route:
              return AnimationUtils.smoothSlideRoute(
                const EarningsScreen(),
                settings: settings,
              );
            default:
              return AnimationUtils.smoothSlideRoute(
                const MainShell(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
