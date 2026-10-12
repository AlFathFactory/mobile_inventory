import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_inventory_service.dart';
import 'inventory_repository.dart';
import 'preview_inventory_repository.dart';
import 'supabase_inventory_repository.dart';

abstract final class InventoryRepositoryFactory {
  static InventoryRepository create(SupabaseClient? client) {
    if (client == null) return const PreviewInventoryRepository();
    return SupabaseInventoryRepository(SupabaseInventoryService(client));
  }
}
