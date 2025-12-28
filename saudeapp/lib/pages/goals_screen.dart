import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';
import 'dart:math' as math;

class GoalsScreen extends StatefulWidget {
  final int userId;
  const GoalsScreen({super.key, required this.userId});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
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
        if (dur != null) totalSegundosAtividade += (dur as num).toInt();
      }

      if (!mounted) return;
      setState(() {
        _totalAgua = agua.totalMl;
        _totalCalorias = refeicoes.totalCalorias;
        _totalSono = sono;
        _totalAtividade = (totalSegundosAtividade / 60).round();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- DETALHES: ÁGUA ----------

  Future<void> _mostrarDetalhesAgua() async {
    try {
      final lista = await _repo.obterBebidasDetalhadasDoDia(widget.userId);
      if (!mounted) return;

      final progresso = (_totalAgua / _metaAgua).clamp(0.0, 1.0);
      final percentagem = (progresso * 100).round();
      final falta = _metaAgua - _totalAgua;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerObjetivo(
                  titulo: "Água",
                  atual: _totalAgua,
                  meta: _metaAgua,
                  unidade: "ml",
                  percentagem: percentagem,
                  icone: Icons.water_drop,
                  cor: const Color(0xFF00BCD4),
                ),
                const SizedBox(height: 12),
                _barraProgresso(progresso, const Color(0xFF00BCD4)),
                const SizedBox(height: 10),
                Text(
                  falta > 0
                      ? "Faltam ${falta.abs()} ml para a meta de hoje."
                      : "Meta de hidratação atingida! 💧",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Registos de hoje:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  const Text(
                    "Ainda não registaste consumo de água hoje.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = lista[index];
                        final ml = e['quantidade_ml'] as int;
                        final tipo = (e['tipo_bebida'] as String?) ?? 'Água';

                        DateTime? data;
                        try {
                          final hab = e['habitos'] as Map?;
                          if (hab != null && hab['data_registo'] != null) {
                            data =
                                DateTime.parse(hab['data_registo'] as String);
                          }
                        } catch (_) {}

                        final horaStr = data == null
                            ? "--:--"
                            : "${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";

                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.local_drink),
                          title: Text("$ml ml ($tipo)"),
                          subtitle: Text("Registado às $horaStr"),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  // ---------- DETALHES: CALORIAS ----------

  Future<void> _mostrarDetalhesCalorias() async {
    try {
      final lista =
          await _repo.obterRefeicoesDetalhadasDoDia(widget.userId);
      if (!mounted) return;

      final progresso =
          (_totalCalorias / _metaCalorias).clamp(0.0, 1.0);
      final percentagem = (progresso * 100).round();
      final falta = _metaCalorias - _totalCalorias;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerObjetivo(
                  titulo: "Calorias",
                  atual: _totalCalorias,
                  meta: _metaCalorias,
                  unidade: "kcal",
                  percentagem: percentagem,
                  icone: Icons.restaurant,
                  cor: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),
                _barraProgresso(progresso, const Color(0xFFFF9800)),
                const SizedBox(height: 10),
                Text(
                  falta > 0
                      ? "Ainda podes consumir cerca de ${falta.abs()} kcal dentro da meta."
                      : "Já ultrapassaste a meta diária de calorias.",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Refeições de hoje:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  const Text(
                    "Ainda não registaste refeições hoje.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = lista[index];
                        final tipo =
                            e['tipo_refeicao'] as String? ?? 'Refeição';
                        final kcal = e['calorias_kcal'] as int? ?? 0;

                        DateTime? data;
                        try {
                          final hab = e['habitos'] as Map?;
                          if (hab != null && hab['data_registo'] != null) {
                            data =
                                DateTime.parse(hab['data_registo'] as String);
                          }
                        } catch (_) {}

                        final horaStr = data == null
                            ? "--:--"
                            : "${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";

                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.fastfood),
                          title: Text("$tipo • $kcal kcal"),
                          subtitle: Text("Registado às $horaStr"),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  // ---------- DETALHES: SONO ----------

  Future<void> _mostrarDetalhesSono() async {
    try {
      final lista =
          await _repo.obterSonoDetalhadoDoDia(widget.userId);
      if (!mounted) return;

      final progresso = (_totalSono / _metaSono).clamp(0.0, 1.0);
      final percentagem = (progresso * 100).round();
      final falta = _metaSono - _totalSono;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerObjetivo(
                  titulo: "Sono",
                  atual: _totalSono.toInt(),
                  meta: _metaSono,
                  unidade: "h",
                  percentagem: percentagem,
                  icone: Icons.bedtime,
                  cor: const Color(0xFF673AB7),
                ),
                const SizedBox(height: 12),
                _barraProgresso(progresso, const Color(0xFF673AB7)),
                const SizedBox(height: 10),
                Text(
                  falta > 0
                      ? "Faltam aproximadamente ${falta.toStringAsFixed(1)} h para a meta de sono."
                      : "Meta de sono atingida ou ultrapassada.",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Registos de hoje:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  const Text(
                    "Ainda não registaste sono hoje.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = lista[index];
                        final horas =
                            (e['horas_dormidas'] as num?)?.toDouble() ?? 0.0;
                        final qualidade = e['qualidade'] as int? ?? 0;

                        DateTime? deitar;
                        DateTime? acordar;
                        try {
                          if (e['hora_deitar'] != null) {
                            deitar =
                                DateTime.parse(e['hora_deitar'] as String);
                          }
                          if (e['hora_acordar'] != null) {
                            acordar =
                                DateTime.parse(e['hora_acordar'] as String);
                          }
                        } catch (_) {}

                        String faixaQualidade;
                        switch (qualidade) {
                          case 1:
                            faixaQualidade = "Muito fraco";
                            break;
                          case 2:
                            faixaQualidade = "Fraco";
                            break;
                          case 3:
                            faixaQualidade = "Normal";
                            break;
                          case 4:
                            faixaQualidade = "Bom";
                            break;
                          case 5:
                            faixaQualidade = "Excelente";
                            break;
                          default:
                            faixaQualidade = "Sem info";
                        }

                        String periodo = "";
                        if (deitar != null && acordar != null) {
                          periodo =
                              "${_fmtHora(deitar)} → ${_fmtHora(acordar)}";
                        }

                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.nightlight_round),
                          title:
                              Text("${horas.toStringAsFixed(1)} h de sono"),
                          subtitle: Text(
                            [
                              if (periodo.isNotEmpty) periodo,
                              "Qualidade: $faixaQualidade",
                            ].join(" • "),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  // ---------- DETALHES: ATIVIDADE ----------

  Future<void> _mostrarDetalhesAtividade() async {
    try {
      final lista =
          await _repo.obterAtividadesDoDia(widget.userId);
      if (!mounted) return;

      final progresso =
          (_totalAtividade / _metaAtividade).clamp(0.0, 1.0);
      final percentagem = (progresso * 100).round();
      final falta = _metaAtividade - _totalAtividade;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerObjetivo(
                  titulo: "Atividade física",
                  atual: _totalAtividade,
                  meta: _metaAtividade,
                  unidade: "min",
                  percentagem: percentagem,
                  icone: Icons.directions_run,
                  cor: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 12),
                _barraProgresso(progresso, const Color(0xFF4CAF50)),
                const SizedBox(height: 10),
                Text(
                  falta > 0
                      ? "Faltam cerca de ${falta.abs()} min para a meta."
                      : "Meta diária de atividade atingida! 💪",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Atividades de hoje:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  const Text(
                    "Ainda não registaste atividades hoje.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = lista[index];
                        final tipo =
                            e['tipo_atividade'] as String? ?? 'Atividade';
                        final distKm =
                            (e['distancia_km'] as num?)?.toDouble() ?? 0.0;
                        final durSeg =
                            (e['duracao_segundos'] as num?)?.toInt() ?? 0;

                        final duracao = Duration(seconds: durSeg);
                        final minutos = duracao.inMinutes;
                        final segundos = duracao.inSeconds % 60;

                        final tempoStr =
                            "${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}";

                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.directions_run),
                          title: Text(tipo),
                          subtitle: Text(
                            "Duração: $tempoStr • Distância: ${distKm.toStringAsFixed(2)} km",
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  // ---------- HELPERS ----------

  Widget _headerObjetivo({
    required String titulo,
    required int atual,
    required int meta,
    required String unidade,
    required int percentagem,
    required IconData icone,
    required Color cor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: cor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: cor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$atual / $meta $unidade  •  $percentagem%",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _barraProgresso(double valor, Color cor) {
    return LinearProgressIndicator(
      value: valor,
      minHeight: 8,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(cor),
    );
  }

  String _fmtHora(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Objetivos',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Metas Diárias",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Acompanha o teu progresso de hoje",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _metaCardCircular(
                            "Água",
                            _totalAgua,
                            _metaAgua,
                            "ml",
                            Icons.water_drop,
                            const Color(0xFF00BCD4),
                            onTap: _mostrarDetalhesAgua,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _metaCardCircular(
                            "Calorias",
                            _totalCalorias,
                            _metaCalorias,
                            "kcal",
                            Icons.restaurant,
                            const Color(0xFFFF9800),
                            onTap: _mostrarDetalhesCalorias,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _metaCardCircular(
                            "Sono",
                            _totalSono.toInt(),
                            _metaSono,
                            "h",
                            Icons.bedtime,
                            const Color(0xFF673AB7),
                            onTap: _mostrarDetalhesSono,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _metaCardCircular(
                            "Atividade",
                            _totalAtividade,
                            _metaAtividade,
                            "min",
                            Icons.directions_run,
                            const Color(0xFF4CAF50),
                            onTap: _mostrarDetalhesAtividade,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metaCardCircular(
    String titulo,
    int atual,
    int meta,
    String unidade,
    IconData icon,
    Color cor, {
    VoidCallback? onTap,
  }) {
    final progresso = (atual / meta).clamp(0.0, 1.0);
    final percentagem = (progresso * 100).round();

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _CircularProgressPainter(progresso, cor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: cor, size: 32),
                  const SizedBox(height: 5),
                  Text(
                    "$percentagem%",
                    style: TextStyle(
                      color: cor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$atual/$meta $unidade",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
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

    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
