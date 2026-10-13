import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_item_details_service.dart';
import 'item_details_repository.dart';
import 'preview_inventory_repository.dart';
import 'supabase_item_details_repository.dart';

abstract final class ItemDetailsRepositoryFactory {
  static ItemDetailsRepository create(SupabaseClient? client) {
    if (client == null) return const PreviewInventoryRepository();
    return SupabaseItemDetailsRepository(SupabaseItemDetailsService(client));
  }
}
