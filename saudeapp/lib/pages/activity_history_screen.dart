import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/habitos_repository.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final int userId;
  const ActivityHistoryScreen({super.key, required this.userId});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<Map<String, dynamic>> _registos = [];
  int _totalMinutos = 0;
  double _totalKm = 0.0;
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
      final registos = await repo.obterAtividadesDoDia(widget.userId);

      if (mounted) {
        int totalSeg = 0;
        double totalDist = 0.0;

        for (var r in registos) {
          final seg = r['duracao_segundos'];
          final km = r['distancia_km'];

          if (seg != null) {
            totalSeg += (seg as num).toInt();
          }
          if (km != null) {
            totalDist += (km as num).toDouble();
          }
        }

        setState(() {
          _registos = registos;
          _totalMinutos = (totalSeg / 60).round();
          _totalKm = totalDist;
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
          'Histórico de Atividade',
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
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
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
                        Icons.directions_run,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Total de Hoje',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_totalMinutos}min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '${_totalKm.toStringAsFixed(2)}km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_registos.length} ${_registos.length == 1 ? 'atividade' : 'atividades'}',
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
                                Icons.directions_run_outlined,
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
                                registo['tipo_atividade'] as String? ??
                                'Atividade';
                            final distanciaKm =
                                (registo['distancia_km'] as num?)?.toDouble() ??
                                0.0;
                            final duracaoSeg =
                                (registo['duracao_segundos'] as num?)
                                    ?.toInt() ??
                                0;
                            final duracaoMin = (duracaoSeg / 60).round();

                            String hora = 'Sem hora';
                            try {
                              if (registo['data_registo'] != null) {
                                final dataRegisto =
                                    registo['data_registo'] as String;
                                final data = DateTime.parse(dataRegisto);
                                hora = DateFormat('HH:mm').format(data);
                              }
                            } catch (_) {}

                            IconData icone;
                            Color cor;
                            switch (tipo.toLowerCase()) {
                              case 'corrida':
                                icone = Icons.directions_run;
                                cor = const Color(0xFF4CAF50);
                                break;
                              case 'caminhada':
                                icone = Icons.directions_walk;
                                cor = const Color(0xFF66BB6A);
                                break;
                              case 'ciclismo':
                                icone = Icons.directions_bike;
                                cor = const Color(0xFF2196F3);
                                break;
                              default:
                                icone = Icons.fitness_center;
                                cor = const Color(0xFF4CAF50);
                            }

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
                                    color: cor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icone, color: cor, size: 28),
                                ),
                                title: Text(
                                  tipo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '$hora • ${distanciaKm.toStringAsFixed(2)}km • ${duracaoMin}min',
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
