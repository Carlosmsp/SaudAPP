import 'package:flutter/material.dart';

/// Ecrã de configuração de Lembretes.
/// Neste momento as definições ficam apenas em memória.
/// Mais tarde podemos persistir em Supabase ou SharedPreferences
/// e ligar a notificações locais.
class RemindersScreen extends StatefulWidget {
  final int userId;

  const RemindersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // ------------------------------
  //     ESTADO – ÁGUA
  // ------------------------------

  /// Se o lembrete de água está ativo ou não.
  bool _aguaAtivo = true;

  /// Intervalo entre lembretes de água em minutos.
  /// Ex.: 30 = a cada 30 minutos, 60 = de hora a hora.
  int _intervaloAguaMin = 60;

  /// Texto da mensagem para o lembrete de água.
  String _descAgua = "Bebe um copo de água.";

  // ------------------------------
  //     ESTADO – SONO
  // ------------------------------

  bool _sonoAtivo = false;
  TimeOfDay _horaSono = const TimeOfDay(hour: 23, minute: 0);
  String _descSono = "Hora de começar a preparar o sono.";

  // ------------------------------
  //     ESTADO – REFEIÇÕES
  // ------------------------------

  bool _refeicoesAtivo = true;

  TimeOfDay _horaPeqAlmoco = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaAlmoco = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _horaLanche = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _horaJantar = const TimeOfDay(hour: 20, minute: 0);

  String _descRefeicoes = "Lembra-te de fazer refeições equilibradas.";

  // ------------------------------
  //     ESTADO – ATIVIDADE
  // ------------------------------

  bool _atividadeAtivo = false;
  TimeOfDay _horaAtividade = const TimeOfDay(hour: 18, minute: 0);
  String _descAtividade = "Levanta-te e mexe o corpo!";

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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "PERSONALIZAÇÃO",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Toca em qualquer lembrete para alterar a mensagem e a hora/intervalo.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // ---------- CARTÃO ÁGUA ----------
          _buildCardAgua(),

          // ---------- CARTÃO SONO ----------
          _buildReminderCardHorario(
            titulo: "Sono",
            descricao: _descSono,
            hora: _horaSono,
            ativo: _sonoAtivo,
            cor: Colors.indigo,
            icon: Icons.bed,
            onChangedAtivo: (valor) {
              setState(() => _sonoAtivo = valor);
            },
            onEditar: () => _editarLembreteHorario(
              tipo: "Sono",
              ativo: _sonoAtivo,
              horaAtual: _horaSono,
              descricaoAtual: _descSono,
              onGuardar: (h, d) {
                setState(() {
                  _horaSono = h;
                  _descSono = d;
                });
              },
            ),
          ),

          // ---------- CARTÃO REFEIÇÕES ----------
          _buildCardRefeicoes(),

          // ---------- CARTÃO ATIVIDADE ----------
          _buildReminderCardHorario(
            titulo: "Atividade Física",
            descricao: _descAtividade,
            hora: _horaAtividade,
            ativo: _atividadeAtivo,
            cor: Colors.green,
            icon: Icons.directions_run,
            onChangedAtivo: (valor) {
              setState(() => _atividadeAtivo = valor);
            },
            onEditar: () => _editarLembreteHorario(
              tipo: "Atividade Física",
              ativo: _atividadeAtivo,
              horaAtual: _horaAtividade,
              descricaoAtual: _descAtividade,
              onGuardar: (h, d) {
                setState(() {
                  _horaAtividade = h;
                  _descAtividade = d;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  //                      CARTÃO – ÁGUA (INTERVALO)
  // ===================================================================

  /// Constrói o cartão específico para o lembrete de água.
  /// Aqui mostramos o intervalo (em minutos) em vez de uma hora fixa.
  Widget _buildCardAgua() {
    final intervaloTexto = _intervaloAguaMin == 30
        ? "a cada 30 minutos"
        : _intervaloAguaMin == 45
            ? "a cada 45 minutos"
            : _intervaloAguaMin == 60
                ? "de hora a hora"
                : "a cada $_intervaloAguaMin minutos";

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descAgua,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        intervaloTexto,
                        style: TextStyle(
                          fontSize: 13,
                          color: _aguaAtivo ? Colors.blue : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: _aguaAtivo,
              onChanged: (valor) {
                setState(() => _aguaAtivo = valor);
              },
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra um painel onde o utilizador pode:
  /// - escolher o intervalo (30, 45, 60, 90, 120 minutos)
  /// - alterar a mensagem do lembrete de água
  Future<void> _editarLembreteAgua() async {
    // valores temporários enquanto o utilizador edita
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                "Configurar lembrete – Água",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Intervalo entre lembretes:",
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Escolha rápida de intervalos com ChoiceChips
              Wrap(
                spacing: 10,
                children: [
                  for (final minutos in [30, 45, 60, 90, 120])
                    ChoiceChip(
                      label: Text("$minutos min"),
                      selected: intervaloTemp == minutos,
                      onSelected: (_) {
                        setState(() {}); // força rebuild do sheet
                        intervaloTemp = minutos;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Mensagem do lembrete",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _intervaloAguaMin = intervaloTemp;
                      _descAgua = controller.text.trim().isEmpty
                          ? _descAgua
                          : controller.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "GUARDAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================================================================
  //                CARTÃO – SONO / ATIVIDADE (HORA ÚNICA)
  // ===================================================================

  /// Cartão genérico para lembretes que usam uma única hora (Sono, Atividade).
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        horaStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: ativo ? cor : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

  /// Editor genérico com escolha de hora + descrição.
  Future<void> _editarLembreteHorario({
    required String tipo,
    required bool ativo,
    required TimeOfDay horaAtual,
    required String descricaoAtual,
    required void Function(TimeOfDay novaHora, String novaDescricao) onGuardar,
  }) async {
    TimeOfDay horaSelecionada =
        TimeOfDay(hour: horaAtual.hour, minute: horaAtual.minute);
    final controller = TextEditingController(text: descricaoAtual);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                "Configurar lembrete – $tipo",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    "Hora atual: "
                    "${horaSelecionada.hour.toString().padLeft(2, '0')}:"
                    "${horaSelecionada.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: horaSelecionada,
                      );
                      if (picked != null) {
                        horaSelecionada = picked;
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                    child: const Text("ALTERAR"),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Mensagem do lembrete",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onGuardar(horaSelecionada, controller.text.trim());
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "GUARDAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================================================================
  //                 CARTÃO – REFEIÇÕES (4 HORAS)
  // ===================================================================

  /// Cartão de resumo das refeições, com 4 horários diferentes.
  Widget _buildCardRefeicoes() {
    String format(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

    final resumoHorarios =
        "Peq. almoço ${format(_horaPeqAlmoco)} • "
        "Almoço ${format(_horaAlmoco)} • "
        "Lanche ${format(_horaLanche)} • "
        "Jantar ${format(_horaJantar)}";

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              child: const Icon(Icons.restaurant,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Refeições",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descRefeicoes,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resumoHorarios,
                    style: TextStyle(
                      fontSize: 12,
                      color: _refeicoesAtivo
                          ? Colors.orange[800]
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _refeicoesAtivo,
              onChanged: (valor) {
                setState(() => _refeicoesAtivo = valor);
              },
              activeThumbColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Editor específico para as 4 refeições.
  /// Permite alterar a hora de cada uma + mensagem de lembrete.
  Future<void> _editarRefeicoes() async {
    // Copias temporárias dos horários atuais
    TimeOfDay peqTemp = _horaPeqAlmoco;
    TimeOfDay almocoTemp = _horaAlmoco;
    TimeOfDay lancheTemp = _horaLanche;
    TimeOfDay jantarTemp = _horaJantar;

    final controller = TextEditingController(text: _descRefeicoes);

    Future<TimeOfDay?> pickTime(
        BuildContext ctx, TimeOfDay initial) async {
      final picked = await showTimePicker(
        context: ctx,
        initialTime: initial,
      );
      return picked;
    }

    String format(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

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
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    "Configurar lembretes – Refeições",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _rowHoraRefeicao(
                    ctx: ctx,
                    label: "Pequeno-almoço",
                    hora: peqTemp,
                    onTap: () async {
                      final picked = await pickTime(ctx, peqTemp);
                      if (picked != null) {
                        setModalState(() => peqTemp = picked);
                      }
                    },
                    format: format,
                  ),
                  _rowHoraRefeicao(
                    ctx: ctx,
                    label: "Almoço",
                    hora: almocoTemp,
                    onTap: () async {
                      final picked = await pickTime(ctx, almocoTemp);
                      if (picked != null) {
                        setModalState(() => almocoTemp = picked);
                      }
                    },
                    format: format,
                  ),
                  _rowHoraRefeicao(
                    ctx: ctx,
                    label: "Lanche",
                    hora: lancheTemp,
                    onTap: () async {
                      final picked = await pickTime(ctx, lancheTemp);
                      if (picked != null) {
                        setModalState(() => lancheTemp = picked);
                      }
                    },
                    format: format,
                  ),
                  _rowHoraRefeicao(
                    ctx: ctx,
                    label: "Jantar",
                    hora: jantarTemp,
                    onTap: () async {
                      final picked = await pickTime(ctx, jantarTemp);
                      if (picked != null) {
                        setModalState(() => jantarTemp = picked);
                      }
                    },
                    format: format,
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Mensagem geral das refeições",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _horaPeqAlmoco = peqTemp;
                          _horaAlmoco = almocoTemp;
                          _horaLanche = lancheTemp;
                          _horaJantar = jantarTemp;
                          _descRefeicoes = controller.text.trim().isEmpty
                              ? _descRefeicoes
                              : controller.text.trim();
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "GUARDAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  /// Linha reutilizável para mostrar/editar a hora de cada refeição.
  Widget _rowHoraRefeicao({
    required BuildContext ctx,
    required String label,
    required TimeOfDay hora,
    required VoidCallback onTap,
    required String Function(TimeOfDay) format,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            format(hora),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onTap,
            child: const Text("ALTERAR"),
          ),
        ],
      ),
    );
  }
}
