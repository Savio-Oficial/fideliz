import 'package:flutter/material.dart';

import 'models/usuario_model.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initializeFromEnvironment();
  runApp(const FidelizApp());
}

class FidelizApp extends StatefulWidget {
  const FidelizApp({super.key});

  @override
  State<FidelizApp> createState() => _FidelizAppState();
}

class _FidelizAppState extends State<FidelizApp> {
  Future<Usuario?> _carregarSessao() => AuthService.carregarSessao();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fideliz',
      theme: AppTheme.lightTheme(),
      home: FutureBuilder<Usuario?>(
        future: _carregarSessao(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(usuario: snapshot.data!);
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
