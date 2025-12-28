import 'package:supabase_flutter/supabase_flutter.dart';

class HabitosRepository {
  final SupabaseClient _client;
  HabitosRepository(this._client);

  factory HabitosRepository.fromSupabase() {
    return HabitosRepository(Supabase.instance.client);
  }

  // --- ÁGUA (Resolve erros do WaterScreen e Goals) ---
  Future<int> registarAgua(int userId, int quantidadeMl) async {
    final res = await _client
        .from('consumo_agua')
        .insert({
          'id_utilizador': userId,
          'quantidade_ml': quantidadeMl,
          'data_registo': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return res['id'] as int;
  }

  Future<List<DailyWaterData>> obterConsumoAguaDoDia(int userId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final List<dynamic> res = await _client
        .from('consumo_agua')
        .select()
        .eq('id_utilizador', userId)
        .gte('data_registo', '$hoje 00:00:00');

    return res
        .map((item) => DailyWaterData(item['id'], item['quantidade_ml']))
        .toList();
  }

  Future<void> apagarRegistoAgua(int registoId) async {
    await _client.from('consumo_agua').delete().eq('id', registoId);
  }

  // --- REFEIÇÕES (Resolve erros do MealsScreen e Goals) ---
  Future<int> registarRefeicao({
    required int userId,
    required String tipo,
    required int calorias,
  }) async {
    final res = await _client
        .from('refeicoes')
        .insert({
          'id_utilizador': userId,
          'nome_refeicao': tipo,
          'calorias': calorias,
          'data_registo': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return res['id'] as int;
  }

  Future<List<DailyMealsData>> obterRefeicoesDoDia(int userId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final List<dynamic> res = await _client
        .from('refeicoes')
        .select()
        .eq('id_utilizador', userId)
        .gte('data_registo', '$hoje 00:00:00');

    return res
        .map(
          (item) => DailyMealsData(
            item['id'],
            item['nome_refeicao'] ?? '',
            item['calorias'],
          ),
        )
        .toList();
  }

  Future<void> apagarRegistoRefeicao(int registoId) async {
    await _client.from('refeicoes').delete().eq('id', registoId);
  }

  // --- ATIVIDADE (Resolve erro Ln 67 do activity_screen) ---
  Future<void> registarAtividade({
    required int userId,
    required String modalidade,
    required double distancia,
    required int duracao,
    required int calorias,
  }) async {
    await _client.from('atividades_fisicas').insert({
      'id_utilizador': userId,
      'tipo_atividade': modalidade,
      'distancia_km': distancia,
      'duracao_minutos': duracao,
      'calorias_queimadas': calorias,
      'data_registo': DateTime.now().toIso8601String(),
    });
  }

  // --- SONO (Resolve erro Ln 31 do goals_screen) ---
  Future<List<dynamic>> obterSonoHoje(int userId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    return await _client
        .from('registo_sono')
        .select()
        .eq('id_utilizador', userId)
        .gte('data_registo', '$hoje 00:00:00');
  }

  Future<void> registarSono(int userId, double horas) async {
    await _client.from('registo_sono').insert({
      'id_utilizador': userId,
      'quantidade_horas': horas,
      'data_registo': DateTime.now().toIso8601String(),
    });
  }

  // --- DASHBOARD (Resolve erro Ln 35 do dashboard_page) ---
  Future<Map<String, dynamic>> obterResumoDoDia(int userId) async {
    try {
      return await _client
          .from('resumo_diario')
          .select()
          .eq('id_utilizador', userId)
          .single();
    } catch (e) {
      return {'total_agua': 0, 'total_calorias': 0, 'total_sono': 0};
    }
  }
}

class DailyWaterData {
  final int id;
  final int totalMl;
  DailyWaterData(this.id, this.totalMl);
}

class DailyMealsData {
  final int id;
  final String nome;
  final int totalCalorias;
  DailyMealsData(this.id, this.nome, this.totalCalorias);
}

extension WaterListLogic on List<DailyWaterData> {
  int get totalMl => fold(0, (sum, item) => sum + item.totalMl);
  List<int> get registoIds => map((item) => item.id).toList();
}

extension MealsListLogic on List<DailyMealsData> {
  int get totalCalorias => fold(0, (sum, item) => sum + item.totalCalorias);
  List<int> get registoIds => map((item) => item.id).toList();
}
