import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Configurações do Supabase ---
class SupabaseConfig {
  static const String url = 'https://dzrpklriotqdaxhxnjfq.supabase.co';
  static const String anonKey =
      'sb_publishable_8WhtpqWZ3257s4FcblrG1w_TXP1doAt';
  static const String tabela = 'utilizadores';
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
      title: 'App Saúde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const SplashPage(),
    );
  }
}

// --- PÁGINA DE CARREGAMENTO (SPLASH) ---
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusMessage = 'A conectar ao servidor...';
  bool _temErro = false;

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    setState(() {
      _temErro = false;
      _statusMessage = 'A verificar base de dados...';
    });

    try {
      // Teste simples de conexão
      await Supabase.instance.client
          .from(SupabaseConfig.tabela)
          .select()
          .limit(1);

      if (mounted) {
        // Se correu bem, vai para a HomePage (Login)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _temErro = true;
          _statusMessage = 'Falha na conexão.\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_temErro)
                const Icon(Icons.error_outline, color: Colors.red, size: 60)
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              if (_temErro) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _inicializarApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- PÁGINA DE LOGIN (HOMEPAGE) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- FUNÇÃO DE LOGIN (MANTIDA IGUAL) ---
  Future<void> _fazerLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preenche o email e a password'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('utilizadores')
          .select()
          .eq('email', email)
          .eq('password_hash', password)
          .maybeSingle();

      if (data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem-vindo(a), ${data['nome']}!'),
              backgroundColor: Colors.green,
            ),
          );
          // AQUI FUTURAMENTE ENTRARÁS NA DASHBOARD
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email ou password errados!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro técnico: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- NOVO VISUAL ESTILO FIGMA ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: size.height),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00C6FB), // Azul claro
                Color(0xFF005BEA), // Azul escuro
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // LOGÓTIPO
                Image.asset('assets/images/logo.png', height: 150),
                const SizedBox(height: 40),

                // CARTÃO DE LOGIN
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Email",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Ex: ana.silva@email.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Password",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Esqueceu-se da password?',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // BOTÃO ENTRAR
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TEXTO REGISTAR
                      Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: RichText(
                            text: const TextSpan(
                              text: 'Ainda não tens conta? ',
                              style: TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: 'Regista-te',
                                  style: TextStyle(
                                    color: Color(0xFF005BEA),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
