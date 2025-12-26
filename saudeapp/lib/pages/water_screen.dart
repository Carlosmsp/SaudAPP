import 'package:flutter/material.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final int _metaDiaria = 2000;
  int _consumido = 0;
  List<int> _historico = [];

  void _adicionarAgua(int ml) {
    setState(() {
      _consumido += ml;
      _historico.add(ml);
    });
  }

  void _desfazerUltimo() {
    if (_historico.isNotEmpty) {
      setState(() {
        int ultimo = _historico.removeLast();
        _consumido -= ultimo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo do progresso (0.0 a 1.0)
    double progresso = (_consumido / _metaDiaria).clamp(0.0, 1.0);

    return Scaffold(
      // Fundo azul escuro profundo (estilo Waterlogged)
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Hidratação",
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        centerTitle: true,
        actions: [
          if (_historico.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orangeAccent),
              onPressed: _desfazerUltimo,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // --- GARRAFA VISUAL ---
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Sombra/Contorno da Garrafa
                  Container(
                    width: 160,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white24, width: 2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  // Água Animada
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutSine,
                    width: 156,
                    height: 396 * progresso,
                    decoration: BoxDecoration(
                      // Gradiente para dar efeito de profundidade à água
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
                  // Texto de Percentagem centralizado
                  Positioned(
                    bottom: 180,
                    child: Column(
                      children: [
                        Text(
                          "${(progresso * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                        const Text(
                          "CONCLUÍDO",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- INFO INFERIOR ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoColuna("${_metaDiaria - _consumido}ml", "FALTA"),
                _infoColuna("${_consumido}ml", "HOJE"),
                _infoColuna("${_metaDiaria}ml", "META"),
              ],
            ),
          ),

          // --- SEÇÃO DE BOTÕES (BRANCA NO FUNDO) ---
          Container(
            padding: const EdgeInsets.only(
              top: 30,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD), // Azul clarinho para os botões
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _botaoIcone(
                  Icons.local_drink_outlined,
                  "250ml",
                  () => _adicionarAgua(250),
                ),
                _botaoIcone(
                  Icons.water_drop_outlined,
                  "500ml",
                  () => _adicionarAgua(500),
                ),
                _botaoIcone(Icons.add_circle_outline, "Custom", () {
                  // Aqui poderias abrir um diálogo para inserir valor manual
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColuna(String valor, String label) {
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _botaoIcone(IconData icone, String label, VoidCallback acao) {
    return InkWell(
      onTap: acao,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 30, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
