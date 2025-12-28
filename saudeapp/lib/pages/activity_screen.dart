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
  bool _isTracking = false;
  String? _modalidadeSelecionada;
  double _distancia = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  final List<Map<String, dynamic>> _modalidades = [
    {
      'nome': 'Caminhada',
      'icon': Icons.directions_walk,
      'cor': Color(0xFF66BB6A),
      'calorias_min': 4,
    },
    {
      'nome': 'Corrida',
      'icon': Icons.directions_run,
      'cor': Color(0xFFFF7043),
      'calorias_min': 10,
    },
    {
      'nome': 'Ciclismo',
      'icon': Icons.directions_bike,
      'cor': Color(0xFF42A5F5),
      'calorias_min': 8,
    },
    {
      'nome': 'Natação',
      'icon': Icons.pool,
      'cor': Color(0xFF26C6DA),
      'calorias_min': 11,
    },
    {
      'nome': 'Yoga',
      'icon': Icons.self_improvement,
      'cor': Color(0xFFAB47BC),
      'calorias_min': 3,
    },
    {
      'nome': 'Ginásio',
      'icon': Icons.fitness_center,
      'cor': Color(0xFFEF5350),
      'calorias_min': 7,
    },
  ];

  void _toggleTracking() async {
    if (!_isTracking && _modalidadeSelecionada != null) {
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;

      setState(() {
        _isTracking = true;
        _distancia = 0.0;
        _stopwatch.start();
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() {});
      });

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen((pos) {
            if (_lastPosition != null) {
              double gap = Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                pos.latitude,
                pos.longitude,
              );
              if (gap > 2.5 && gap < 40) {
                if (mounted) setState(() => _distancia += gap);
              }
            }
            _lastPosition = pos;
          });
    } else if (_isTracking) {
      _finalizar();
    }
  }

  Future<void> _finalizar() async {
    _stopwatch.stop();
    _timer?.cancel();
    _positionStream?.cancel();

    try {
      final repo = HabitosRepository.fromSupabase();
      await repo.registarAtividade(
        userId: widget.userId,
        modalidade: _modalidadeSelecionada!,
        distancia: double.parse((_distancia / 1000).toStringAsFixed(2)),
        duracao: _stopwatch.elapsed.inSeconds,
        calorias: 0,
      );
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

  int _calcularCalorias() {
    final modalidade = _modalidades.firstWhere(
      (m) => m['nome'] == _modalidadeSelecionada,
    );
    final minutos = _stopwatch.elapsed.inMinutes;
    return (minutos * (modalidade['calorias_min'] as int)).toInt();
  }

  String _calcularRitmo() {
    if (_distancia < 100) return "--:--";
    final km = _distancia / 1000;
    final minutos = _stopwatch.elapsed.inMinutes;
    if (km == 0) return "--:--";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Atividade Física',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: _isTracking ? _buildTracking() : _buildSelection(),
    );
  }

  Widget _buildSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Escolhe a tua atividade",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Seleciona o tipo de exercício que vais fazer",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
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
              final isSelected = _modalidadeSelecionada == mod['nome'];
              return Material(
                color: isSelected ? mod['cor'] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: isSelected ? 8 : 2,
                child: InkWell(
                  onTap: () =>
                      setState(() => _modalidadeSelecionada = mod['nome']),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mod['icon'],
                        size: 50,
                        color: isSelected ? Colors.white : mod['cor'],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mod['nome'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
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
          if (_modalidadeSelecionada != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "INICIAR TREINO",
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
    );
  }

  Widget _buildTracking() {
    final corAtual =
        _modalidades.firstWhere(
              (m) => m['nome'] == _modalidadeSelecionada,
            )['cor']
            as Color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [corAtual, corAtual.withValues(alpha: 0.7)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _modalidadeSelecionada!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              (_distancia / 1000).toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "QUILÓMETROS",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDuration(_stopwatch.elapsed),
              style: const TextStyle(color: Colors.white, fontSize: 36),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCard(
                    "RITMO",
                    "${_calcularRitmo()}\nmin/km",
                    Icons.speed,
                  ),
                  _statCard(
                    "VELOCIDADE",
                    "${_calcularVelocidade()}\nkm/h",
                    Icons.flash_on,
                  ),
                  _statCard(
                    "CALORIAS",
                    "${_calcularCalorias()}\nkcal",
                    Icons.local_fire_department,
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _toggleTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "PARAR TREINO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
