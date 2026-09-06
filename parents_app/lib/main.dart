import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.I.init();
  runApp(const BazinoApp());
}
