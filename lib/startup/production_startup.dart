import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/config/supabase_config.dart';
import '../core/data/local/hive_cache_database.dart';
import '../core/data/services/connecting_inventory_source.dart';
import '../core/data/services/supabase_bootstrap.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_loading_skeleton.dart';
import '../core/widgets/recovery_panel.dart';
import '../features/inventory/data/local/inventory_local_data_source.dart';
import '../features/alerts/data/repositories/alerts_repository_factory.dart';
import '../features/dashboard/data/repositories/dashboard_repository_factory.dart';
import '../features/inventory/data/repositories/inventory_repository_factory.dart';
import '../features/inventory/data/repositories/item_details_repository_factory.dart';
import '../features/inventory/data/repositories/movement_history_repository_factory.dart';
import '../features/reports/data/repositories/reports_repository_factory.dart';

/// Installs a Flutter tree before local storage or network setup starts.
class ProductionStartup extends StatefulWidget {
  const ProductionStartup({
    super.key,
    this.localInitializer,
    this.clientInitializer,
  });

  final Future<InventoryLocalDataSource> Function()? localInitializer;
  final Future<SupabaseClient?> Function()? clientInitializer;

  @override
  State<ProductionStartup> createState() => _ProductionStartupState();
}

class _ProductionStartupState extends State<ProductionStartup> {
  InventoryLocalDataSource? _local;
  SupabaseClient? _client;
  Object? _localError;
  bool _openingLocal = false;
  Future<SupabaseClient?>? _connecting;
  Object? _connectionError;

  @override
  void initState() {
    super.initState();
    unawaited(_openLocal());
  }

  Future<void> _openLocal() async {
    if (_openingLocal) return;
    setState(() {
      _openingLocal = true;
      _localError = null;
    });
    try {
      final local = await (widget.localInitializer?.call() ?? _openHive());
      await local.recoverInterruptedSync();
      if (!mounted) return;
      setState(() => _local = local);
      unawaited(_connect());
    } on Object catch (error) {
      debugPrint('Hive cache initialization failed: $error');
      if (mounted) setState(() => _localError = error);
    } finally {
      if (mounted) setState(() => _openingLocal = false);
    }
  }

  Future<InventoryLocalDataSource> _openHive() async =>
      HiveInventoryLocalDataSource(await HiveCacheDatabase.initializeFlutter());

  Future<SupabaseClient?> _connect() {
    if (_client != null) return Future.value(_client);
    final running = _connecting;
    if (running != null) return running;
    final attempt = _initializeClient();
    _connecting = attempt;
    unawaited(
      attempt.whenComplete(() {
        if (identical(_connecting, attempt)) _connecting = null;
      }),
    );
    return attempt;
  }

  Future<SupabaseClient?> _initializeClient() async {
    try {
      if (widget.clientInitializer == null &&
          !SupabaseConfig.environment.isConfigured) {
        throw const SupabaseConfigurationException();
      }
      final client =
          await (widget.clientInitializer?.call() ??
                  SupabaseBootstrap.initialize())
              .timeout(const Duration(seconds: 10));
      _connectionError = null;
      if (mounted && client != null) setState(() => _client = client);
      return client;
    } on Object catch (error) {
      _connectionError = error;
      debugPrint('Supabase initialization failed: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = _local;
    if (local == null) {
      return MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: _localError == null
                  ? const AppLoadingSkeleton()
                  : Center(
                      child: SingleChildScrollView(
                        child: RecoveryPanel(
                          icon: Icons.storage_rounded,
                          title: 'تعذر فتح بيانات المخزون المحفوظة',
                          message:
                              'تعذر قراءة البيانات المحفوظة على هذا الجهاز. حاول مرة أخرى لفتح التطبيق.',
                          onRetry: _openLocal,
                          isRetrying: _openingLocal,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    }
    final client = _client;
    return MyApp(
      key: ValueKey(client),
      dashboardRepository: DashboardRepositoryFactory.create(client),
      alertsRepository: AlertsRepositoryFactory.create(client),
      inventoryRepository: InventoryRepositoryFactory.create(
        client,
        localDataSource: local,
        remoteDataSource: ConnectingInventorySource(
          _connect,
          () => _connectionError,
        ),
      ),
      itemDetailsRepository: ItemDetailsRepositoryFactory.create(client),
      movementHistoryRepository: MovementHistoryRepositoryFactory.create(
        client,
      ),
      reportsRepository: ReportsRepositoryFactory.create(client),
    );
  }
}
