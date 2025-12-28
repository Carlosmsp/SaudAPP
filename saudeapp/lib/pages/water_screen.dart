import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';

class WaterScreen extends StatefulWidget {
  final int userId;
  const WaterScreen({super.key, required this.userId});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final int _metaAgua = 2500;
  int _totalAgua = 0;
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
      final data = await _repo.obterConsumoAguaDoDia(widget.userId);
      if (!mounted) return;
      setState(() {
        _totalAgua = data.totalMl;
        _historicoIds = List<int>.from(data.registoIds);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarAgua(int ml) async {
    setState(() => _totalAgua += ml);
    try {
      final id = await _repo.registarAgua(widget.userId, ml);
      if (!mounted) return;
      setState(() => _historicoIds.add(id));
    } catch (e) {
      if (!mounted) setState(() => _totalAgua -= ml);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progresso = (_totalAgua / _metaAgua).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF0F171E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hidratação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.cyanAccent),
            onPressed: () async {
              if (_historicoIds.isNotEmpty) {
                await _repo.apagarRegistoAgua(_historicoIds.last);
                _carregarDados();
              }
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const SizedBox(height: 40),
              _buildProgressCircle(progresso),
              const SizedBox(height: 40),
              _buildQuickAdd(),
            ],
          ),
    );
  }

  Widget _buildProgressCircle(double progresso) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280, height: 280,
          child: CircularProgressIndicator(
            value: progresso,
            strokeWidth: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
        Column(
          children: [
            Text("$_totalAgua", style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w100)),
            const Text("ML CONSUMIDOS", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAdd() {
    return Wrap(
      spacing: 20,
      children: [
        _waterButton(250, "Copo"),
        _waterButton(500, "Garrafa"),
        _waterButton(750, "Garrafa XL"),
      ],
    );
  }

  Widget _waterButton(int ml, String label) {
    return ActionChip(
      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
      label: Text("$ml ml", style: const TextStyle(color: Colors.cyanAccent)),
      onPressed: () => _adicionarAgua(ml),
    );
  }
}