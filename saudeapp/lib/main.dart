import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
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

  await NotificationService().initialize();

  await Permission.notification.request();

  runApp(const MeuAppSaude());
}

class MeuAppSaude extends StatelessWidget {
  const MeuAppSaude({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaudApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyan,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/welcome': (context) => const WelcomePage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget _initialPage = const WelcomePage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      try {
        final data = await Supabase.instance.client
            .from('utilizadores')
            .select('id_utilizador, nome')
            .eq('user_id', session!.user.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _initialPage = MainWrapper(
              nomeUsuario: data['nome'],
              userId: data['id_utilizador'],
            );
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // Ignore error
      }
    }
    if (mounted) {
      setState(() {
        _initialPage = const WelcomePage();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _initialPage;
  }
}
