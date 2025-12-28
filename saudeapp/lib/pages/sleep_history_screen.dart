import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/habitos_repository.dart';

class SleepHistoryScreen extends StatefulWidget {
  final int userId;
  const SleepHistoryScreen({super.key, required this.userId});

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  List<Map<String, dynamic>> _registos = [];
  double _totalHoras = 0.0;
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
      final registos = await repo.obterSonoDetalhadoDoDia(widget.userId);

      if (mounted) {
        double total = 0.0;
        for (var r in registos) {
          total += (r['horas_dormidas'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          _registos = registos;
          _totalHoras = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Histórico de Sono',
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
                      colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
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
                      const Icon(Icons.bedtime, color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        'Total de Hoje',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${_totalHoras.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_registos.length} ${_registos.length == 1 ? 'registo' : 'registos'}',
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
                                Icons.bedtime_outlined,
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
                            final horas =
                                (registo['horas_dormidas'] as num?)
                                    ?.toDouble() ??
                                0.0;
                            final qualidade = registo['qualidade'] as int? ?? 0;

                            String qualidadeStr;
                            switch (qualidade) {
                              case 1:
                                qualidadeStr = "Muito fraco";
                                break;
                              case 2:
                                qualidadeStr = "Fraco";
                                break;
                              case 3:
                                qualidadeStr = "Normal";
                                break;
                              case 4:
                                qualidadeStr = "Bom";
                                break;
                              case 5:
                                qualidadeStr = "Excelente";
                                break;
                              default:
                                qualidadeStr = "Sem info";
                            }

                            DateTime? deitar, acordar;
                            try {
                              if (registo['hora_deitar'] != null) {
                                deitar = DateTime.parse(
                                  registo['hora_deitar'] as String,
                                );
                              }
                              if (registo['hora_acordar'] != null) {
                                acordar = DateTime.parse(
                                  registo['hora_acordar'] as String,
                                );
                              }
                            } catch (_) {}

                            String periodo = "";
                            if (deitar != null && acordar != null) {
                              periodo =
                                  "${DateFormat('HH:mm').format(deitar)} → ${DateFormat('HH:mm').format(acordar)}";
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
                                    color: const Color(
                                      0xFF673AB7,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.nightlight_round,
                                    color: Color(0xFF673AB7),
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  '${horas.toStringAsFixed(1)}h de sono',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '$periodo\nQualidade: $qualidadeStr',
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
