import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';
import 'dart:math' as math;
import 'water_history_screen.dart';
import 'meals_history_screen.dart';
import 'sleep_history_screen.dart';
import 'activity_history_screen.dart';

class GoalsScreen extends StatefulWidget {
  final int userId;
  const GoalsScreen({super.key, required this.userId});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final int _metaAgua = 2500;
  final int _metaCalorias = 2000;
  final int _metaSono = 8;
  final int _metaAtividade = 30;

  int _totalAgua = 0;
  int _totalCalorias = 0;
  double _totalSono = 0.0;
  int _totalAtividade = 0;

  bool _isLoading = true;
  final HabitosRepository _repo = HabitosRepository.fromSupabase();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarDados();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _carregarDados();
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final agua = await _repo.obterConsumoAguaDoDia(widget.userId);
      final refeicoes = await _repo.obterRefeicoesDoDia(widget.userId);
      final sono = await _repo.obterSonoHoje(widget.userId);
      final atividades = await _repo.obterAtividadesDoDia(widget.userId);

      int totalSegundosAtividade = 0;
      for (final a in atividades) {
        final dur = a['duracao_segundos'];
        if (dur != null) {
          totalSegundosAtividade += (dur as num).toInt();
        }
      }

      if (!mounted) return;
      setState(() {
        _totalAgua = agua.totalMl;
        _totalCalorias = refeicoes.totalCalorias;
        _totalSono = sono;
        _totalAtividade = (totalSegundosAtividade / 60).round();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Objetivos', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
          onRefresh: _carregarDados,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Metas Diárias", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Acompanha o teu progresso de hoje", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _metaCardCircular("Água", _totalAgua, _metaAgua, "ml", Icons.water_drop, const Color(0xFF00BCD4), onTap: () => _abrirHistorico(WaterHistoryScreen(userId: widget.userId)))),
                    const SizedBox(width: 15),
                    Expanded(child: _metaCardCircular("Calorias", _totalCalorias, _metaCalorias, "kcal", Icons.restaurant, const Color(0xFFFF9800), onTap: () => _abrirHistorico(MealsHistoryScreen(userId: widget.userId)))),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _metaCardCircular("Sono", _totalSono.toInt(), _metaSono, "h", Icons.bedtime, const Color(0xFF673AB7), onTap: () => _abrirHistorico(SleepHistoryScreen(userId: widget.userId)))),
                    const SizedBox(width: 15),
                    Expanded(child: _metaCardCircular("Atividade", _totalAtividade, _metaAtividade, "min", Icons.directions_run, const Color(0xFF4CAF50), onTap: () => _abrirHistorico(ActivityHistoryScreen(userId: widget.userId)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirHistorico(Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => tela)).then((_) => _carregarDados());
  }

  Widget _metaCardCircular(String titulo, int atual, int meta, String unidade, IconData icon, Color cor, {VoidCallback? onTap}) {
    final progresso = (atual / meta).clamp(0.0, 1.0);
    final percentagem = (progresso * 100).round();

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 100, height: 100, child: CustomPaint(painter: _CircularProgressPainter(progresso, cor))),
              Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: cor, size: 32), const SizedBox(height: 5), Text("$percentagem%", style: TextStyle(color: cor, fontSize: 20, fontWeight: FontWeight.bold))]),
            ],
          ),
          const SizedBox(height: 15),
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("$atual/$meta $unidade", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(20), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: card));
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CircularProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final backgroundPaint = Paint()..color = Colors.grey[200]!..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);
    final progressPaint = Paint()..color = color..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}