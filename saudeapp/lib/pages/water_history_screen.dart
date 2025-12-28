import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/habitos_repository.dart';

class WaterHistoryScreen extends StatefulWidget {
  final int userId;
  const WaterHistoryScreen({super.key, required this.userId});

  @override
  State<WaterHistoryScreen> createState() => _WaterHistoryScreenState();
}

class _WaterHistoryScreenState extends State<WaterHistoryScreen> {
  List<Map<String, dynamic>> _registos = [];
  int _totalMl = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final repo = HabitosRepository.fromSupabase();
      final registos = await repo.obterBebidasDetalhadasDoDia(widget.userId);
      
      if (mounted) {
        int total = 0;
        for (var r in registos) {
          final ml = r['quantidade_ml'];
          if (ml != null) {
            total += (ml as num).toInt();
          }
        }
        
        setState(() {
          _registos = registos;
          _totalMl = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _apagarRegisto(int idBebida, int quantidade) async {
    try {
      final repo = HabitosRepository.fromSupabase();
      await repo.apagarRegistoAgua(idBebida);
      
      await _carregarHistorico();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registo apagado!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarApagar(int idBebida, int quantidade) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Apagar registo"),
        content: Text("Apagar registo de ${quantidade}ml?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _apagarRegisto(idBebida, quantidade);
            },
            child: const Text("APAGAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Histórico de Água', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 50),
                const SizedBox(height: 10),
                const Text('Total de Hoje', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('${_totalMl}ml', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('${_registos.length} ${_registos.length == 1 ? 'registo' : 'registos'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _registos.isEmpty ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  Text('Sem registos hoje', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            ) : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _registos.length,
              itemBuilder: (context, index) {
                final registo = _registos[index];
                final quantidade = (registo['quantidade_ml'] as num?)?.toInt() ?? 0;
                final idBebida = registo['id_bebida'] as int;
                
                String hora = 'Sem hora';
                try {
                  if (registo['habitos'] != null && registo['habitos']['data_registo'] != null) {
                    final dataRegisto = registo['habitos']['data_registo'] as String;
                    final data = DateTime.parse(dataRegisto);
                    hora = DateFormat('HH:mm').format(data);
                  }
                } catch (_) {}

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: Color(0xFF00BCD4), size: 28),
                    ),
                    title: Text('${quantidade}ml', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(hora, style: TextStyle(color: Colors.grey[600])),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarApagar(idBebida, quantidade),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}