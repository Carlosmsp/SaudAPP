import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _fazerRegisto() async {
    setState(() => _isLoading = true);
    final name = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preenche todos os campos.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Voltamos ao método simples que não dá erro de "email invalid"
      await Supabase.instance.client.from('utilizadores').insert({
        'nome': name,
        'email': email,
        'password_hash': password, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 180),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome")),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
                    const SizedBox(height: 20),
                    _isLoading 
                      ? const CircularProgressIndicator() 
                      : ElevatedButton(onPressed: _fazerRegisto, child: const Text("CRIAR CONTA")),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}