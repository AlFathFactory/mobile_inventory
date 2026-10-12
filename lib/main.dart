import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/services/supabase_bootstrap.dart';
import 'features/inventory/data/repositories/inventory_repository_factory.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = await SupabaseBootstrap.initialize();
  final inventoryRepository = InventoryRepositoryFactory.create(client);
  runApp(MyApp(inventoryRepository: inventoryRepository));
}
