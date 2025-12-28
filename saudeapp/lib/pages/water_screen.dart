import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';
import 'water_history_screen.dart';

class WaterScreen extends StatefulWidget {
  final int userId;
  const WaterScreen({super.key, required this.userId});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _totalMl = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarTotal();
  }

  Future<void> _carregarTotal() async {
    setState(() => _isLoading = true);
    try {
      final repo = HabitosRepository.fromSupabase();
      final data = await repo.obterConsumoAguaDoDia(widget.userId);
      if (mounted) {
        setState(() {
          _totalMl = data.totalMl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarAgua(int ml) async {
    try {
      final repo = HabitosRepository.fromSupabase();
      await repo.registarAgua(widget.userId, ml);
      if (mounted) {
        setState(() => _totalMl += ml);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ +${ml}ml adicionado!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoPersonalizado() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Quantidade personalizada"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Mililitros (ml)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                Navigator.pop(ctx);
                _adicionarAgua(ml);
              }
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentagem = (_totalMl / 2500 * 100).clamp(0, 100).toInt();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Água", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WaterHistoryScreen(userId: widget.userId),
                ),
              ).then((_) => _carregarTotal());
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: percentagem / 100,
                              strokeWidth: 15,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "$percentagem%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_totalMl}ml / 2500ml",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "Adicionar água",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: [
                          _botaoAgua(100),
                          _botaoAgua(200),
                          _botaoAgua(250),
                          _botaoAgua(330),
                          _botaoAgua(500),
                          _botaoAgua(750),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _mostrarDialogoPersonalizado,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          "Quantidade personalizada",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _botaoAgua(int ml) {
    return ElevatedButton(
      onPressed: () => _adicionarAgua(ml),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00BCD4),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: Text(
        "${ml}ml",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
