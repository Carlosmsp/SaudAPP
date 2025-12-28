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