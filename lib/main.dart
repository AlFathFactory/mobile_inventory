import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/services/supabase_bootstrap.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const MyApp());
}
