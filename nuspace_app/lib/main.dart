import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/firebase_options.dart';
import 'package:nuspace_app/screens/activities/activity_forms.dart';
import 'package:nuspace_app/screens/activities/activityscreen.dart';
import 'package:nuspace_app/screens/activities/viewactivityscreen.dart';
import 'package:nuspace_app/screens/authentication/changepassword_emailcode.dart';
import 'package:nuspace_app/screens/authentication/checkemailscreen.dart';
import 'package:nuspace_app/screens/authentication/emailverificationscreen.dart';
import 'package:nuspace_app/screens/authentication/forgotpasswordscreen.dart';
import 'package:nuspace_app/screens/notification/notification_screen.dart';
import 'package:nuspace_app/screens/notification/notification_settings_screen.dart';
import 'package:nuspace_app/screens/rso/homescreen.dart';
import 'package:nuspace_app/screens/rso/rsoannouncementscreen.dart';
import 'package:nuspace_app/screens/rso/rsomembershipforms.dart';
import 'package:nuspace_app/screens/rso/viewrsoscreeen.dart';
import 'package:nuspace_app/screens/user/interestscreen.dart';
import 'package:nuspace_app/screens/landing_screen.dart';
import 'package:nuspace_app/screens/authentication/loginscreen.dart';
import 'package:nuspace_app/screens/mainscreen.dart';
import 'package:nuspace_app/screens/authentication/registerscreen.dart';
import 'package:nuspace_app/screens/user/profilescreen.dart';
import 'package:nuspace_app/services/auth_service.dart';
import 'package:nuspace_app/services/connectivity_service.dart';
import 'package:nuspace_app/services/notification_service.dart';
import 'package:nuspace_app/widgets/snackbarhelper.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setPreferredOrientations();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseBackgroundHandler,
  );

  String initialRoute = await AuthService.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
      ],
      child: MainApp(initialRoute: initialRoute),
    ),
  );
}

void setPreferredOrientations() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

final MyCustomNavigatorObserver myObserver = MyCustomNavigatorObserver();

class MainApp extends StatelessWidget {
  final String initialRoute;
  const MainApp({super.key, required this.initialRoute});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 715),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (_, child) {
        return MaterialApp(
          navigatorObservers: [myObserver],
          debugShowCheckedModeBanner: false,
          title: 'NU Space',
          scaffoldMessengerKey: scaffoldMessengerKey,
          initialRoute: initialRoute,
          routes: {
            '/landingScreen': (context) => const LandingScreen(),
            '/loginScreen': (context) => const LoginScreen(),
            '/registerAccountScreen': (context) => const RegisterScreen(),
            '/interestScreen': (context) => const InterestScreen(),
            '/checkEmailScreen': (context) => const CheckEmailScreen(),
            '/homeScreen': (context) => const HomeScreen(),
            '/activityScreen': (context) => const ActivityScreen(),
            '/profileScreen': (context) => const ProfileScreen(),
            '/mainScreen': (context) => const MainScreen(),
            '/notificationScreen': (context) => const NotificationScreen(),
            '/notificationSettingsScreen':
                (context) => const NotificationSettingsScreen(),
          },
          onGenerateRoute: (settings) {
            //routes that needs arguments
            switch (settings.name) {
              case '/emailVerificationScreen':
                final email = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => EmailVerificationScreen(email: email),
                );

              case '/changePasswordEmailCode':
                final email = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => ChangePasswordEmailCode(email: email),
                );

              case '/forgotPasswordScreen':
                final email = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => ForgotPasswordScreen(email: email),
                );

              case '/viewRSOScreen':
                final args = settings.arguments as Map<String, dynamic>?;
                final rsoId = args?['rsoId'] as String?;
                return MaterialPageRoute(
                  builder: (_) => ViewRSOScreen(rsoId: rsoId),
                );

              case '/viewActivityScreen':
                final args = settings.arguments as Map<String, dynamic>?;
                final activityID = args?['activityID'] as String?;
                return MaterialPageRoute(
                  builder: (_) => ViewActivityScreen(activityID: activityID),
                );

              case '/announcementScreen':
                final args = settings.arguments as Map<String, dynamic>;
                final rsoId = args['rsoId'] as String?;
                return MaterialPageRoute(
                  builder: (_) => RSOAnnouncementScreen(rsoId: rsoId),
                );

              case '/membershipForms':
                final args = settings.arguments as Map<String, dynamic>;
                final rsoId = args['rsoId'] as String?;
                return MaterialPageRoute(
                  builder: (_) => RSOMembershipForms(rsoId: rsoId),
                );

              case '/activityForms':
                final args = settings.arguments as Map<String, dynamic>;
                final activityId = args['activityId'] as String?;
                final formType = args['formType'] as String?;
                return MaterialPageRoute(
                  builder:
                      (_) => ActivityForms(
                        activityId: activityId,
                        formType: formType,
                      ),
                );

              default:
                return null;
            }
          },
          theme: ThemeData(scaffoldBackgroundColor: whitetheme),
          builder: (context, child) {
            return Consumer<ConnectivityService>(
              builder: (context, connectivityService, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  //display snackbar when there is no internet connection
                  if (connectivityService.wasOffline) {
                    SnackbarHelper.showConnectivityStatus(
                      connectivityService.isConnected,
                    );
                  }
                });
                return child!;
              },
              child: child,
            );
          },
        );
      },
    );
  }
}

class MyCustomNavigatorObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('Pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('Popped: ${route.settings.name}');
  }
}
