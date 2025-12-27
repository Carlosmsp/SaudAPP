import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ActivityScreen extends StatefulWidget {
  final int userId;
  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isTracking = false;
  // CORREÇÃO: Campo marcado como final
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _distance = 0.0;
  Position? _lastPosition;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int milliseconds) {
    var secs = milliseconds ~/ 1000;
    var hours = (secs ~/ 3600).toString().padLeft(2, '0');
    var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    var seconds = (secs % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  void _toggleTracking() async {
    if (!_isTracking) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      setState(() {
        _isTracking = true;
        _distance = 0.0;
        _stopwatch.reset();
        _stopwatch.start();
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        // CORREÇÃO DO ERRO FINAL: Usando LocationSettings em vez de desiredAccuracy
        Position currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2, // Apenas atualiza se mover 2 metros
          ),
        );

        if (_lastPosition != null) {
          double gap = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPos.latitude,
            currentPos.longitude,
          );
          if (gap > 2) {
            setState(() => _distance += gap);
          }
        }
        _lastPosition = currentPos;
      });
    } else {
      _stopwatch.stop();
      _timer?.cancel();
      setState(() => _isTracking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        title: const Text("Atividade", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(_stopwatch.elapsedMilliseconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.w100,
            ),
          ),
          const Text(
            "DURAÇÃO",
            style: TextStyle(color: Colors.white54, letterSpacing: 2),
          ),

          const SizedBox(height: 50),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CORREÇÃO: Removida interpolação desnecessária
              _metricCard((_distance / 1000).toStringAsFixed(2), "QUILÓMETROS"),
              const SizedBox(width: 40),
              // CORREÇÃO: Removida interpolação desnecessária
              _metricCard(
                (_distance > 0
                        ? (_stopwatch.elapsed.inMinutes / (_distance / 1000))
                        : 0.0)
                    .toStringAsFixed(1),
                "RITMO (min/km)",
              ),
            ],
          ),

          const SizedBox(height: 80),

          GestureDetector(
            onTap: _toggleTracking,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTracking ? Colors.redAccent : Colors.greenAccent,
                boxShadow: [
                  BoxShadow(
                    color: (_isTracking ? Colors.red : Colors.green).withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isTracking ? Icons.stop : Icons.play_arrow,
                size: 50,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
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
