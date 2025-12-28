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

  Future<void> _mostrarDialogRefeicao(String tipo, int sugestao) async {
    final controller = TextEditingController(text: sugestao.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tipo),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Calorias (kcal)",
            hintText: "Ex: 650",
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
            child: const Text("REGISTAR"),
          ),
        ],
      ),
    );

    if (result != null) {
      await _adicionarRefeicao(tipo, result);
    }
  }

  Future<void> _adicionarRefeicao(String tipo, int cal) async {
    try {
      final id = await _repo.registarRefeicao(
        userId: widget.userId,
        tipo: tipo,
        calorias: cal,
      );
      if (!mounted) return;
      setState(() {
        _totalCalorias += cal;
        _historicoIds.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$tipo: +$cal kcal"),
          backgroundColor: Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    final caloriasRestantes = _metaCalorias - _totalCalorias;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Refeições', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        actions: [
          if (_historicoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orange),
              onPressed: () async {
                await _repo.apagarRegistoRefeicao(_historicoIds.last);
                _carregarDados();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$_totalCalorias",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "KCAL HOJE",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _infoChip(
                              "Falta",
                              "${caloriasRestantes > 0 ? caloriasRestantes : 0}",
                            ),
                            _infoChip("Meta", "$_metaCalorias"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _mealCard(
                    "Pequeno-almoço",
                    "Clica para registar",
                    400,
                    Icons.coffee,
                    const Color(0xFFFFB74D),
                  ),
                  _mealCard(
                    "Almoço",
                    "Clica para registar",
                    800,
                    Icons.lunch_dining,
                    const Color(0xFFFF8A65),
                  ),
                  _mealCard(
                    "Lanche",
                    "Clica para registar",
                    200,
                    Icons.cookie,
                    const Color(0xFFFFD54F),
                  ),
                  _mealCard(
                    "Jantar",
                    "Clica para registar",
                    700,
                    Icons.dinner_dining,
                    const Color(0xFFFF7043),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _mealCard(
    String nome,
    String desc,
    int sugestaoCalorias,
    IconData icon,
    Color cor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        elevation: 2,
        child: InkWell(
          onTap: () => _mostrarDialogRefeicao(nome, sugestaoCalorias),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cor, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        desc,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
