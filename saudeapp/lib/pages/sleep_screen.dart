import 'dart:async';
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
  Timer? _timer;
  final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  void initState() {
    super.initState();
    _recuperar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _recuperar() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getString('sleep_start');
    if (start != null && mounted) {
      setState(() {
        _isSleeping = true;
        _startTime = DateTime.parse(start);
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _acordar() async {
    _timer?.cancel();
    final horaAcordar = DateTime.now();
    final diffMinutos = horaAcordar.difference(_startTime!).inMinutes;
    final horas = diffMinutos / 60.0;
    final ciclos = _getCiclos();

    if (mounted) {
      final qualidade = await _mostrarResumo(horas, ciclos);
      if (qualidade != null) {
        try {
          await _repo.registarSonoComQualidade(
            widget.userId,
            double.parse(horas.toStringAsFixed(2)),
            _startTime!,
            horaAcordar,
            qualidade,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sleep_start');
          if (mounted) Navigator.pop(context);
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
    }
  }

  Future<int?> _mostrarResumo(double horas, int ciclos) async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SleepSummaryDialog(horas: horas, ciclos: ciclos),
    );
  }

  Future<void> _toggle() async {
    if (!_isSleeping) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('sleep_start', now.toIso8601String());
      setState(() {
        _isSleeping = true;
        _startTime = now;
      });
      _startTimer();
    } else {
      await _acordar();
    }
  }

  String _getElapsedTime() {
    if (!_isSleeping || _startTime == null) return "0h 0m";
    final diff = DateTime.now().difference(_startTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  int _getCiclos() {
    if (!_isSleeping || _startTime == null) return 0;
    final minutos = DateTime.now().difference(_startTime!).inMinutes;
    return (minutos / 90).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sono', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSleeping ? Icons.bedtime : Icons.wb_sunny,
              size: 80,
              color: _isSleeping ? Colors.deepPurpleAccent : Colors.amber,
            ),
            const SizedBox(height: 30),
            if (_isSleeping) ...[
              Text(
                _getElapsedTime(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${_getCiclos()} ciclos de sono",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              _buildCycles(_getCiclos()),
            ] else ...[
              const Text(
                "Pronto para dormir?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Um ciclo de sono dura ~90 minutos",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _toggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSleeping
                    ? Colors.red
                    : Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _isSleeping ? "ACORDAR" : "COMEÇAR A DORMIR",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycles(int count) {
    return Wrap(
      spacing: 8,
      children: List.generate(
        8,
        (i) => Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: i < count
                ? Colors.deepPurpleAccent
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.nights_stay,
              size: 18,
              color: i < count ? Colors.white : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepSummaryDialog extends StatefulWidget {
  final double horas;
  final int ciclos;

  const _SleepSummaryDialog({required this.horas, required this.ciclos});

  @override
  State<_SleepSummaryDialog> createState() => _SleepSummaryDialogState();
}

class _SleepSummaryDialogState extends State<_SleepSummaryDialog> {
  int _qualidade = 3;

  String _getAnalise() {
    if (widget.horas < 4) return "Sono insuficiente";
    if (widget.horas < 6) return "Sono curto";
    if (widget.horas < 8) return "Bom descanso";
    if (widget.horas < 10) return "Excelente sono";
    return "Muito tempo na cama";
  }

  IconData _getIcone() {
    if (widget.horas < 4) return Icons.sentiment_dissatisfied;
    if (widget.horas < 6) return Icons.sentiment_neutral;
    if (widget.horas < 10) return Icons.sentiment_satisfied;
    return Icons.sentiment_very_satisfied;
  }

  Color _getCor() {
    if (widget.horas < 4) return Colors.red;
    if (widget.horas < 6) return Colors.orange;
    if (widget.horas < 10) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF1A1F33)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcone(), size: 70, color: _getCor()),
            const SizedBox(height: 15),
            const Text(
              "Bom dia!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem(
                        "Tempo",
                        "${widget.horas.toStringAsFixed(1)}h",
                        Icons.access_time,
                      ),
                      _statItem(
                        "Ciclos",
                        "${widget.ciclos}",
                        Icons.nights_stay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _getAnalise(),
                    style: TextStyle(
                      color: _getCor(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Como foi a qualidade do sono?",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _qualidade ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _qualidade = i + 1),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _qualidade),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "GUARDAR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
