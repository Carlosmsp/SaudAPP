import 'package:flutter/material.dart';
import '../repositories/habitos_repository.dart';

/// Ecrã responsável pelo registo das refeições diárias.
/// Mostra o total de calorias do dia e permite registar
/// Pequeno-almoço, Almoço, Lanche e Jantar.
class MealsScreen extends StatefulWidget {
  /// Identificador do utilizador (vem do login / sessão).
  final int userId;

  const MealsScreen({super.key, required this.userId});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  /// Meta diária de calorias (valor fixo por agora).
  final int _metaCalorias = 2000;

  /// Total de calorias já consumidas hoje.
  int _totalCalorias = 0;

  /// Indica se os dados ainda estão a ser carregados.
  bool _isLoading = true;

  /// Guarda os IDs dos registos de refeições feitos hoje.
  /// Serve para permitir o "desfazer" (apagar o último registo).
  List<int> _historicoIds = [];

  /// Repositório de hábitos responsável por falar com a base de dados / API.
  /// Esta classe depende de HabitosRepository para ler e gravar refeições.
  late final HabitosRepository _repo = HabitosRepository.fromSupabase();

  /// Lista de alimentos pré-definidos por tipo de refeição.
  /// Cada alimento tem um nome e o respectivo valor calórico aproximado.
  final Map<String, List<Map<String, dynamic>>> _alimentosPorRefeicao = {
    "Pequeno-almoço": [
      {"nome": "Pão com queijo fresco", "calorias": 180},
      {"nome": "Tosta mista", "calorias": 260},
      {"nome": "Iogurte natural com aveia", "calorias": 200},
      {"nome": "Café com leite + 2 bolachas Maria", "calorias": 140},
    ],
    "Almoço": [
      {"nome": "Frango grelhado + arroz + salada", "calorias": 650},
      {"nome": "Peixe grelhado + batata cozida + legumes", "calorias": 550},
      {"nome": "Carne estufada + arroz/massa", "calorias": 700},
      {"nome": "Prato vegetariano (legumes + leguminosas)", "calorias": 500},
    ],
    "Lanche": [
      {"nome": "Iogurte + fruta", "calorias": 180},
      {"nome": "Sandes de queijo ou fiambre", "calorias": 250},
      {"nome": "Maçã + punhado de frutos secos", "calorias": 230},
      {"nome": "Bolacha de água e sal (4 unid.)", "calorias": 160},
    ],
    "Jantar": [
      {"nome": "Sopa de legumes (1 prato)", "calorias": 150},
      {"nome": "Omelete + salada", "calorias": 350},
      {"nome": "Peixe cozido + legumes", "calorias": 400},
      {"nome": "Iogurte ou fruta", "calorias": 100},
    ],
  };

  /// Lista genérica de alimentos usada quando não existir
  /// um conjunto específico para o tipo de refeição.
  List<Map<String, dynamic>> _obterAlimentosParaTipo(String tipo) {
    if (_alimentosPorRefeicao.containsKey(tipo)) {
      return _alimentosPorRefeicao[tipo]!;
    }

    return [
      {"nome": "Prato de carne com acompanhamento", "calorias": 600},
      {"nome": "Prato de peixe com acompanhamento", "calorias": 500},
      {"nome": "Prato vegetariano", "calorias": 450},
      {"nome": "Sobremesa simples", "calorias": 200},
    ];
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Carrega do repositório os dados do dia atual
  /// (total de calorias e lista de IDs de registos).
  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _repo.obterRefeicoesDoDia(widget.userId);

      if (!mounted) return;
      setState(() {
        _totalCalorias = data.totalCalorias;
        _historicoIds = data.registoIds;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar dados: ${e.toString()}"),
          ),
        );
      }
    }
  }

  /// Regista uma refeição nova no repositório e atualiza o estado local.
  Future<void> _adicionarRefeicao(String tipo, int cal) async {
    try {
      final id = await _repo.registarRefeicao(
        userId: widget.userId,
        tipo: tipo,
        calorias: cal,
      );

      if (!mounted) return;
      setState(() {
        _totalCalorias += cal;
        _historicoIds.add(id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao registar refeição: $e")),
      );
    }
  }

  /// Remove o último registo de refeição (efeito "desfazer").
  Future<void> _removerUltimoRegisto() async {
    if (_historicoIds.isEmpty) return;

    final id = _historicoIds.last;
    try {
      // O repositório devolve as calorias que foram apagadas
      // para podermos atualizar o total localmente.
      final cal = await _repo.apagarRefeicao(id);

      if (!mounted) return;
      setState(() {
        // ignore: unnecessary_cast
        _totalCalorias -= (cal as int);
        _historicoIds.removeLast();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao remover registo: $e")),
      );
    }
  }

  /// Abre o diálogo de selecção de alimentos para uma determinada refeição.
  ///
  /// O diálogo devolve o total de calorias (int) ou null se o utilizador cancelar.
  Future<void> _mostrarDialogRefeicao(String tipo, int sugestao) async {
    final alimentosBase = _obterAlimentosParaTipo(tipo);

    final resultado = await showDialog<int>(
      context: context,
      builder: (ctx) => SelecionarRefeicaoDialog(
        tipo: tipo,
        sugestao: sugestao,
        alimentosIniciais: alimentosBase,
      ),
    );

    if (resultado != null) {
      await _adicionarRefeicao(tipo, resultado);
    }
  }

  /// Pequeno widget de apoio para mostrar informações numéricas
  /// (por exemplo, "Falta" e "Meta") em formato de chip no topo.
  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calorias que ainda faltam para atingir a meta diária.
    final caloriasRestantes = _metaCalorias - _totalCalorias;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Refeições"),
        actions: [
          IconButton(
            onPressed: _historicoIds.isNotEmpty ? _removerUltimoRegisto : null,
            icon: const Icon(Icons.undo),
            tooltip: "Desfazer último registo",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Cartão superior com resumo das calorias do dia.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$_totalCalorias",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "KCAL HOJE",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _infoChip(
                                "Falta",
                                "${caloriasRestantes > 0 ? caloriasRestantes : 0}",
                              ),
                              _infoChip("Meta", "$_metaCalorias"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    /// Cartões para cada refeição do dia.
                    _mealCard(
                      "Pequeno-almoço",
                      "Clica para registar o que comeste",
                      400,
                      Icons.coffee,
                      const Color(0xFFFFB74D),
                    ),
                    _mealCard(
                      "Almoço",
                      "Clica para registar o que comeste",
                      800,
                      Icons.lunch_dining,
                      const Color(0xFFFF8A65),
                    ),
                    _mealCard(
                      "Lanche",
                      "Clica para registar o que comeste",
                      200,
                      Icons.cookie,
                      const Color(0xFFFFD54F),
                    ),
                    _mealCard(
                      "Jantar",
                      "Clica para registar o que comeste",
                      700,
                      Icons.dinner_dining,
                      const Color(0xFFFF7043),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Constrói o cartão (tile) de uma refeição individual.
  ///
  /// [nome]   – título da refeição (ex.: "Almoço").
  /// [desc]   – pequena descrição por baixo do título.
  /// [sugestaoCalorias] – valor aproximado recomendado para essa refeição.
  /// [icon]   – ícone exibido à esquerda.
  /// [cor]    – cor principal usada no ícone.
  Widget _mealCard(
    String nome,
    String desc,
    int sugestaoCalorias,
    IconData icon,
    Color cor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        elevation: 2,
        child: InkWell(
          // Ao tocar no cartão, abrimos o diálogo de selecção de alimentos.
          onTap: () => _mostrarDialogRefeicao(nome, sugestaoCalorias),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                /// Círculo colorido com o ícone da refeição.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: cor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cor, size: 28),
                ),
                const SizedBox(width: 15),

                /// Texto principal do cartão (nome, descrição e sugestão).
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sugestão: $sugestaoCalorias kcal",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Setinha à direita para indicar que é clicável.
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo autónomo para seleccionar alimentos de uma refeição
/// e opcionalmente adicionar alimentos novos (nome + calorias).
class SelecionarRefeicaoDialog extends StatefulWidget {
  final String tipo;
  final int sugestao;
  final List<Map<String, dynamic>> alimentosIniciais;

  const SelecionarRefeicaoDialog({
    super.key,
    required this.tipo,
    required this.sugestao,
    required this.alimentosIniciais,
  });

  @override
  State<SelecionarRefeicaoDialog> createState() =>
      _SelecionarRefeicaoDialogState();
}

class _SelecionarRefeicaoDialogState extends State<SelecionarRefeicaoDialog> {
  /// Lista local de alimentos (cópia da lista recebida).
  late List<Map<String, dynamic>> _alimentos;

  /// Índices dos alimentos seleccionados.
  final Set<int> _indicesSelecionados = {};

  /// Controllers para o alimento manual.
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _caloriasController = TextEditingController();

  /// Mensagem de erro local (para validação do alimento manual).
  String? _erroAdicionar;

  @override
  void initState() {
    super.initState();
    // Fazemos uma cópia da lista recebida para não mexer no mapa original.
    _alimentos =
        widget.alimentosIniciais.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _caloriasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Soma das calorias dos alimentos seleccionados.
    final totalSelecionado = _indicesSelecionados.fold<int>(
      0,
      (soma, index) => soma + (_alimentos[index]["calorias"] as int),
    );

    final podeRegistar = _indicesSelecionados.isNotEmpty;

    return AlertDialog(
      title: Text("${widget.tipo} - registar refeição"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Selecciona os alimentos que consumiste nesta refeição "
                "e, se não encontrares o que procuras, adiciona-o manualmente.",
              ),
              const SizedBox(height: 10),

              /// Lista de alimentos com checkbox.
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: _alimentos.length,
                  itemBuilder: (context, index) {
                    final alimento = _alimentos[index];
                    final nome = alimento["nome"] as String;
                    final calorias = alimento["calorias"] as int;
                    final selecionado = _indicesSelecionados.contains(index);

                    return CheckboxListTile(
                      value: selecionado,
                      onChanged: (valor) {
                        setState(() {
                          if (valor == true) {
                            _indicesSelecionados.add(index);
                          } else {
                            _indicesSelecionados.remove(index);
                          }
                        });
                      },
                      title: Text(nome),
                      subtitle: Text("$calorias kcal"),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),

              /// Secção para adicionar um alimento manualmente.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Adicionar alimento manualmente",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome do alimento",
                  hintText: "Ex.: Arroz de pato",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _caloriasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Calorias (kcal)",
                  hintText: "Ex.: 650",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_erroAdicionar != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _erroAdicionar!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _adicionarAlimentoManual,
                  icon: const Icon(Icons.add),
                  label: const Text("Adicionar à lista"),
                ),
              ),
              const SizedBox(height: 10),

              /// Informação sobre o total calculado e sugestão.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Total seleccionado: $totalSelecionado kcal",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              if (widget.sugestao > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sugestão para esta refeição: ${widget.sugestao} kcal",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCELAR"),
        ),
        ElevatedButton(
          onPressed: !podeRegistar
              ? null
              : () {
                  final total = _indicesSelecionados.fold<int>(
                    0,
                    (soma, index) =>
                        soma + (_alimentos[index]["calorias"] as int),
                  );
                  if (total <= 0) return;
                  Navigator.pop<int>(context, total);
                },
          child: const Text("REGISTAR"),
        ),
      ],
    );
  }

  /// Lógica para adicionar um alimento manualmente à lista local.
  void _adicionarAlimentoManual() {
    final nome = _nomeController.text.trim();
    final calorias = int.tryParse(_caloriasController.text.trim());

    if (nome.isEmpty || calorias == null || calorias <= 0) {
      setState(() {
        _erroAdicionar = "Preenche o nome e as calorias com um valor válido.";
      });
      return;
    }

    setState(() {
      _erroAdicionar = null;

      _alimentos.add({
        "nome": nome,
        "calorias": calorias,
      });

      final novoIndex = _alimentos.length - 1;
      _indicesSelecionados.add(novoIndex);

      _nomeController.clear();
      _caloriasController.clear();
    });
  }
}
