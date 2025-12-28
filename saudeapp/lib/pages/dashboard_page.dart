import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/habitos_repository.dart';
import 'water_screen.dart';
import 'activity_screen.dart';
import 'meals_screen.dart';
import 'sleep_screen.dart';

class DashboardPage extends StatefulWidget {
  final String nomeUsuario;
  final int userId;
  const DashboardPage({
    super.key,
    required this.nomeUsuario,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final HabitosRepository _repo = HabitosRepository.fromSupabase();
  bool _isLoading = true;
  String _nomeReal = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await _repo.obterResumoDoDia(widget.userId);
      final userData = await Supabase.instance.client
          .from('utilizadores')
          .select('nome')
          .eq('id_utilizador', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          _nomeReal = userData['nome'] ?? widget.nomeUsuario;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nomeReal = widget.nomeUsuario;
          _isLoading = false;
        });
      }
    }
  }

  String _getPrimeiroNome() {
    final partes = _nomeReal.trim().split(' ');
    return partes.isNotEmpty ? partes[0] : _nomeReal;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Dashboard principal",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregar,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Olá, ${_getPrimeiroNome()}!",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Vamos cuidar da saúde?",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: [
                          _card(
                            "ÁGUA",
                            Icons.water_drop,
                            const Color(0xFF4FC3F7),
                            WaterScreen(userId: widget.userId),
                          ),
                          _card(
                            "REFEIÇÕES",
                            Icons.restaurant,
                            const Color(0xFFFFB74D),
                            MealsScreen(userId: widget.userId),
                          ),
                          _card(
                            "DORMIR",
                            Icons.bed,
                            const Color(0xFF3D5AFE),
                            SleepScreen(userId: widget.userId),
                          ),
                          _card(
                            "ATIVIDADE",
                            Icons.directions_run,
                            const Color(0xFF8BC34A),
                            ActivityScreen(userId: widget.userId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _card(String label, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => page),
      ).then((_) => _carregar()),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
