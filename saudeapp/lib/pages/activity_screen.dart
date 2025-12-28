import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/habitos_repository.dart';

class ActivityScreen extends StatefulWidget {
  final int userId;
  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Estado principal
  bool _isTracking = false;                    // se está a gravar atividade
  String? _modalidadeSelecionada;             // nome da modalidade escolhida
  String? _descricaoOutraAtividade;           // texto introduzido na "Outra atividade"
  double _distancia = 0.0;                    // distância percorrida em metros
  final Stopwatch _stopwatch = Stopwatch();   // cronómetro da sessão
  Timer? _timer;                              // para refrescar o tempo no ecrã

  StreamSubscription<Position>? _positionStream; // stream do GPS
  Position? _lastPosition;                       // última posição conhecida

  /// Lista de modalidades disponíveis.
  /// 'calorias_min' é um valor aproximado de gasto calórico por minuto.
  final List<Map<String, dynamic>> _modalidades = [
    {
      'nome': 'Caminhada',
      'icon': Icons.directions_walk,
      'cor': const Color(0xFF66BB6A),
      'calorias_min': 4,
    },
    {
      'nome': 'Corrida',
      'icon': Icons.directions_run,
      'cor': const Color(0xFFFF7043),
      'calorias_min': 10,
    },
    {
      'nome': 'Ciclismo',
      'icon': Icons.directions_bike,
      'cor': const Color(0xFF42A5F5),
      'calorias_min': 8,
    },
    {
      'nome': 'Natação',
      'icon': Icons.pool,
      'cor': const Color(0xFF26C6DA),
      'calorias_min': 9,
    },
    {
      'nome': 'Subir escadas',
      'icon': Icons.stairs,
      'cor': const Color(0xFFFFCA28),
      'calorias_min': 11,
    },
    {
      'nome': 'Yoga',
      'icon': Icons.self_improvement,
      'cor': const Color(0xFFAB47BC),
      'calorias_min': 3,
    },
    {
      'nome': 'Ginásio',
      'icon': Icons.fitness_center,
      'cor': const Color(0xFFEF5350),
      'calorias_min': 7,
    },
    {
      'nome': 'Outra atividade',
      'icon': Icons.more_horiz,
      'cor': const Color(0xFF9E9E9E),
      'calorias_min': 5, // valor genérico
    },
  ];

  @override
  void dispose() {
    _pararTracking(forceStop: true);
    super.dispose();
  }

  // ----------------- CONTROLO DE LOCALIZAÇÃO -----------------

  Future<bool> _verificarPermissoesLocalizacao() async {
    bool servicosAtivos = await Geolocator.isLocationServiceEnabled();
    if (!servicosAtivos) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Serviços de localização desativados. Ativa o GPS para registar a atividade."),
        ),
      );
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Permissão de localização recusada. Não é possível registar a atividade."),
          ),
        );
        return false;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Permissão de localização permanentemente recusada. Ajusta as permissões nas definições."),
        ),
      );
      return false;
    }

    return true;
  }

  // ----------------- INICIAR / PARAR ATIVIDADE -----------------

  Future<void> _iniciarTracking() async {
    if (_modalidadeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolhe primeiro uma modalidade.")),
      );
      return;
    }

    final ok = await _verificarPermissoesLocalizacao();
    if (!ok) return;

    setState(() {
      _isTracking = true;
      _distancia = 0.0;
      _lastPosition = null;
      _stopwatch.reset();
      _stopwatch.start();
    });

    // Atualiza o cronómetro no ecrã a cada segundo.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Stream do GPS para ir somando a distância
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // só atualiza se o utilizador se mover ~5m
      ),
    ).listen((pos) {
      if (_lastPosition != null) {
        final gap = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );

        // filtros simples para evitar saltos absurdos
        if (gap > 2.5 && gap < 40) {
          if (mounted) {
            setState(() {
              _distancia += gap;
            });
          }
        }
      }
      _lastPosition = pos;
    });
  }

  Future<void> _pararTracking({bool forceStop = false}) async {
    // parar cronómetro e streams
    _stopwatch.stop();
    _timer?.cancel();
    _positionStream?.cancel();
    _positionStream = null;

    if (!forceStop && _distancia > 0 && _modalidadeSelecionada != null) {
      // Perguntar se quer guardar a atividade
      await _mostrarDialogGuardarAtividade();
    }

    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
  }

  Future<void> _mostrarDialogGuardarAtividade() async {
    final duracao = _stopwatch.elapsed;
    final km = _distancia / 1000;
    final calorias = _calcularCalorias();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Guardar atividade"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Modalidade: ${_modalidadeSelecionada ?? '---'}"),
              const SizedBox(height: 8),
              Text("Distância: ${km.toStringAsFixed(2)} km"),
              const SizedBox(height: 4),
              Text("Duração: ${_formatDuration(duracao)}"),
              const SizedBox(height: 4),
              Text("Calorias (aprox.): $calorias kcal"),
              const SizedBox(height: 8),
              Text("Ritmo médio: ${_calcularRitmo()} min/km"),
              Text("Velocidade média: ${_calcularVelocidade()} km/h"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Descartar"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final repo = HabitosRepository.fromSupabase();
                  await repo.registarAtividade(
                    userId: widget.userId,
                    modalidade: _modalidadeSelecionada!,
                    distancia: double.parse(
                        (km).toStringAsFixed(2)), // km com 2 casas
                    duracao: duracao.inSeconds,
                    calorias: calorias,
                  );
                  // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(ctx);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Atividade guardada com sucesso."),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro ao guardar atividade: $e"),
                      ),
                    );
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // ----------------- CÁLCULOS AUXILIARES -----------------

  int _calcularCalorias() {
    if (_modalidadeSelecionada == null) return 0;
    final minutos = _stopwatch.elapsed.inMinutes;
    if (minutos == 0) return 0;

    // Encontrar a modalidade escolhida: se for "Outra atividade",
    // usamos o valor genérico (5 kcal/min).
    Map<String, dynamic>? modalidade;
    for (final m in _modalidades) {
      if (_descricaoOutraAtividade != null &&
          _modalidadeSelecionada == _descricaoOutraAtividade) {
        if (m['nome'] == 'Outra atividade') {
          modalidade = m;
          break;
        }
      } else if (m['nome'] == _modalidadeSelecionada) {
        modalidade = m;
        break;
      }
    }

    if (modalidade == null) return 0;
    final kcalMin = modalidade['calorias_min'] as int;
    return (minutos * kcalMin).toInt();
  }

  String _calcularRitmo() {
    if (_distancia < 100) return "--:--";
    final km = _distancia / 1000;
    final minutos = _stopwatch.elapsed.inMinutes;
    if (km == 0 || minutos == 0) return "--:--";
    final ritmo = minutos / km;
    final min = ritmo.floor();
    final seg = ((ritmo - min) * 60).round();
    return "$min:${seg.toString().padLeft(2, '0')}";
  }

  String _calcularVelocidade() {
    if (_distancia < 100) return "0.0";
    final km = _distancia / 1000;
    final horas = _stopwatch.elapsed.inSeconds / 3600;
    if (horas == 0) return "0.0";
    return (km / horas).toStringAsFixed(1);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // ----------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    final km = _distancia / 1000;
    final ritmo = _calcularRitmo();
    final velocidade = _calcularVelocidade();
    final duracao = _stopwatch.elapsed;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Atividade Física",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cartão com resumo da sessão
            Container(
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
                  Text(
                    _isTracking ? "Sessão em curso" : "Sem sessão ativa",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isTracking ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDuration(duracao),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoChip("Distância", "${km.toStringAsFixed(2)} km"),
                      _infoChip("Ritmo", ritmo),
                      _infoChip("Veloc.", "$velocidade km/h"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _isTracking ? _pararTracking : _iniciarTracking,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? "Parar" : "Iniciar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isTracking ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Escolhe a modalidade",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1,
              ),
              itemCount: _modalidades.length,
              itemBuilder: (context, index) {
                final mod = _modalidades[index];
                final nome = mod['nome'] as String;
                final isSelected = _modalidadeSelecionada == nome ||
                    (_descricaoOutraAtividade != null &&
                        nome == 'Outra atividade' &&
                        _modalidadeSelecionada == _descricaoOutraAtividade);

                return Material(
                  color: isSelected ? mod['cor'] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: isSelected ? 8 : 2,
                  child: InkWell(
                    onTap: () async {
                      // Se for "Outra atividade", pedimos ao utilizador que indique qual
                      if (nome == 'Outra atividade') {
                        final controller = TextEditingController(
                          text: _descricaoOutraAtividade ?? '',
                        );

                        final resultado = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text("Outra atividade"),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: "Qual atividade?",
                                  hintText: "Ex.: Padel, Dança, Escalada…",
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final txt =
                                        controller.text.trim();
                                    Navigator.pop(
                                        ctx, txt.isEmpty ? null : txt);
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            );
                          },
                        );

                        if (resultado == null) return;

                        setState(() {
                          _descricaoOutraAtividade = resultado;
                          _modalidadeSelecionada = resultado;
                        });
                      } else {
                        setState(() {
                          _descricaoOutraAtividade = null;
                          _modalidadeSelecionada = nome;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          mod['icon'] as IconData,
                          size: 50,
                          color:
                              isSelected ? Colors.white : mod['cor'] as Color,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          nome == 'Outra atividade'
                              ? (_descricaoOutraAtividade ??
                                  'Outra atividade')
                              : nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
