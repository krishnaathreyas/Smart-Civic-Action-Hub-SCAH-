import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/comments_provider.dart';
import '../presentation/providers/location_provider.dart';
import '../presentation/providers/report_provider.dart';
import 'routes.dart';

class SCAHApp extends StatelessWidget {
  const SCAHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final cp = CommentsProvider();
            // Fire and forget load; UI will update when ready
            cp.load();
            return cp;
          },
        ),
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
