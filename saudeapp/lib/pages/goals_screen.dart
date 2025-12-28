import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';

class GoalsScreen extends StatefulWidget {
  final int userId;
  const GoalsScreen({super.key, required this.userId});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final HabitosRepository _repo = HabitosRepository.fromSupabase();
  bool _isLoading = true;
  int consumidoAgua = 0;
  int consumidoCalorias = 0;
  double consumidoSono = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final resultados = await Future.wait([
        _repo.obterConsumoAguaDoDia(widget.userId),
        _repo.obterRefeicoesDoDia(widget.userId),
        _repo.obterSonoHoje(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        consumidoAgua = (resultados[0] as DailyWaterData).totalMl;
        consumidoCalorias = (resultados[1] as DailyMealsData).totalCalorias;
        consumidoSono = (resultados[2] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Metas Diárias"), centerTitle: true),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _itemMetas("Água", consumidoAgua.toDouble(), 2000, "ml", Colors.blue),
              _itemMetas("Calorias", consumidoCalorias.toDouble(), 2200, "kcal", Colors.orange),
              _itemMetas("Sono", consumidoSono, 8.0, "h", Colors.indigo),
            ],
          ),
    );
  }

  Widget _itemMetas(String label, double atual, double meta, String uni, Color cor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: (atual / meta).clamp(0, 1), 
            color: cor,
            backgroundColor: cor.withAlpha(30),
          ),
        ),
        trailing: Text("${atual.toInt()}/$meta $uni"),
      ),
    );
  }
}