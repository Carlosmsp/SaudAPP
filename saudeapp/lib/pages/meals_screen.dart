import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/habitos_repository.dart';

class MealsScreen extends StatefulWidget {
  final int userId;

  const MealsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final int _metaCalorias = 2000; // meta diária (ajusta se quiseres)

  int _totalCalorias = 0;
  bool _isLoading = true;
  List<int> _historicoIds = [];

  // Repositório de hábitos (já criado antes)
  late final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final data = await _repo.obterRefeicoesDoDia(widget.userId);

      if (!mounted) return;
      setState(() {
        _totalCalorias = data.totalCalorias;
        _historicoIds = List<int>.from(data.registoIds);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarRefeicao({
    required String tipo,
    required int calorias,
  }) async {
    setState(() => _totalCalorias += calorias);

    try {
      final id = await _repo.registarRefeicao(
        userId: widget.userId,
        tipo: tipo,
        calorias: calorias,
      );

      if (!mounted) return;
      setState(() => _historicoIds.add(id));
    } catch (e) {
      if (!mounted) return;
      // desfaz localmente se deu erro na BD
      setState(() => _totalCalorias -= calorias);
    }
  }

  Future<void> _desfazerUltimaRefeicao() async {
    if (_historicoIds.isEmpty) return;

    final ultimoId = _historicoIds.last;

    try {
      final calorias = await _repo.apagarRegistoRefeicao(ultimoId);

      if (!mounted) return;
      setState(() {
        _totalCalorias -= calorias;
        _historicoIds.removeLast();
      });
    } catch (e) {
      // se algo correr mal, recarrega do servidor
      await _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progresso = (_totalCalorias / _metaCalorias).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1B262F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refeições',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          if (_historicoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orangeAccent),
              onPressed: _desfazerUltimaRefeicao,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orangeAccent,
              ),
            )
          : Column(
              children: [
                // “Gráfico” de progresso (podes trocar se quiseres outro estilo)
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progresso,
                            strokeWidth: 16,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orangeAccent.shade200,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(progresso * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "CALORIAS",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Totais
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _info(
                        "${(_metaCalorias - _totalCalorias).clamp(0, 9999)} kcal",
                        "FALTA",
                      ),
                      _info(
                        "${_totalCalorias} kcal",
                        "HOJE",
                      ),
                      _info(
                        "${_metaCalorias} kcal",
                        "META",
                      ),
                    ],
                  ),
                ),

                // Botões de adicionar refeição
                Container(
                  padding: const EdgeInsets.only(
                    top: 30,
                    bottom: 40,
                    left: 20,
                    right: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _mealButton(
                        icon: Icons.free_breakfast,
                        label: "Peq. almoço",
                        onTap: () => _perguntarCalorias("Pequeno-almoço"),
                      ),
                      _mealButton(
                        icon: Icons.lunch_dining,
                        label: "Almoço",
                        onTap: () => _perguntarCalorias("Almoço"),
                      ),
                      _mealButton(
                        icon: Icons.dinner_dining,
                        label: "Jantar",
                        onTap: () => _perguntarCalorias("Jantar"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _info(String valor, String label) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _mealButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  void _perguntarCalorias(String tipo) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Calorias – $tipo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Ex: 500",
            labelText: "Calorias",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = int.tryParse(controller.text);
              if (valor != null && valor > 0) {
                _adicionarRefeicao(tipo: tipo, calorias: valor);
                Navigator.pop(ctx);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
