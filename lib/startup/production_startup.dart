import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/config/supabase_config.dart';
import '../core/data/repositories/data_result.dart';
import '../core/data/repositories/page.dart';
import '../core/data/services/connecting_inventory_source.dart';
import '../core/data/services/supabase_bootstrap.dart';
import '../core/data/services/supabase_failure_mapper.dart';
import '../core/router/app_routes.dart';
import '../features/alerts/data/repositories/alerts_repository_factory.dart';
import '../features/dashboard/data/repositories/dashboard_repository_factory.dart';
import '../features/inventory/data/models/inventory_query.dart';
import '../features/inventory/data/repositories/inventory_repository_factory.dart';
import '../features/inventory/data/repositories/item_details_repository_factory.dart';
import '../features/inventory/data/repositories/movement_history_repository_factory.dart';
import '../features/inventory/data/services/inventory_remote_data_source.dart';
import '../features/inventory/data/services/supabase_inventory_service.dart';
import '../features/reports/data/repositories/reports_repository_factory.dart';
import 'remove_legacy_inventory_cache.dart';

/// Starts live repositories without waiting for device storage.
class ProductionStartup extends StatefulWidget {
  const ProductionStartup({super.key, this.clientInitializer});

  final Future<SupabaseClient?> Function()? clientInitializer;

  @override
  State<ProductionStartup> createState() => _ProductionStartupState();
}

class _ProductionStartupState extends State<ProductionStartup> {
  SupabaseClient? _client;
  Future<SupabaseClient?>? _connecting;
  Object? _connectionError;
  bool _connectionLost = false;
  bool _retrying = false;
  int _connectionGeneration = 0;
  String _lastLocation = AppRoutePaths.dashboard;

  @override
  void initState() {
    super.initState();
    SupabaseFailureMapper.onConnectionFailure = _showConnectionOverlay;
    unawaited(removeLegacyInventoryCache());
    unawaited(_connect());
  }

  @override
  void dispose() {
    if (SupabaseFailureMapper.onConnectionFailure == _showConnectionOverlay) {
      SupabaseFailureMapper.onConnectionFailure = null;
    }
    super.dispose();
  }

  void _showConnectionOverlay() {
    if (mounted && !_connectionLost) setState(() => _connectionLost = true);
  }

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
      if (client == null) throw const SupabaseConnectionException();
      _connectionError = null;
      if (mounted) setState(() => _client = client);
      return client;
    } on Object catch (error) {
      _connectionError = error;
      SupabaseFailureMapper.from(error);
      debugPrint('Supabase initialization failed: $error');
      return null;
    }
  }

  Future<void> _retryConnection() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final client = await _connect();
      if (client == null) return;
      // A client can initialize without a working network. Check a real read.
      await SupabaseInventoryService(client)
          .fetchItems(
            InventoryRemoteQuery.fromInventoryQuery(
              const InventoryQuery(page: PageRequest(limit: 1)),
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _connectionLost = false;
        _connectionGeneration++;
      });
    } on Object catch (error) {
      final failure = SupabaseFailureMapper.from(error);
      if (mounted && failure.kind != DataFailureKind.offline) {
        setState(() {
          _connectionLost = false;
          _connectionGeneration++;
        });
      }
      debugPrint('Connection retry failed: $error');
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    return MyApp(
      key: ValueKey((client, _connectionGeneration)),
      connectionLost: _connectionLost,
      isRetryingConnection: _retrying,
      onRetryConnection: _retryConnection,
      initialLocation: _lastLocation,
      onLocationChanged: (location) => _lastLocation = location,
      dashboardRepository: DashboardRepositoryFactory.create(client),
      alertsRepository: AlertsRepositoryFactory.create(client),
      inventoryRepository: InventoryRepositoryFactory.create(
        client,
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
