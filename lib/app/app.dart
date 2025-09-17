import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/report_provider.dart';
import '../presentation/providers/location_provider.dart';
import 'routes.dart';

class SCAHApp extends StatelessWidget {
  const SCAHApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'SCAH - Community Voice',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter(authProvider).router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
