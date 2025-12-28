import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  final int userId;
  const RemindersScreen({super.key, required this.userId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _aguaAtivo = true;
  bool _sonoAtivo = false;
  bool _refeicoesAtivo = true;
  bool _atividadeAtivo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lembretes', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lembretes de Hábitos",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Ativa notificações para manter os teus objetivos",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            _lembreteCard(
              "Lembrete de Água",
              "Notificação a cada 2 horas",
              Icons.water_drop,
              const Color(0xFF00BCD4),
              _aguaAtivo,
              (val) => setState(() => _aguaAtivo = val),
            ),
            _lembreteCard(
              "Lembrete de Sono",
              "Todos os dias às 23:00",
              Icons.bedtime,
              const Color(0xFF673AB7),
              _sonoAtivo,
              (val) => setState(() => _sonoAtivo = val),
            ),
            _lembreteCard(
              "Lembrete de Refeições",
              "Almoço (13h) e Jantar (20h)",
              Icons.restaurant,
              const Color(0xFFFF9800),
              _refeicoesAtivo,
              (val) => setState(() => _refeicoesAtivo = val),
            ),
            _lembreteCard(
              "Lembrete de Atividade",
              "Diariamente às 18:00",
              Icons.directions_run,
              const Color(0xFF4CAF50),
              _atividadeAtivo,
              (val) => setState(() => _atividadeAtivo = val),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "As notificações só funcionam se permitires nas definições do telemóvel",
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lembreteCard(
    String titulo,
    String descricao,
    IconData icon,
    Color cor,
    bool ativo,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ativo ? cor.withValues(alpha: 0.4) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ativo ? cor.withValues(alpha: 0.15) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ativo ? cor : Colors.grey[400], size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: ativo, onChanged: onChanged, activeTrackColor: cor),
        ],
      ),
    );
  }
}
