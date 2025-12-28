import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _dadosHoje;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final resumo = await _repo.obterResumoDoDia(widget.userId);
      if (mounted) {
        setState(() {
          _dadosHoje = resumo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Dashboard Principal",
            style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarResumo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildMonitorCards(),
              const SizedBox(height: 30),
              const Text("Atalhos Rápidos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildGridMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Olá, ${widget.nomeUsuario.split(' ').first}!",
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const Text("Vamos cuidar da saúde?",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMonitorCards() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)
        ],
      ),
      child: Column(
        children: [
          _resumoLinha("Água consumida", "${_dadosHoje?['total_agua'] ?? 0} ml",
              Colors.cyan),
          const Divider(height: 30),
          _resumoLinha("Calorias totais",
              "${_dadosHoje?['total_calorias'] ?? 0} kcal", Colors.orange),
          const Divider(height: 30),
          _resumoLinha("Sono registado", "${_dadosHoje?['total_sono'] ?? 0} h",
              Colors.indigoAccent),
        ],
      ),
    );
  }

  Widget _resumoLinha(String label, String valor, Color cor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          CircleAvatar(radius: 5, backgroundColor: cor),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
        ]),
        Text(valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGridMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _botaoDashboard(
          icon: Icons.water_drop,
          label: "ÁGUA",
          color: Colors.cyan,
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => WaterScreen(userId: widget.userId)))
              .then((_) => _carregarResumo()),
        ),
        _botaoDashboard(
          icon: Icons.restaurant,
          label: "REFEIÇÕES",
          color: Colors.orange,
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => MealsScreen(userId: widget.userId)))
              .then((_) => _carregarResumo()),
        ),
        _botaoDashboard(
          icon: Icons.bed,
          label: "DORMIR",
          color: Colors.indigoAccent,
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => SleepScreen(userId: widget.userId)))
              .then((_) => _carregarResumo()),
        ),
        _botaoDashboard(
          icon: Icons.directions_run,
          label: "ATIVIDADE",
          color: Colors.green,
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => ActivityScreen(userId: widget.userId)))
              .then((_) => _carregarResumo()),
        ),
      ],
    );
  }

  Widget _botaoDashboard(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}