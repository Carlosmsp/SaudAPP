import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';


class WaterScreen extends StatefulWidget {
  final int userId;

  const WaterScreen({super.key, required this.userId});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final int _metaDiaria = 2000;
  int _consumido = 0;
  bool _isLoading = true;
  List<int> _historicoIds = [];

  late final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final data = await _repo.obterConsumoAguaDoDia(widget.userId);

      if (!mounted) return;

      setState(() {
        _consumido = data.totalMl;
        _historicoIds = List<int>.from(data.registoIds);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  Future<void> _adicionarAgua(int ml) async {
    setState(() => _consumido += ml);

    try {
      final id = await _repo.registarAgua(widget.userId, ml);

      if (!mounted) return;
      setState(() => _historicoIds.add(id));
    } catch (e) {
      // Se deu erro no Supabase, desfaz o valor local
      if (!mounted) return;
      setState(() => _consumido -= ml);
    }
  }


  Future<void> _desfazer() async {
    if (_historicoIds.isEmpty) return;

    final ultimoId = _historicoIds.last;

    try {
      final ml = await _repo.apagarRegistoAgua(ultimoId);

      if (!mounted) return;
      setState(() {
        _consumido -= ml;
        _historicoIds.removeLast();
      });
    } catch (e) {
      // Se algo correr mal, recarrega do servidor para ficar consistente
      await _carregarDados();
    }
  }


  @override
  Widget build(BuildContext context) {
    double progresso = (_consumido / _metaDiaria).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Hidratação", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
        actions: [
          if (_historicoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orangeAccent),
              onPressed: _desfazer,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent)) 
        : Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 160,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white24, width: 2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    width: 156,
                    height: 396 * progresso,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blueAccent.withValues(alpha: 0.7),
                          Colors.blue.shade900.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: const Radius.circular(38),
                        bottomRight: const Radius.circular(38),
                        topLeft: Radius.circular(progresso >= 0.95 ? 38 : 5),
                        topRight: Radius.circular(progresso >= 0.95 ? 38 : 5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 180,
                    child: Column(
                      children: [
                        Text(
                          "${(progresso * 100).toInt()}%",
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w100),
                        ),
                        const Text("CONCLUÍDO", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _info("${(_metaDiaria - _consumido).clamp(0, 9999)}ml", "FALTA"),
                _info("${_consumido}ml", "HOJE"),
                _info("${_metaDiaria}ml", "META"),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 30, bottom: 40, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _btn(Icons.local_drink_outlined, "250ml", () => _adicionarAgua(250)),
                _btn(Icons.water_drop_outlined, "500ml", () => _adicionarAgua(500)),
                _btn(Icons.add_circle_outline, "Custom", _custom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(l, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.2)),
  ]);

  Widget _btn(IconData i, String l, VoidCallback a) => InkWell(
    onTap: a,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(i, size: 30, color: Colors.blue.shade700),
      ),
      const SizedBox(height: 8),
      Text(l, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
    ]),
  );

  void _custom() {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Quantidade (ml)"),
      content: TextField(controller: c, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Sair")),
        ElevatedButton(onPressed: () {
          final v = int.tryParse(c.text);
          if (v != null && v > 0) { _adicionarAgua(v); Navigator.pop(ctx); }
        }, child: const Text("OK")),
      ],
    ));
  }
}