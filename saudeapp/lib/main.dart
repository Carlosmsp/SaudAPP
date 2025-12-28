import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/main_wrapper.dart';
import 'services/notification_service.dart';

class SupabaseConfig {
  static const String url = 'https://dzrpklriotqdaxhxnjfq.supabase.co';
  static const String anonKey =
      'sb_publishable_8WhtpqWZ3257s4FcblrG1w_TXP1doAt';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService().initNotification();

  runApp(const MeuAppSaude());
}

class MeuAppSaude extends StatelessWidget {
  const MeuAppSaude({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    return MaterialApp(
      title: 'SaudApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyan,
      ),
      home: user != null 
          ? MainWrapper(
              userId: int.tryParse(user.id) ?? 1, 
              nomeUsuario: user.userMetadata?['full_name'] ?? 'Utilizador'
            ) 
          : const WelcomePage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => const MainWrapper(nomeUsuario: 'Utilizador', userId: 1),
      },
    );
  }
}