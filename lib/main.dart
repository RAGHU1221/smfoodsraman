import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/bill_repository.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task == AppConstants.SYNC_TASK_NAME) {
      try { await BillRepository().syncPendingBills(); } catch (_) {}
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    AppConstants.SYNC_TASK_NAME, AppConstants.SYNC_TASK_NAME,
    frequency: const Duration(minutes: AppConstants.SYNC_INTERVAL_MINUTES),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(const SMFoodsApp());
}

class SMFoodsApp extends StatelessWidget {
  const SMFoodsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'Sri Murugan POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login':  (_) => const LoginScreen(),
          '/home':   (_) => const HomeScreen(),
        },
      ),
    );
  }
}
