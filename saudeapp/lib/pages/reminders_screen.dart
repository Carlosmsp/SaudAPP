import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  final int userId;
  const RemindersScreen({super.key, required this.userId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notif = NotificationService();

  // Estados dos Lembretes - Água
  bool _aguaAtivo = false;
  int _intervaloAguaMin = 60;
  String _descAgua = "Bebe um copo de água.";

  // Estados dos Lembretes - Sono
  bool _sonoAtivo = false;
  TimeOfDay _horaSono = const TimeOfDay(hour: 23, minute: 0);
  String _descSono = "Hora de começar a preparar o sono.";

  // Estados dos Lembretes - Refeições
  bool _refeicoesAtivo = false;
  TimeOfDay _horaPeqAlmoco = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaAlmoco = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _horaLanche = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _horaJantar = const TimeOfDay(hour: 20, minute: 0);
  String _descRefeicoes = "Lembra-te de fazer refeições equilibradas.";

  // Estados dos Lembretes - Atividade
  bool _atividadeAtivo = false;
  TimeOfDay _horaAtividade = const TimeOfDay(hour: 18, minute: 0);
  String _descAtividade = "Levanta-te e mexe o corpo!";

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    await _notif.initialize();
    await _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aguaAtivo = prefs.getBool('agua_ativo') ?? false;
      _intervaloAguaMin = prefs.getInt('agua_intervalo') ?? 60;
      _descAgua = prefs.getString('agua_desc') ?? "Bebe um copo de água.";

      _sonoAtivo = prefs.getBool('sono_ativo') ?? false;
      _horaSono = TimeOfDay(
        hour: prefs.getInt('sono_hora') ?? 23,
        minute: prefs.getInt('sono_min') ?? 0,
      );
      _descSono =
          prefs.getString('sono_desc') ?? "Hora de começar a preparar o sono.";

      _refeicoesAtivo = prefs.getBool('refeicoes_ativo') ?? false;
      _horaPeqAlmoco = TimeOfDay(
        hour: prefs.getInt('peq_hora') ?? 8,
        minute: prefs.getInt('peq_min') ?? 0,
      );
      _horaAlmoco = TimeOfDay(
        hour: prefs.getInt('almoco_hora') ?? 13,
        minute: prefs.getInt('almoco_min') ?? 0,
      );
      _horaLanche = TimeOfDay(
        hour: prefs.getInt('lanche_hora') ?? 17,
        minute: prefs.getInt('lanche_min') ?? 0,
      );
      _horaJantar = TimeOfDay(
        hour: prefs.getInt('jantar_hora') ?? 20,
        minute: prefs.getInt('jantar_min') ?? 0,
      );
      _descRefeicoes =
          prefs.getString('refeicoes_desc') ??
          "Lembra-te de fazer refeições equilibradas.";

      _atividadeAtivo = prefs.getBool('atividade_ativo') ?? false;
      _horaAtividade = TimeOfDay(
        hour: prefs.getInt('atividade_hora') ?? 18,
        minute: prefs.getInt('atividade_min') ?? 0,
      );
      _descAtividade =
          prefs.getString('atividade_desc') ?? "Levanta-te e mexe o corpo!";
    });
  }

  Future<void> _guardarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agua_ativo', _aguaAtivo);
    await prefs.setInt('agua_intervalo', _intervaloAguaMin);
    await prefs.setString('agua_desc', _descAgua);

    await prefs.setBool('sono_ativo', _sonoAtivo);
    await prefs.setInt('sono_hora', _horaSono.hour);
    await prefs.setInt('sono_min', _horaSono.minute);
    await prefs.setString('sono_desc', _descSono);

    await prefs.setBool('refeicoes_ativo', _refeicoesAtivo);
    await prefs.setInt('peq_hora', _horaPeqAlmoco.hour);
    await prefs.setInt('peq_min', _horaPeqAlmoco.minute);
    await prefs.setInt('almoco_hora', _horaAlmoco.hour);
    await prefs.setInt('almoco_min', _horaAlmoco.minute);
    await prefs.setInt('lanche_hora', _horaLanche.hour);
    await prefs.setInt('lanche_min', _horaLanche.minute);
    await prefs.setInt('jantar_hora', _horaJantar.hour);
    await prefs.setInt('jantar_min', _horaJantar.minute);
    await prefs.setString('refeicoes_desc', _descRefeicoes);

    await prefs.setBool('atividade_ativo', _atividadeAtivo);
    await prefs.setInt('atividade_hora', _horaAtividade.hour);
    await prefs.setInt('atividade_min', _horaAtividade.minute);
    await prefs.setString('atividade_desc', _descAtividade);
  }

  Future<void> _atualizarNotificacoes() async {
    await _guardarConfiguracoes();

    if (_aguaAtivo) {
      await _notif.agendarAguaPeriodica(_intervaloAguaMin, _descAgua);
    } else {
      await _notif.cancelarNotificacao(1);
    }

    if (_sonoAtivo) {
      await _notif.agendarNotificacao(
        id: 10,
        titulo: '🛏️ Sono',
        corpo: _descSono,
        hora: _horaSono,
        channelId: 'sono_channel',
        channelName: 'Lembretes de Sono',
      );
    } else {
      await _notif.cancelarNotificacao(10);
    }

    if (_refeicoesAtivo) {
      final refeicoes = [
        {'id': 20, 'titulo': '🍳 Pequeno-almoço', 'hora': _horaPeqAlmoco},
        {'id': 21, 'titulo': '🍽️ Almoço', 'hora': _horaAlmoco},
        {'id': 22, 'titulo': '🍪 Lanche', 'hora': _horaLanche},
        {'id': 23, 'titulo': '🍲 Jantar', 'hora': _horaJantar},
      ];
      for (var r in refeicoes) {
        await _notif.agendarNotificacao(
          id: r['id'] as int,
          titulo: r['titulo'] as String,
          corpo: _descRefeicoes,
          hora: r['hora'] as TimeOfDay,
          channelId: 'refeicoes_channel',
          channelName: 'Lembretes de Refeições',
        );
      }
    } else {
      for (int i = 20; i <= 23; i++) {
        await _notif.cancelarNotificacao(i);
      }
    }

    if (_atividadeAtivo) {
      await _notif.agendarNotificacao(
        id: 30,
        titulo: '🏃 Atividade Física',
        corpo: _descAtividade,
        hora: _horaAtividade,
        channelId: 'atividade_channel',
        channelName: 'Lembretes de Atividade',
      );
    } else {
      await _notif.cancelarNotificacao(30);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lembretes configurados com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Lembretes",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCardAgua(),
          _buildReminderCardHorario(
            titulo: "Sono",
            descricao: _descSono,
            hora: _horaSono,
            ativo: _sonoAtivo,
            cor: Colors.indigo,
            icon: Icons.bed,
            onChangedAtivo: (v) => setState(() => _sonoAtivo = v),
            onEditar: () => _editarLembreteHorario(
              tipo: "Sono",
              horaAtual: _horaSono,
              descricaoAtual: _descSono,
              onGuardar: (h, d) => setState(() {
                _horaSono = h;
                _descSono = d;
              }),
            ),
          ),
          _buildCardRefeicoes(),
          _buildReminderCardHorario(
            titulo: "Atividade Física",
            descricao: _descAtividade,
            hora: _horaAtividade,
            ativo: _atividadeAtivo,
            cor: Colors.green,
            icon: Icons.directions_run,
            onChangedAtivo: (v) => setState(() => _atividadeAtivo = v),
            onEditar: () => _editarLembreteHorario(
              tipo: "Atividade Física",
              horaAtual: _horaAtividade,
              descricaoAtual: _descAtividade,
              onGuardar: (h, d) => setState(() {
                _horaAtividade = h;
                _descAtividade = d;
              }),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _atualizarNotificacoes,
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'GUARDAR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- MÉTODOS DE UI ---

  Widget _buildCardAgua() {
    final intervaloTexto = "A cada $_intervaloAguaMin min";
    return InkWell(
      onTap: _editarLembreteAgua,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _aguaAtivo
                ? Colors.blue.withValues(alpha: 0.5)
                : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Água",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _descAgua,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    intervaloTexto,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _aguaAtivo,
              onChanged: (v) => setState(() => _aguaAtivo = v),
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarLembreteAgua() async {
    int intervaloTemp = _intervaloAguaMin;
    final controller = TextEditingController(text: _descAgua);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Configurar Água",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [30, 45, 60, 90, 120].map((m) {
                      return ChoiceChip(
                        label: Text("$m min"),
                        selected: intervaloTemp == m,
                        onSelected: (_) =>
                            setModalState(() => intervaloTemp = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Mensagem",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      setState(() {
                        _intervaloAguaMin = intervaloTemp;
                        _descAgua = controller.text;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderCardHorario({
    required String titulo,
    required String descricao,
    required TimeOfDay hora,
    required bool ativo,
    required Color cor,
    required IconData icon,
    required ValueChanged<bool> onChangedAtivo,
    required VoidCallback onEditar,
  }) {
    final horaStr =
        "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
    return InkWell(
      onTap: onEditar,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: ativo ? cor.withValues(alpha: 0.5) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    descricao,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    horaStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: ativo,
              onChanged: onChangedAtivo,
              activeThumbColor: cor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarLembreteHorario({
    required String tipo,
    required TimeOfDay horaAtual,
    required String descricaoAtual,
    required Function(TimeOfDay, String) onGuardar,
  }) async {
    TimeOfDay horaSel = horaAtual;
    final controller = TextEditingController(text: descricaoAtual);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tipo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text("Hora: ${horaSel.format(context)}"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: horaSel,
                      );
                      if (p != null) setModalState(() => horaSel = p);
                    },
                  ),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Mensagem",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      onGuardar(horaSel, controller.text);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardRefeicoes() {
    String format(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    final resumoHorarios =
        "Peq ${format(_horaPeqAlmoco)} • Alm ${format(_horaAlmoco)} • Lan ${format(_horaLanche)} • Jan ${format(_horaJantar)}";

    return InkWell(
      onTap: _editarRefeicoes,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _refeicoesAtivo
                ? Colors.orange.withValues(alpha: 0.5)
                : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Refeições",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _descRefeicoes,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resumoHorarios,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _refeicoesAtivo,
              onChanged: (v) => setState(() => _refeicoesAtivo = v),
              activeThumbColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarRefeicoes() async {
    TimeOfDay pTemp = _horaPeqAlmoco;
    TimeOfDay aTemp = _horaAlmoco;
    TimeOfDay lTemp = _horaLanche;
    TimeOfDay jTemp = _horaJantar;
    final controller = TextEditingController(text: _descRefeicoes);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Configurar Refeições",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeTile(
                    ctx,
                    "Pequeno-almoço",
                    pTemp,
                    (t) => setModalState(() => pTemp = t),
                  ),
                  _buildTimeTile(
                    ctx,
                    "Almoço",
                    aTemp,
                    (t) => setModalState(() => aTemp = t),
                  ),
                  _buildTimeTile(
                    ctx,
                    "Lanche",
                    lTemp,
                    (t) => setModalState(() => lTemp = t),
                  ),
                  _buildTimeTile(
                    ctx,
                    "Jantar",
                    jTemp,
                    (t) => setModalState(() => jTemp = t),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Mensagem",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      setState(() {
                        _horaPeqAlmoco = pTemp;
                        _horaAlmoco = aTemp;
                        _horaLanche = lTemp;
                        _horaJantar = jTemp;
                        _descRefeicoes = controller.text;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeTile(
    BuildContext ctx,
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onPick,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        time.format(ctx),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
      ),
      onTap: () async {
        final p = await showTimePicker(context: ctx, initialTime: time);
        if (p != null) onPick(p);
      },
    );
  }
}
