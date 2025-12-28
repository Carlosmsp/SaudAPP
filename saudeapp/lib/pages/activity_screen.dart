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
  String _modalidade = 'Caminhada';
  double _distancia = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  void _toggleTracking() async {
    if (!_isTracking) {
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;

      setState(() {
        _isTracking = true;
        _distancia = 0.0;
        _stopwatch.start();
      });

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (t) => setState(() {}),
      );

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
              if (gap > 2.5 && gap < 40) setState(() => _distancia += gap);
            }
            _lastPosition = pos;
          });
    } else {
      _finalizar();
    }
  }

  Future<void> _finalizar() async {
    _stopwatch.stop();
    _timer?.cancel();
    _positionStream?.cancel();

    final repo = HabitosRepository.fromSupabase();
    await repo.registarAtividade(
      userId: widget.userId,
      modalidade: _modalidade,
      distancia: double.parse((_distancia / 1000).toStringAsFixed(2)),
      duracao: _stopwatch.elapsed.inMinutes,
      calorias: (_stopwatch.elapsed.inMinutes * 7).toInt(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Treino GPS"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (!_isTracking) _buildSelector(),
          const Spacer(),
          Text(
            "${(_distancia / 1000).toStringAsFixed(2)} KM",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatDuration(_stopwatch.elapsed),
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 30),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleTracking,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: _isTracking
                  ? Colors.redAccent
                  : Colors.cyanAccent,
              child: Icon(
                _isTracking ? Icons.stop : Icons.play_arrow,
                size: 50,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ['Caminhada', 'Corrida', 'Ciclismo'].map((m) {
        bool isSel = _modalidade == m;
        return ActionChip(
          label: Text(m),
          backgroundColor: isSel ? Colors.cyanAccent : Colors.white10,
          onPressed: () => setState(() => _modalidade = m),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}
