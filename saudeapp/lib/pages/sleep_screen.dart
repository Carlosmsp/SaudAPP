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

  Future<void> _toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isSleeping) {
      final now = DateTime.now();
      await prefs.setString('sleep_start', now.toIso8601String());
      setState(() {
        _isSleeping = true;
        _startTime = now;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      final horaAcordar = DateTime.now();
      final diff = horaAcordar.difference(_startTime!).inMinutes / 60.0;
      if (diff > 0.01) {
        try {
          await _repo.registarSonoCompleto(
            widget.userId,
            double.parse(diff.toStringAsFixed(1)),
            _startTime!,
            horaAcordar,
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
      await prefs.remove('sleep_start');
      setState(() {
        _isSleeping = false;
        _startTime = null;
      });
      if (mounted) Navigator.pop(context);
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
    final hours = DateTime.now().difference(_startTime!).inHours;
    return (hours / 1.5).floor();
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
