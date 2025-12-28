import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/habitos_repository.dart';

class MealsHistoryScreen extends StatefulWidget {
  final int userId;
  const MealsHistoryScreen({super.key, required this.userId});

  @override
  State<MealsHistoryScreen> createState() => _MealsHistoryScreenState();
}

class _MealsHistoryScreenState extends State<MealsHistoryScreen> {
  List<Map<String, dynamic>> _registos = [];
  int _totalCalorias = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final repo = HabitosRepository.fromSupabase();
      final registos = await repo.obterRefeicoesDetalhadasDoDia(widget.userId);

      if (mounted) {
        int total = 0;
        for (var r in registos) {
          final cal = r['calorias_kcal'];
          if (cal != null) {
            total += (cal as num).toInt();
          }
        }

        setState(() {
          _registos = registos;
          _totalCalorias = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Histórico de Refeições',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Total de Hoje',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${_totalCalorias}kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_registos.length} ${_registos.length == 1 ? 'refeição' : 'refeições'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _registos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Sem registos hoje',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: _registos.length,
                          itemBuilder: (context, index) {
                            final registo = _registos[index];
                            final tipo =
                                registo['tipo_refeicao'] as String? ??
                                'Refeição';
                            final calorias =
                                (registo['calorias_kcal'] as num?)?.toInt() ??
                                0;

                            String hora = 'Sem hora';
                            try {
                              if (registo['habitos'] != null &&
                                  registo['habitos']['data_registo'] != null) {
                                final dataRegisto =
                                    registo['habitos']['data_registo']
                                        as String;
                                final data = DateTime.parse(dataRegisto);
                                hora = DateFormat('HH:mm').format(data);
                              }
                            } catch (_) {}

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Color(0xFFFF9800),
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  tipo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '$hora • ${calorias}kcal',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
