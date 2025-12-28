import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // Estados dos switches (Lógicas do Figma)
  bool _agua = true;
  bool _sono = false;
  bool _refeicoes = true;
  bool _atividade = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lembretes", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ícone de cabeçalho igual ao Figma
            const Icon(
              Icons.notifications_active_outlined,
              size: 80,
              color: Colors.cyan,
            ),
            const SizedBox(height: 10),
            const Text(
              "Lembretes de Hábitos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Lista de Lembretes conforme o Design
            _buildReminderTile(
              "Lembrete de Água",
              "A cada duas horas",
              Icons.water_drop,
              _agua,
              (v) => setState(() => _agua = v),
            ),
            _buildReminderTile(
              "Lembrete de Sono",
              "Ex: 23:00",
              Icons.bedtime,
              _sono,
              (v) => setState(() => _sono = v),
            ),
            _buildReminderTile(
              "Lembrete de Refeições",
              "Almoço e Jantar",
              Icons.restaurant,
              _refeicoes,
              (v) => setState(() => _refeicoes = v),
            ),
            _buildReminderTile(
              "Lembrete de Atividade",
              "Diariamente às 18:00",
              Icons.directions_run,
              _atividade,
              (v) => setState(() => _atividade = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyan),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.cyan.withValues(alpha: 0.5),
          activeThumbColor: Colors.cyan,
        ),
      ),
    );
  }
}
