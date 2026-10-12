import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/inventory/data/repositories/inventory_repository.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.previewLoadDelay = const Duration(milliseconds: 650),
    this.inventoryRepository,
  });

  final Duration previewLoadDelay;
  final InventoryRepository? inventoryRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    previewLoadDelay: widget.previewLoadDelay,
    inventoryRepository: widget.inventoryRepository,
  );

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مراقبة المخزون',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: _appRouter.router,
    );
  }
}
