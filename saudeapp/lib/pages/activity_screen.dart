import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityScreen extends StatefulWidget {
  final int userId;
  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isTracking = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _distance = 0.0;
  Position? _lastPosition;
  String _selectedActivity = 'Caminhada';

  final List<Map<String, dynamic>> _modalidades = [
    {
      'nome': 'Caminhada',
      'icon': Icons.directions_walk,
      'cor': Colors.greenAccent,
      'usaGPS': true,
    },
    {
      'nome': 'Corrida',
      'icon': Icons.directions_run,
      'cor': Colors.orangeAccent,
      'usaGPS': true,
    },
    {
      'nome': 'Passadeira',
      'icon': Icons.directions_run_outlined,
      'cor': Colors.blueAccent,
      'usaGPS': false,
    },
    {
      'nome': 'Ciclismo',
      'icon': Icons.directions_bike,
      'cor': Colors.yellowAccent,
      'usaGPS': true,
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTracking() async {
    if (!_isTracking) {
      // Verificar se a modalidade precisa de GPS
      bool usaGPS = _modalidades.firstWhere(
        (m) => m['nome'] == _selectedActivity,
      )['usaGPS'];

      if (usaGPS) {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      setState(() {
        _isTracking = true;
        _distance = 0.0;
        _stopwatch.reset();
        _stopwatch.start();
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (usaGPS) {
          Position currentPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          if (_lastPosition != null) {
            double gap = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              currentPos.latitude,
              currentPos.longitude,
            );
            if (gap > 2) setState(() => _distance += gap);
          }
          _lastPosition = currentPos;
        } else {
          setState(() {}); // Apenas atualiza o cronómetro para indoor
        }
      });
    } else {
      _stopActivity();
    }
  }

  Future<void> _stopActivity() async {
    _stopwatch.stop();
    _timer?.cancel();

    try {
      final supabase = Supabase.instance.client;

      // Gravação segura na tabela 'atividades'
      await supabase.from('atividades').insert({
        'id_utilizador': widget.userId,
        'tipo_atividade': _selectedActivity,
        'distancia_km': double.parse((_distance / 1000).toStringAsFixed(2)),
        'duracao_segundos': _stopwatch.elapsed.inSeconds,
        'ritmo_medio': _calculatePace(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Atividade Guardada!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // CORREÇÃO DO ERRO: Usamos o SnackBar em vez de print()
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isTracking = false;
      _lastPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        title: Text(
          _isTracking ? _selectedActivity : "Selecionar Atividade",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isTracking
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          if (!_isTracking) _buildSelector(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_stopwatch.elapsedMilliseconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 70,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                const Text(
                  "DURAÇÃO",
                  style: TextStyle(color: Colors.white54, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _metricCard((_distance / 1000).toStringAsFixed(2), "KM"),
                    const SizedBox(width: 40),
                    _metricCard(_calculatePace(), "RITMO"),
                  ],
                ),
              ],
            ),
          ),
          _buildActionButton(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _modalidades.length,
        itemBuilder: (context, index) {
          bool isSel = _selectedActivity == _modalidades[index]['nome'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedActivity = _modalidades[index]['nome']),
            child: Container(
              width: 100,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSel ? _modalidades[index]['cor'] : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modalidades[index]['icon'],
                    color: isSel ? Colors.black : Colors.white,
                  ),
                  Text(
                    _modalidades[index]['nome'],
                    style: TextStyle(
                      color: isSel ? Colors.black : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _toggleTracking,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isTracking ? Colors.redAccent : Colors.greenAccent,
          boxShadow: [
            BoxShadow(
              color: (_isTracking ? Colors.red : Colors.green).withValues(
                alpha: 0.3,
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: Icon(_isTracking ? Icons.stop : Icons.play_arrow, size: 50),
      ),
    );
  }

  String _formatTime(int ms) {
    var secs = ms ~/ 1000;
    return "${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}";
  }

  String _calculatePace() {
    if (_distance == 0) return "0.0";
    double km = _distance / 1000;
    return (_stopwatch.elapsed.inMinutes / km).toStringAsFixed(1);
  }

  Widget _metricCard(String val, String label) => Column(
    children: [
      Text(
        val,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ],
  );
}
