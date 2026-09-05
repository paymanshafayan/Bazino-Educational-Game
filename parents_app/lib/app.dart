import 'package:flutter/material.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/link/link_screen.dart';
import 'features/shell/home_shell.dart';

class BazinoApp extends StatelessWidget {
  const BazinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bazino Ebeveyn',
      debugShowCheckedModeBanner: false,
      theme: BazinoTheme.dark(),
      home: AnimatedBuilder(
        animation: Session.I,
        builder: (context, _) {
          final s = Session.I;
          if (!s.loggedIn) return const LoginScreen();
          if (s.childIds.isEmpty) return const LinkScreen();
          return const HomeShell();
        },
      ),
    );
  }
}
