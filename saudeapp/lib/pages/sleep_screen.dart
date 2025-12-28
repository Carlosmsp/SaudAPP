import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/habitos_repository.dart';

class SleepScreen extends StatefulWidget {
  final int userId;
  const SleepScreen({super.key, required this.userId});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  bool _isSleeping = false;
  DateTime? _startTime;
  final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  void initState() {
    super.initState();
    _recuperarEstadoSono();
  }

  Future<void> _recuperarEstadoSono() async {
    final prefs = await SharedPreferences.getInstance();
    final startString = prefs.getString('sleep_start_time');

    if (startString != null && mounted) {
      setState(() {
        _isSleeping = true;
        _startTime = DateTime.parse(startString);
      });
    }
  }

  Future<void> _toggleSleep() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isSleeping) {
      final now = DateTime.now();
      await prefs.setString('sleep_start_time', now.toIso8601String());

      if (!mounted) return;
      setState(() {
        _isSleeping = true;
        _startTime = now;
      });
    } else {
      final endTime = DateTime.now();
      final difference = endTime.difference(_startTime!);
      final horasDormidas = double.parse(
        (difference.inMinutes / 60).toStringAsFixed(1),
      );

      if (horasDormidas > 0.1) {
        await _repo.registarSono(widget.userId, horasDormidas);

        // CORREÇÃO DO ERRO BuildContext
        // Guardamos o messenger antes do await ou verificamos context.mounted logo após
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registado: $horasDormidas horas de sono"),
            backgroundColor: Colors.indigoAccent,
          ),
        );
      }

      await prefs.remove('sleep_start_time');

      if (!mounted) return;
      setState(() {
        _isSleeping = false;
        _startTime = null;
      });
    }
  }

  void _registoPersonalizado() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Registo Personalizado"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Horas dormidas",
            hintText: "Ex: 7.5",
            suffixText: "horas",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
            ),
            onPressed: () async {
              final h = double.tryParse(controller.text);
              if (h != null) {
                await _repo.registarSono(widget.userId, h);

                // CORREÇÃO DO NAVIGATOR: Verifica o context do diálogo
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          "Registo de Sono",
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar, color: Colors.indigoAccent),
            onPressed: _registoPersonalizado,
            tooltip: "Registo Manual",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSleeping
                    ? Colors.indigoAccent.withValues(
                        alpha: 0.1,
                      ) // CORREÇÃO withOpacity
                    : Colors.orangeAccent.withValues(alpha: 0.1),
              ),
              child: Icon(
                _isSleeping ? Icons.nights_stay : Icons.wb_sunny,
                size: 100,
                color: _isSleeping ? Colors.indigoAccent : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _isSleeping ? "A descansar..." : "Pronto para dormir?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_isSleeping && _startTime != null)
              Text(
                "Início: ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSleeping
                    ? Colors.redAccent
                    : Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              onPressed: _toggleSleep,
              child: Text(
                _isSleeping ? "ACORDAR AGORA" : "COMEÇAR A DORMIR",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
