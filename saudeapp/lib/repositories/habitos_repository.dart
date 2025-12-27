import 'package:supabase_flutter/supabase_flutter.dart';

/// Dados de água consumida num dia
class DailyWaterData {
  final int totalMl;           // total consumido nesse dia
  final List<int> registoIds;  // ids dos registos usados para "desfazer"

  const DailyWaterData({
    required this.totalMl,
    required this.registoIds,
  });
}

/// Dados de refeições num dia
class DailyMealsData {
  final int totalCalorias;
  final List<int> registoIds;

  const DailyMealsData({
    required this.totalCalorias,
    required this.registoIds,
  });
}

/// Repositório responsável por falar com o Supabase
/// para tudo o que seja Hábitos (por enquanto Água + Refeições).
class HabitosRepository {
  final SupabaseClient _client;

  HabitosRepository(this._client);

  /// Construtor de conveniência que usa o cliente global do Supabase
  factory HabitosRepository.fromSupabase() =>
      HabitosRepository(Supabase.instance.client);

  // =======================
  //          ÁGUA
  // =======================

  /// Devolve o total de água consumida hoje + lista de IDs dos registos.
  Future<DailyWaterData> obterConsumoAguaDoDia(
    int userId, {
    DateTime? dia,
  }) async {
    final data = dia ?? DateTime.now();
    // Só a parte da data em formato YYYY-MM-DD
    final hojeStr =
        DateTime(data.year, data.month, data.day).toIso8601String().split('T')[0];

    final rows = await _client
        .from('historico_agua') // <- mesmo nome de tabela que já usavas
        .select('id, quantidade_ml')
        .eq('id_utilizador', userId)
        .gte('data_registo', hojeStr);

    int total = 0;
    final ids = <int>[];

    for (final row in rows) {
      final ml = (row['quantidade_ml'] as num?)?.toInt() ?? 0;
      total += ml;
      ids.add(row['id'] as int);
    }

    return DailyWaterData(totalMl: total, registoIds: ids);
  }

  /// Regista um novo consumo de água e devolve o ID criado.
  Future<int> registarAgua(int userId, int ml) async {
    final response = await _client
        .from('historico_agua')
        .insert({
          'id_utilizador': userId,
          'quantidade_ml': ml,
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Apaga um registo de água e devolve a quantidade_ml que lá estava.
  Future<int> apagarRegistoAgua(int registoId) async {
    // 1º: ler a quantidade_ml
    final row = await _client
        .from('historico_agua')
        .select('quantidade_ml')
        .eq('id', registoId)
        .single();

    final ml = (row['quantidade_ml'] as num?)?.toInt() ?? 0;

    // 2º: apagar o registo
    await _client
        .from('historico_agua')
        .delete()
        .eq('id', registoId);

    return ml;
  }

  // =======================
  //        REFEIÇÕES
  // =======================

  /// Devolve o total de calorias ingeridas num dia + ids dos registos
  Future<DailyMealsData> obterRefeicoesDoDia(
    int userId, {
    DateTime? dia,
  }) async {
    final data = dia ?? DateTime.now();
    final hojeStr =
        DateTime(data.year, data.month, data.day).toIso8601String().split('T')[0];

    final rows = await _client
        .from('historico_refeicoes') // <-- ajusta se a tabela tiver outro nome
        .select('id, calorias_kcal')
        .eq('id_utilizador', userId)
        .gte('data_registo', hojeStr);

    int total = 0;
    final ids = <int>[];

    for (final row in rows) {
      final cals = (row['calorias_kcal'] as num?)?.toInt() ?? 0;
      total += cals;
      ids.add(row['id'] as int);
    }

    return DailyMealsData(totalCalorias: total, registoIds: ids);
  }

  /// Regista uma refeição e devolve o id do registo criado
  Future<int> registarRefeicao({
    required int userId,
    required String tipo,
    required int calorias,
  }) async {
    final response = await _client
        .from('historico_refeicoes')
        .insert({
          'id_utilizador': userId,
          'tipo_refeicao': tipo,
          'calorias_kcal': calorias,
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Apaga um registo de refeição e devolve as calorias que lá estavam
  Future<int> apagarRegistoRefeicao(int registoId) async {
    final row = await _client
        .from('historico_refeicoes')
        .select('calorias_kcal')
        .eq('id', registoId)
        .single();

    final cals = (row['calorias_kcal'] as num?)?.toInt() ?? 0;

    await _client
        .from('historico_refeicoes')
        .delete()
        .eq('id', registoId);

    return cals;
  }
}
