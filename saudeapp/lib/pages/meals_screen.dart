import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';

class MealsScreen extends StatefulWidget {
  final int userId;
  const MealsScreen({super.key, required this.userId});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final int _metaCalorias = 2000;
  int _totalCalorias = 0;
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
      setState(() => _totalCalorias -= calorias);
    }
  }

  Future<void> _desfazerUltimaRefeicao() async {
    if (_historicoIds.isEmpty) return;
    final ultimoId = _historicoIds.last;
    try {
      await _repo.apagarRegistoRefeicao(ultimoId);
      if (!mounted) return;
      await _carregarDados();
    } catch (e) {
      await _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progresso = (_totalCalorias / _metaCalorias).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF121B24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refeições',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_historicoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_rounded, color: Colors.orangeAccent),
              onPressed: _desfazerUltimaRefeicao,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progresso,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ), // Corrigido para evitar erro
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.orangeAccent,
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
                                fontSize: 54,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                            const Text(
                              "CALORIAS",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoCard(
                        "${(_metaCalorias - _totalCalorias).clamp(0, 9999)}",
                        "FALTA",
                      ),
                      _infoCard("$_totalCalorias", "HOJE"),
                      _infoCard("$_metaCalorias", "META"),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(25, 40, 25, 50),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF5E6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _mealIcon(
                        Icons.coffee_rounded,
                        "Peq. Almoço",
                        () => _perguntarCalorias("Pequeno-almoço"),
                      ),
                      _mealIcon(
                        Icons.lunch_dining_rounded,
                        "Almoço",
                        () => _perguntarCalorias("Almoço"),
                      ),
                      _mealIcon(
                        Icons.dinner_dining_rounded,
                        "Jantar",
                        () => _perguntarCalorias("Jantar"),
                      ),
                    ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Registar $tipo"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Quantidade de Calorias",
            hintText: "Ex: 450", // Ajuda o utilizador
            suffixText: "kcal", // Unidade clara
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null) {
                _adicionarRefeicao(tipo: tipo, calorias: v);
                Navigator.pop(ctx);
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String v, String l) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(l, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ],
  );

  Widget _mealIcon(IconData i, String l, VoidCallback a) => InkWell(
    onTap: a,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(i, size: 32, color: Colors.orange),
        ),
        const SizedBox(height: 12),
        Text(l, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
