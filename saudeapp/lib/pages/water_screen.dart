import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';

class WaterScreen extends StatefulWidget {
  final int userId;
  const WaterScreen({super.key, required this.userId});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final int _metaAgua = 2500;
  int _totalAgua = 0;
  bool _isLoading = true;
  List<int> _historicoIds = [];
  late final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _repo.obterConsumoAguaDoDia(widget.userId);
      if (!mounted) return;
      setState(() {
        _totalAgua = data.totalMl;
        _historicoIds = data.registoIds;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adicionarAgua(int ml) async {
    try {
      final id = await _repo.registarAgua(widget.userId, ml);
      if (!mounted) return;
      setState(() {
        _totalAgua += ml;
        _historicoIds.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("+$ml ml"),
          backgroundColor: Colors.cyan,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogPersonalizado() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Quantidade personalizada"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Quantidade (ml)",
            hintText: "Ex: 350",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = int.tryParse(controller.text);
              if (valor != null && valor > 0) {
                Navigator.pop(ctx, valor);
              }
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
    if (result != null) {
      await _adicionarAgua(result);
    }
  }

  Future<void> _removerUltimo() async {
    if (_historicoIds.isEmpty) return;
    try {
      await _repo.apagarRegistoAgua(_historicoIds.last);
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao remover: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progresso = (_totalAgua / _metaAgua).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hidratação', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (_historicoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white70),
              onPressed: _removerUltimo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const Spacer(),
                _buildBottle(progresso),
                const SizedBox(height: 30),
                Text(
                  "$_totalAgua ml",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "META: $_metaAgua ml",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _quickButton(250, "Copo"),
                          _quickButton(500, "Garrafa"),
                          _quickButton(750, "Garrafa+"),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _mostrarDialogPersonalizado,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            "PERSONALIZADO",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildBottle(double fill) {
    return SizedBox(
      width: 120,
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 280 * fill,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.8),
                    Colors.cyan,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton(int ml, String label) {
    return ElevatedButton(
      onPressed: () => _adicionarAgua(ml),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        children: [
          Text(
            "$ml ml",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
