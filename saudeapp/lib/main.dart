import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart';

// --- CONFIGURAÇÕES ---
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

  runApp(const MeuAppSaude());
}

class MeuAppSaude extends StatelessWidget {
  const MeuAppSaude({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaudApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),

      home: const WelcomePage(),
    );
  }
}
