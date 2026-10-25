import 'package:flutter/material.dart';

import 'startup/production_startup.dart';

export 'app.dart';
export 'startup/production_startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProductionStartup());
}
