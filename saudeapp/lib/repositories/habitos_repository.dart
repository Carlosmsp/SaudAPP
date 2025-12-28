import 'package:supabase_flutter/supabase_flutter.dart';

class HabitosRepository {
  final SupabaseClient _client;
  HabitosRepository(this._client);

  factory HabitosRepository.fromSupabase() =>
      HabitosRepository(Supabase.instance.client);

  Future<int> _criarHabito(int userId, String tipo) async {
    final res = await _client
        .from('habitos')
        .insert({
          'id_utilizador': userId,
          'tipo_habito': tipo,
          'data_registo': DateTime.now().toIso8601String(),
        })
        .select('id_habito')
        .single();
    return res['id_habito'];
  }

  Future<DailyWaterData> obterConsumoAguaDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('bebidas')
        .select(
          'id_bebida, quantidade_ml, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId);

    final lista = res as List;
    int total = lista.fold(0, (sum, e) => sum + (e['quantidade_ml'] as int));
    return DailyWaterData(
      lista.map((e) => e['id_bebida'] as int).toList(),
      total,
    );
  }

  Future<int> registarAgua(int userId, int ml) async {
    final idHabito = await _criarHabito(userId, 'Hidratação');

    final res = await _client
        .from('bebidas')
        .insert({
          'id_habito': idHabito,
          'quantidade_ml': ml,
          'tipo_bebida': 'Água',
        })
        .select('id_bebida')
        .single();
    return res['id_bebida'];
  }

  Future<void> apagarRegistoAgua(int id) async {
    await _client.from('bebidas').delete().eq('id_bebida', id);
  }

  Future<DailyMealsData> obterRefeicoesDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('refeicoes')
        .select(
          'id_refeicao, calorias_kcal, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId);

    final lista = res as List;
    int total = lista.fold(0, (sum, e) => sum + (e['calorias_kcal'] as int));
    return DailyMealsData(
      lista.map((e) => e['id_refeicao'] as int).toList(),
      total,
    );
  }

  Future<int> registarRefeicao({
    required int userId,
    required String tipo,
    required int calorias,
  }) async {
    final idHabito = await _criarHabito(userId, 'Alimentação');

    final res = await _client
        .from('refeicoes')
        .insert({
          'id_habito': idHabito,
          'tipo_refeicao': tipo,
          'calorias_kcal': calorias,
        })
        .select('id_refeicao')
        .single();
    return res['id_refeicao'];
  }

  Future<void> apagarRegistoRefeicao(int id) async {
    await _client.from('refeicoes').delete().eq('id_refeicao', id);
  }

  Future<void> registarSono(int userId, double horas) async {
    final idHabito = await _criarHabito(userId, 'Sono');

    await _client.from('sono').insert({
      'id_habito': idHabito,
      'horas_dormidas': horas,
      'qualidade': 3,
    });
  }

  Future<void> registarSonoCompleto(int userId, double horas, DateTime horaDeitar, DateTime horaAcordar) async {
    final idHabito = await _criarHabito(userId, 'Sono');

    await _client.from('sono').insert({
      'id_habito': idHabito,
      'horas_dormidas': horas,
      'qualidade': 3,
      'hora_deitar': horaDeitar.toIso8601String(),
      'hora_acordar': horaAcordar.toIso8601String(),
    });
  }

  Future<void> registarSonoComQualidade(int userId, double horas, DateTime horaDeitar, DateTime horaAcordar, int qualidade) async {
    final idHabito = await _criarHabito(userId, 'Sono');

    await _client.from('sono').insert({
      'id_habito': idHabito,
      'horas_dormidas': horas,
      'qualidade': qualidade,
      'hora_deitar': horaDeitar.toIso8601String(),
      'hora_acordar': horaAcordar.toIso8601String(),
    });
  }

  Future<double> obterSonoHoje(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('sono')
        .select('horas_dormidas, habitos!inner(id_utilizador, data_registo)')
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId);

    final lista = res as List;
    if (lista.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in lista) {
      final horas = item['horas_dormidas'];
      if (horas != null) {
        total += (horas as num).toDouble();
      }
    }
    return total;
  }

  Future<void> registarAtividade({
    required int userId,
    required String modalidade,
    required double distancia,
    required int duracao,
    required int calorias,
  }) async {
    await _client.from('atividades').insert({
      'id_utilizador': userId,
      'tipo_atividade': modalidade,
      'distancia_km': distancia,
      'duracao_segundos': duracao,
      'ritmo_medio': 0.0,
    });
  }
  /// Lista detalhada dos registos de água de HOJE.
  /// Cada item vem com quantidade, tipo de bebida e data/hora.
  Future<List<Map<String, dynamic>>> obterBebidasDetalhadasDoDia(
      int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('bebidas')
        .select(
          'id_bebida, quantidade_ml, tipo_bebida, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Lista detalhada das refeições de HOJE.
  /// Cada item tem tipo_refeicao, calorias e data/hora.
  Future<List<Map<String, dynamic>>> obterRefeicoesDetalhadasDoDia(
      int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('refeicoes')
        .select(
          'id_refeicao, tipo_refeicao, calorias_kcal, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Lista detalhada dos registos de sono de HOJE.
  /// Cada item tem horas, qualidade e hora_deitar/hora_acordar.
  Future<List<Map<String, dynamic>>> obterSonoDetalhadoDoDia(
      int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('sono')
        .select(
          'horas_dormidas, qualidade, hora_deitar, hora_acordar, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Lista detalhada das atividades físicas de HOJE.
  ///
  /// NOTA: aqui assumo que a tabela `atividades` tem uma coluna
  /// `data_registo` do tipo timestamp. Se na tua BD se chamar
  /// `created_at` ou outro nome, é só trocar abaixo.
  Future<List<Map<String, dynamic>>> obterAtividadesDoDia(
      int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final res = await _client
        .from('atividades')
        .select(
          'tipo_atividade, distancia_km, duracao_segundos, ritmo_medio, data_registo',
        )
        .gte('data_registo', inicioDia.toIso8601String())
        .lt('data_registo', fimDia.toIso8601String())
        .eq('id_utilizador', userId)
        .order('data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> obterResumoDoDia(int userId) async {
    final agua = await obterConsumoAguaDoDia(userId);
    final refeicoes = await obterRefeicoesDoDia(userId);
    final sono = await obterSonoHoje(userId);
    return {
      'total_agua': agua.totalMl,
      'total_calorias': refeicoes.totalCalorias,
      'total_sono': sono,
    };
  }

    /// Apaga uma refeição e devolve as calorias que estavam associadas,
  /// para poderes atualizar o total localmente no ecrã.
  Future<int> apagarRefeicao(int id) async {
    // Primeiro vamos buscar as calorias da refeição
    final res = await _client
        .from('refeicoes')
        .select('calorias_kcal')
        .eq('id_refeicao', id)
        .single();

    final calorias = res['calorias_kcal'] as int;

    // Depois apagamos o registo
    await _client.from('refeicoes').delete().eq('id_refeicao', id);

    // E devolvemos as calorias para o ecrã poder subtrair ao total
    return calorias;
  }

}
  /// LISTA DETALHADA – Água de HOJE
  /// Devolve todos os registos de bebidas do dia (ml, tipo, hora).
  Future<List<Map<String, dynamic>>> obterBebidasDetalhadasDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // ignore: no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
    var _client;
    final res = await _client
        .from('bebidas')
        .select(
          'id_bebida, quantidade_ml, tipo_bebida, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// LISTA DETALHADA – Refeições de HOJE
  /// (tipo_refeicao + calorias + hora)
  Future<List<Map<String, dynamic>>> obterRefeicoesDetalhadasDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // ignore: no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
    var _client;
    final res = await _client
        .from('refeicoes')
        .select(
          'id_refeicao, tipo_refeicao, calorias_kcal, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// LISTA DETALHADA – Sono de HOJE
  /// (horas, qualidade, hora_deitar, hora_acordar)
  Future<List<Map<String, dynamic>>> obterSonoDetalhadoDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // ignore: no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
    var _client;
    final res = await _client
        .from('sono')
        .select(
          'horas_dormidas, qualidade, hora_deitar, hora_acordar, habitos!inner(id_utilizador, data_registo)',
        )
        .gte('habitos.data_registo', inicioDia.toIso8601String())
        .lt('habitos.data_registo', fimDia.toIso8601String())
        .eq('habitos.id_utilizador', userId)
        .order('habitos.data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// LISTA DETALHADA – Atividades físicas de HOJE
  ///
  /// ⚠️ IMPORTANTE:
  /// - Aqui assumo que a tabela `atividades` tem a coluna `data_registo`.
  /// - Se na tua BD for `created_at`, é só trocar abaixo.
  Future<List<Map<String, dynamic>>> obterAtividadesDoDia(int userId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // ignore: no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
    var _client;
    final res = await _client
        .from('atividades')
        .select(
          'tipo_atividade, distancia_km, duracao_segundos, ritmo_medio, data_registo',
        )
        .gte('data_registo', inicioDia.toIso8601String())
        .lt('data_registo', fimDia.toIso8601String())
        .eq('id_utilizador', userId)
        .order('data_registo');

    return List<Map<String, dynamic>>.from(res as List);
  }

class DailyWaterData {
  final List<int> registoIds;
  final int totalMl;
  DailyWaterData(this.registoIds, this.totalMl);
}

class DailyMealsData {
  final List<int> registoIds;
  final int totalCalorias;
  DailyMealsData(this.registoIds, this.totalCalorias);
}