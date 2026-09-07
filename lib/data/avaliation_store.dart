import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class AvaliaTechException implements Exception {
  AvaliaTechException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Repositório local de demonstração. Não sincroniza entre dispositivos.
/// Todas as operações da interface passam pelas regras de domínio.
class AvaliationStore extends ChangeNotifier {
  AvaliationStore(this.preferences);
  final SharedPreferences preferences;
  final usuarios = <Usuario>[];
  final turmas = <Turma>[];
  final convites = <ConviteTurma>[];
  final questoes = <Questao>[];
  final questionarios = <Questionario>[];
  final publicacoes = <PublicacaoQuestionario>[];
  final tentativas = <Tentativa>[];
  final resultados = <Resultado>[];
  final notificacoes = <Notificacao>[];
  final configuracoes = <String, ConfiguracaoUsuario>{};
  Usuario? atual;
  bool get autenticado => atual != null;
  bool get professor => atual?.papel == Papel.professor;
  static const _key = 'avaliation_store_v1';

  // Hash local para contas de demonstração; produção exige autenticação remota.
  static String hashSenha(String senha, String salt) {
    var bytes = utf8.encode('$salt:$senha');
    for (var i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return '$salt:${base64Encode(bytes)}';
  }

  static String novoHash(String senha) => hashSenha(senha, newId());
  static bool conferirSenha(String senha, String hash) {
    final i = hash.indexOf(':');
    if (i < 0) return false;
    final a = hashSenha(senha, hash.substring(0, i));
    var diff = a.length ^ hash.length;
    for (var j = 0; j < min(a.length, hash.length); j++) {
      diff |= a.codeUnitAt(j) ^ hash.codeUnitAt(j);
    }
    return diff == 0;
  }

  void exigir(bool ok, String mensagem) {
    if (!ok) throw AvaliaTechException(mensagem);
  }

  Usuario get usuario {
    exigir(atual != null, 'Entre na sua conta.');
    return atual!;
  }

  String get uid => usuario.id;
  void exigirProfessor() =>
      exigir(professor, 'Ação disponível apenas para professores.');
  void exigirEstudante() => exigir(
    atual?.papel == Papel.estudante,
    'Ação disponível apenas para estudantes.',
  );
  T encontrar<T>(Iterable<T> lista, String id, String Function(T) key) {
    for (final item in lista) {
      if (key(item) == id) return item;
    }
    throw AvaliaTechException('Registro não encontrado.');
  }

  Usuario usuarioPorId(String id) => encontrar(usuarios, id, (u) => u.id);
  Turma turma(String id) => encontrar(turmas, id, (t) => t.id);
  Questao questao(String id) => encontrar(questoes, id, (q) => q.id);
  Questionario questionario(String id) =>
      encontrar(questionarios, id, (q) => q.id);
  PublicacaoQuestionario publicacao(String id) =>
      encontrar(publicacoes, id, (p) => p.id);
  Tentativa tentativa(String id) => encontrar(tentativas, id, (t) => t.id);
  ConfiguracaoUsuario get configuracao =>
      configuracoes.putIfAbsent(uid, () => ConfiguracaoUsuario(usuarioId: uid));
  List<Turma> get minhasTurmas => turmas
      .where(
        (t) =>
            t.ativa &&
            (professor ? t.professorId == uid : t.estudanteIds.contains(uid)),
      )
      .toList();
  List<Questao> get minhasQuestoes =>
      questoes.where((q) => q.professorId == uid && q.ativa).toList();
  List<Questionario> get meusQuestionarios =>
      questionarios.where((q) => q.professorId == uid && q.ativo).toList();
  List<PublicacaoQuestionario> get minhasPublicacoes => publicacoes
      .where(
        (p) => professor
            ? p.professorId == uid
            : p.turmas.any((id) => minhasTurmas.any((t) => t.id == id)),
      )
      .toList();
  List<Tentativa> tentativasDe(String id, {String? estudanteId}) => tentativas
      .where(
        (t) =>
            t.publicacaoId == id &&
            (estudanteId == null || t.estudanteId == estudanteId),
      )
      .toList();
  List<Resultado> resultadosDe(String id) =>
      resultados.where((r) => r.publicacaoId == id).toList();
  List<Notificacao> get minhasNotificacoes =>
      notificacoes.where((n) => n.usuarioId == uid).toList()
        ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));

  Future<void> carregar() async {
    final raw = preferences.getString(_key);
    if (raw == null) {
      _semear();
      await salvar();
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    usuarios.addAll(decodeList(j['usuarios'], usuarioFromJson));
    turmas.addAll(decodeList(j['turmas'], Turma.fromJson));
    convites.addAll(decodeList(j['convites'], ConviteTurma.fromJson));
    questoes.addAll(decodeList(j['questoes'], Questao.fromJson));
    questionarios.addAll(decodeList(j['questionarios'], Questionario.fromJson));
    publicacoes.addAll(
      decodeList(j['publicacoes'], PublicacaoQuestionario.fromJson),
    );
    tentativas.addAll(decodeList(j['tentativas'], Tentativa.fromJson));
    resultados.addAll(decodeList(j['resultados'], Resultado.fromJson));
    notificacoes.addAll(decodeList(j['notificacoes'], Notificacao.fromJson));
    for (final c in decodeList(
      j['configuracoes'],
      ConfiguracaoUsuario.fromJson,
    )) {
      configuracoes[c.usuarioId] = c;
    }
    final session = preferences.getString('avaliation_session');
    if (session != null) {
      for (final u in usuarios) {
        if (u.id == session && u.ativo) atual = u;
      }
    }
    notifyListeners();
  }

  Future<void> salvar() async {
    final j = {
      'usuarios': usuarios.map((e) => e.toJson()).toList(),
      'turmas': turmas.map((e) => e.toJson()).toList(),
      'convites': convites.map((e) => e.toJson()).toList(),
      'questoes': questoes.map((e) => e.toJson()).toList(),
      'questionarios': questionarios.map((e) => e.toJson()).toList(),
      'publicacoes': publicacoes.map((e) => e.toJson()).toList(),
      'tentativas': tentativas.map((e) => e.toJson()).toList(),
      'resultados': resultados.map((e) => e.toJson()).toList(),
      'notificacoes': notificacoes.map((e) => e.toJson()).toList(),
      'configuracoes': configuracoes.values.map((e) => e.toJson()).toList(),
    };
    final ok = await preferences.setString(_key, jsonEncode(j));
    if (!ok)
      throw AvaliaTechException(
        'Não foi possível salvar os dados neste dispositivo.',
      );
    notifyListeners();
  }

  Future<void> entrar(String email, String senha, Papel papel) async {
    final matches = usuarios
        .where(
          (u) =>
              u.email == email.trim().toLowerCase() &&
              u.papel == papel &&
              u.ativo,
        )
        .toList();
    exigir(
      matches.length == 1 && conferirSenha(senha, matches.first.senhaHash),
      'E-mail, senha ou perfil inválidos.',
    );
    atual = matches.first;
    await preferences.setString('avaliation_session', atual!.id);
    notifyListeners();
  }

  Future<void> sair() async {
    atual = null;
    await preferences.remove('avaliation_session');
    notifyListeners();
  }

  Future<Usuario> cadastrarUsuario(
    String nome,
    String email,
    String senha,
    Papel papel,
  ) async {
    exigir(
      nome.trim().isNotEmpty && email.contains('@') && senha.length >= 8,
      'Informe nome, e-mail válido e senha com pelo menos 8 caracteres.',
    );
    exigir(
      !usuarios.any((u) => u.email == email.trim().toLowerCase()),
      'Este e-mail já está cadastrado.',
    );
    final id = newId();
    final hash = novoHash(senha);
    final u = papel == Papel.professor
        ? Professor(
            id: id,
            nome: nome.trim(),
            email: email.trim().toLowerCase(),
            senhaHash: hash,
          )
        : Estudante(
            id: id,
            nome: nome.trim(),
            email: email.trim().toLowerCase(),
            senhaHash: hash,
          );
    usuarios.add(u);
    configuracoes[id] = ConfiguracaoUsuario(usuarioId: id);
    await salvar();
    return u;
  }

  Future<void> atualizarPerfil(String nome, String email) async {
    exigir(
      nome.trim().isNotEmpty && email.contains('@'),
      'Informe nome e e-mail válidos.',
    );
    exigir(
      !usuarios.any(
        (u) => u.id != uid && u.email == email.trim().toLowerCase(),
      ),
      'E-mail já utilizado.',
    );
    usuario.atualizarPerfil(nome, email);
    await salvar();
  }

  Future<void> alterarSenha(String antiga, String nova) async {
    exigir(conferirSenha(antiga, usuario.senhaHash), 'Senha atual incorreta.');
    exigir(nova.length >= 8, 'A nova senha deve ter pelo menos 8 caracteres.');
    usuario.alterarSenha(novoHash(nova));
    await salvar();
  }

  Future<void> atualizarConfiguracao(
    void Function(ConfiguracaoUsuario) f,
  ) async {
    f(configuracao);
    await salvar();
  }

  String _codigo() => 'TRM-${Random.secure().nextInt(900000) + 100000}';
  Future<Turma> salvarTurma({
    String? id,
    required String nome,
    required String disciplina,
  }) async {
    exigirProfessor();
    exigir(
      nome.trim().isNotEmpty && disciplina.trim().isNotEmpty,
      'Preencha nome e disciplina.',
    );
    final t = id == null
        ? Turma(
            id: newId(),
            nome: nome.trim(),
            disciplina: disciplina.trim(),
            professorId: uid,
            codigoConvite: _codigo(),
            dataCriacao: DateTime.now(),
          )
        : turma(id);
    exigir(t.professorId == uid, 'Turma não autorizada.');
    t.nome = nome.trim();
    t.disciplina = disciplina.trim();
    if (id == null) turmas.add(t);
    await salvar();
    return t;
  }

  Future<void> arquivarTurma(String id) async {
    exigirProfessor();
    final t = turma(id);
    exigir(t.professorId == uid, 'Turma não autorizada.');
    t.arquivar();
    await salvar();
  }

  Future<String> gerarNovoCodigo(String id) async {
    exigirProfessor();
    final t = turma(id);
    exigir(t.professorId == uid, 'Turma não autorizada.');
    t.codigoConvite = _codigo();
    await salvar();
    return t.codigoConvite;
  }

  Future<void> removerEstudante(String turmaId, String estudanteId) async {
    exigirProfessor();
    final t = turma(turmaId);
    exigir(t.professorId == uid, 'Turma não autorizada.');
    t.removerEstudante(estudanteId);
    await salvar();
  }

  Future<ConviteTurma> convidar(String turmaId, String email) async {
    exigirProfessor();
    final t = turma(turmaId);
    exigir(t.professorId == uid && t.ativa, 'Turma não autorizada.');
    final matches = usuarios
        .where(
          (u) =>
              u.email == email.trim().toLowerCase() &&
              u.papel == Papel.estudante,
        )
        .toList();
    exigir(matches.isNotEmpty, 'Estudante não cadastrado.');
    final s = matches.first;
    exigir(
      !t.estudanteIds.contains(s.id),
      'Este estudante já participa da turma.',
    );
    exigir(
      !convites.any(
        (c) =>
            c.turmaId == t.id &&
            c.estudanteId == s.id &&
            c.status == StatusConvite.pendente,
      ),
      'Já existe um convite pendente.',
    );
    final c = ConviteTurma(
      id: newId(),
      turmaId: t.id,
      estudanteId: s.id,
      professorId: uid,
      dataEnvio: DateTime.now(),
      dataExpiracao: DateTime.now().add(const Duration(days: 7)),
    );
    convites.add(c);
    _notificar(
      s.id,
      'Convite para turma',
      'Você foi convidado para ${t.nome}.',
      TipoNotificacao.conviteTurma,
      c.id,
    );
    await salvar();
    return c;
  }

  Future<void> responderConvite(String id, bool aceitar) async {
    exigirEstudante();
    final c = encontrar(convites, id, (c) => c.id);
    exigir(
      c.estudanteId == uid && c.status == StatusConvite.pendente,
      'Convite não disponível.',
    );
    if (c.expirou()) {
      c.status = StatusConvite.expirado;
      await salvar();
      throw AvaliaTechException('O convite expirou.');
    }
    c.status = aceitar ? StatusConvite.aceito : StatusConvite.recusado;
    if (aceitar) turma(c.turmaId).adicionarEstudante(uid);
    await salvar();
  }

  Future<void> entrarNaTurma(String codigo) async {
    exigirEstudante();
    final matches = turmas
        .where(
          (t) =>
              t.codigoConvite.toUpperCase() == codigo.trim().toUpperCase() &&
              t.ativa,
        )
        .toList();
    exigir(matches.isNotEmpty, 'Código de turma inválido.');
    matches.first.adicionarEstudante(uid);
    await salvar();
  }

  Future<void> sairDaTurma(String id) async {
    exigirEstudante();
    turma(id).removerEstudante(uid);
    await salvar();
  }

  Future<Questao> salvarQuestao(Questao q) async {
    exigirProfessor();
    exigir(q.professorId == uid, 'Questão não autorizada.');
    q.validar();
    final i = questoes.indexWhere((e) => e.id == q.id);
    if (i < 0) {
      questoes.add(q);
    } else {
      questoes[i] = q;
    }
    q.dataAtualizacao = DateTime.now();
    await salvar();
    return q;
  }

  Future<void> arquivarQuestao(String id) async {
    exigirProfessor();
    final q = questao(id);
    exigir(q.professorId == uid, 'Questão não autorizada.');
    q.ativa = false;
    await salvar();
  }

  Future<Questionario> salvarQuestionario(Questionario q) async {
    exigirProfessor();
    exigir(q.professorId == uid, 'Questionário não autorizado.');
    q.validar();
    for (final item in q.itens) {
      final ref = questao(item.questaoId);
      exigir(
        ref.professorId == uid && ref.ativa,
        'Uma questão não está disponível.',
      );
    }
    exigir(
      q.itens.map((i) => i.questaoId).toSet().length == q.itens.length,
      'Não adicione a mesma questão duas vezes.',
    );
    final i = questionarios.indexWhere((e) => e.id == q.id);
    if (i < 0) {
      questionarios.add(q);
    } else {
      questionarios[i] = q;
    }
    q.dataAtualizacao = DateTime.now();
    await salvar();
    return q;
  }

  Future<void> arquivarQuestionario(String id) async {
    exigirProfessor();
    final q = questionario(id);
    exigir(q.professorId == uid, 'Questionário não autorizado.');
    q.ativo = false;
    await salvar();
  }

  Future<PublicacaoQuestionario> publicar({
    required String questionarioId,
    required List<String> turmaIds,
    required DateTime inicio,
    required DateTime prazo,
    required int limite,
    required bool mostrarResultado,
    required bool embaralhar,
  }) async {
    exigirProfessor();
    final q = questionario(questionarioId);
    exigir(q.professorId == uid && q.ativo, 'Questionário não autorizado.');
    q.validar();
    for (final id in turmaIds) {
      final t = turma(id);
      exigir(t.professorId == uid && t.ativa, 'Uma turma não está disponível.');
    }
    final p = PublicacaoQuestionario(
      id: newId(),
      questionarioId: q.id,
      professorId: uid,
      turmas: turmaIds.toSet().toList(),
      inicioDisponibilidade: inicio,
      prazo: prazo,
      limiteTentativas: limite,
      mostrarResultado: mostrarResultado,
      embaralharQuestoes: embaralhar,
      dataPublicacao: DateTime.now(),
      conteudo: ConteudoAvaliacao(
        titulo: q.titulo,
        descricao: q.descricao,
        duracaoMinutos: q.duracaoMinutos,
        itens: decodeList(
          q.itens.map((e) => e.toJson()).toList(),
          ItemQuestionario.fromJson,
        ),
        questoes: q.itens.map((i) => questao(i.questaoId).snapshot()).toList(),
      ),
    );
    p.validar();
    publicacoes.add(p);
    for (final id in p.turmas) {
      for (final sid in turma(id).estudanteIds) {
        _notificar(
          sid,
          'Nova avaliação publicada',
          q.titulo,
          TipoNotificacao.novaAvaliacao,
          p.id,
        );
      }
    }
    await salvar();
    return p;
  }

  Future<void> ajustarPublicacao(
    String id, {
    DateTime? prazo,
    bool? mostrarResultado,
    bool encerrar = false,
  }) async {
    exigirProfessor();
    final p = publicacao(id);
    exigir(p.professorId == uid, 'Publicação não autorizada.');
    if (prazo != null) {
      exigir(prazo.isAfter(p.inicioDisponibilidade), 'Prazo inválido.');
      p.prazo = prazo;
    }
    if (mostrarResultado != null) p.mostrarResultado = mostrarResultado;
    if (encerrar) p.status = StatusPublicacao.encerrada;
    await salvar();
  }

  ConteudoAvaliacao conteudo(PublicacaoQuestionario p) =>
      p.conteudo ?? _conteudoLegado(p);
  ConteudoAvaliacao _conteudoLegado(PublicacaoQuestionario p) {
    final q = questionario(p.questionarioId);
    return ConteudoAvaliacao(
      titulo: q.titulo,
      descricao: q.descricao,
      duracaoMinutos: q.duracaoMinutos,
      itens: q.itens,
      questoes: q.itens.map((i) => questao(i.questaoId)).toList(),
    );
  }

  bool podeIniciar(PublicacaoQuestionario p) {
    if (atual?.papel != Papel.estudante ||
        !minhasPublicacoes.any((e) => e.id == p.id))
      return false;
    return p.estaDisponivel() &&
        tentativasDe(p.id, estudanteId: uid).length < p.limiteTentativas;
  }

  Tentativa? tentativaEmAndamento(String publicacaoId) {
    for (final t in tentativasDe(publicacaoId, estudanteId: uid)) {
      if (t.editavel) return t;
    }
    return null;
  }

  Future<Tentativa> iniciar(String publicacaoId) async {
    exigirEstudante();
    final p = publicacao(publicacaoId);
    exigir(
      minhasPublicacoes.any((e) => e.id == p.id),
      'Avaliação não autorizada.',
    );
    final aberta = tentativaEmAndamento(p.id);
    if (aberta != null) return aberta;
    exigir(
      podeIniciar(p),
      'Avaliação indisponível ou limite de tentativas atingido.',
    );
    final ordem = conteudo(p).itens.map((e) => e.questaoId).toList();
    if (p.embaralharQuestoes) ordem.shuffle(Random.secure());
    final t = Tentativa(
      id: newId(),
      estudanteId: uid,
      publicacaoId: p.id,
      numeroTentativa: tentativasDe(p.id, estudanteId: uid).length + 1,
      inicio: DateTime.now(),
      ordemQuestoes: ordem,
    );
    tentativas.add(t);
    await salvar();
    return t;
  }

  DateTime? limiteTempo(Tentativa t) {
    final p = publicacao(t.publicacaoId);
    final d = conteudo(p).duracaoMinutos;
    if (d == null) return p.prazo;
    final fim = t.inicio.add(Duration(minutes: d));
    return fim.isBefore(p.prazo) ? fim : p.prazo;
  }

  bool tempoEsgotado(Tentativa t, [DateTime? now]) {
    final limite = limiteTempo(t);
    return limite != null && !(now ?? DateTime.now()).isBefore(limite);
  }

  Future<void> responder(
    String tentativaId,
    String questaoId, {
    String? alternativaId,
    String? texto,
  }) async {
    exigirEstudante();
    final t = tentativa(tentativaId);
    exigir(
      t.estudanteId == uid && t.editavel,
      'A tentativa não pode ser alterada.',
    );
    exigir(!tempoEsgotado(t), 'O tempo da avaliação terminou.');
    final q = conteudo(publicacao(t.publicacaoId)).questao(questaoId);
    exigir(t.ordemQuestoes.contains(q.id), 'Questão inválida.');
    if (alternativaId != null)
      exigir(
        q.alternativas.any((a) => a.id == alternativaId),
        'Alternativa inválida.',
      );
    var r = t.resposta(q.id);
    if (r == null) {
      r = Resposta(
        id: newId(),
        tentativaId: t.id,
        questaoId: q.id,
        respondidaEm: DateTime.now(),
      );
      t.respostas.add(r);
    }
    r.alternativaSelecionadaId = alternativaId;
    r.respostaTexto = texto;
    r.correta = null;
    r.pontuacaoObtida = null;
    r.respondidaEm = DateTime.now();
    await salvar();
  }

  Future<Resultado> enviar(String tentativaId) async {
    exigirEstudante();
    final t = tentativa(tentativaId);
    exigir(t.estudanteId == uid && t.editavel, 'A tentativa já foi enviada.');
    final result = _corrigir(t);
    t.fim = DateTime.now();
    t.status = result.provisorio
        ? StatusTentativa.enviada
        : StatusTentativa.corrigida;
    t.nota = result.nota;
    t.percentualAcerto = result.percentualAcerto;
    resultados.add(result);
    _notificar(
      publicacao(t.publicacaoId).professorId,
      'Nova resposta',
      '${usuario.nome} enviou uma avaliação.',
      TipoNotificacao.novaResposta,
      t.id,
    );
    await salvar();
    return result;
  }

  Resultado _corrigir(Tentativa t) {
    final c = conteudo(publicacao(t.publicacaoId));
    var pontos = 0.0, acertos = 0, erros = 0, brancos = 0;
    var pendente = false;
    for (final item in c.itens) {
      final q = c.questao(item.questaoId);
      final r = t.resposta(q.id);
      if (r == null || !r.respondida) {
        brancos++;
        continue;
      }
      if (r.pontuacaoObtida == null) {
        final correta = q.validarResposta(r);
        r.correta = correta;
        if (correta == null) {
          pendente = true;
        } else {
          r.pontuacaoObtida = correta ? item.pontuacao : 0.0;
        }
      }
      if (r.pontuacaoObtida != null) {
        pontos += r.pontuacaoObtida!;
        if (r.correta == true)
          acertos++;
        else if (r.correta == false)
          erros++;
      }
    }
    final nota = c.totalPontos == 0 ? 0.0 : 10 * pontos / c.totalPontos;
    final percentual = c.itens.isEmpty ? 0.0 : 100 * acertos / c.itens.length;
    return Resultado(
      id: newId(),
      tentativaId: t.id,
      estudanteId: t.estudanteId,
      publicacaoId: t.publicacaoId,
      nota: nota,
      totalQuestoes: c.itens.length,
      acertos: acertos,
      erros: erros,
      emBranco: brancos,
      percentualAcerto: percentual,
      dataConclusao: t.fim ?? DateTime.now(),
      provisorio: pendente,
    );
  }

  Future<void> corrigirResposta(
    String tentativaId,
    String questaoId,
    double pontos,
  ) async {
    exigirProfessor();
    final t = tentativa(tentativaId);
    final p = publicacao(t.publicacaoId);
    exigir(p.professorId == uid && !t.editavel, 'Correção não autorizada.');
    final item = conteudo(p).itens.firstWhere((i) => i.questaoId == questaoId);
    final q = conteudo(p).questao(questaoId);
    exigir(!q.objetiva, 'Use a correção automática para questões objetivas.');
    final r = t.resposta(questaoId);
    exigir(r != null && r.respondida, 'Não há resposta para corrigir.');
    exigir(
      pontos >= 0 && pontos <= item.pontuacao,
      'Pontuação fora do intervalo permitido.',
    );
    r!.pontuacaoObtida = pontos;
    r.correta = pontos == item.pontuacao;
    resultados.removeWhere((e) => e.tentativaId == t.id);
    final resultado = _corrigir(t);
    resultados.add(resultado);
    t.nota = resultado.nota;
    t.percentualAcerto = resultado.percentualAcerto;
    t.status = resultado.provisorio
        ? StatusTentativa.enviada
        : StatusTentativa.corrigida;
    if (!resultado.provisorio)
      _notificar(
        t.estudanteId,
        'Resultado disponível',
        'A correção de ${conteudo(p).titulo} foi concluída.',
        TipoNotificacao.resultadoDisponivel,
        p.id,
      );
    await salvar();
  }

  List<Tentativa> get correcoesPendentes => tentativas
      .where(
        (t) =>
            !t.editavel &&
            resultados.any((r) => r.tentativaId == t.id && r.provisorio) &&
            publicacoes.any(
              (p) => p.id == t.publicacaoId && p.professorId == uid,
            ),
      )
      .toList();
  Resultado? resultadoDaTentativa(String id) {
    for (final r in resultados) {
      if (r.tentativaId == id) return r;
    }
    return null;
  }

  void exigirResultadoVisivel(Tentativa t) {
    exigir(
      t.estudanteId == uid ||
          (professor && publicacao(t.publicacaoId).professorId == uid),
      'Resultado não autorizado.',
    );
    if (!professor)
      exigir(
        publicacao(t.publicacaoId).mostrarResultado,
        'O professor ainda não liberou o resultado.',
      );
  }

  Future<void> marcarLida(String id) async {
    final n = encontrar(notificacoes, id, (n) => n.id);
    exigir(n.usuarioId == uid, 'Notificação não autorizada.');
    n.lida = true;
    await salvar();
  }

  Future<void> marcarTodasLidas() async {
    for (final n in minhasNotificacoes) {
      n.lida = true;
    }
    await salvar();
  }

  void _notificar(
    String id,
    String titulo,
    String mensagem,
    TipoNotificacao tipo,
    String? referencia,
  ) {
    final c = configuracoes[id];
    if (c != null && !c.notificacoesAtivas) return;
    notificacoes.add(
      Notificacao(
        id: newId(),
        usuarioId: id,
        titulo: titulo,
        mensagem: mensagem,
        tipo: tipo,
        dataCriacao: DateTime.now(),
        referenciaId: referencia,
      ),
    );
  }

  MetricasDashboard metricas(
    String publicacaoId, {
    String? turmaId,
    String? estudanteId,
    DateTime? inicio,
    DateTime? fim,
  }) {
    exigirProfessor();
    final p = publicacao(publicacaoId);
    exigir(p.professorId == uid, 'Resultados não autorizados.');
    final ids = <String>{};
    for (final id in p.turmas) {
      if (turmaId == null || turmaId == id) ids.addAll(turma(id).estudanteIds);
    }
    if (estudanteId != null) ids.removeWhere((id) => id != estudanteId);
    final concluidas = tentativasDe(p.id)
        .where(
          (t) =>
              !t.editavel &&
              ids.contains(t.estudanteId) &&
              (inicio == null || !(t.fim ?? t.inicio).isBefore(inicio)) &&
              (fim == null || !(t.fim ?? t.inicio).isAfter(fim)),
        )
        .toList();
    final ultimas = <String, Tentativa>{};
    for (final t in concluidas) {
      final old = ultimas[t.estudanteId];
      if (old == null || t.numeroTentativa > old.numeroTentativa)
        ultimas[t.estudanteId] = t;
    }
    final validos = ultimas.values
        .map(resultadoDaTentativa)
        .whereType<Resultado>()
        .where((r) => !r.provisorio)
        .toList();
    final notas = validos.map((r) => r.nota).toList()..sort();
    final media = notas.isEmpty
        ? null
        : notas.reduce((a, b) => a + b) / notas.length;
    final mediana = notas.isEmpty
        ? null
        : (notas[(notas.length - 1) ~/ 2] + notas[notas.length ~/ 2]) / 2;
    final desvio = media == null
        ? null
        : sqrt(
            notas
                    .map((n) => pow(n - media, 2))
                    .fold<double>(0, (s, n) => s + n) /
                notas.length,
          );
    final faixas = List.generate(
      5,
      (i) => FaixaNota(
        i == 0
            ? '0–2'
            : i == 4
            ? '8–10'
            : '${i * 2}–${i * 2 + 2}',
        notas
            .where((n) => i == 4 ? n >= 8 : n >= i * 2 && n < (i + 1) * 2)
            .length,
      ),
    );
    final desempenhos = <DesempenhoQuestao>[];
    for (final item in conteudo(p).itens) {
      var acertos = 0, erros = 0, brancos = 0;
      for (final t in ultimas.values) {
        final r = t.resposta(item.questaoId);
        if (r == null || !r.respondida) {
          brancos++;
        } else if (r.correta == true) {
          acertos++;
        } else if (r.correta == false) {
          erros++;
        }
      }
      desempenhos.add(
        DesempenhoQuestao(
          questaoId: item.questaoId,
          totalRespostas: ultimas.length,
          totalAcertos: acertos,
          totalErros: erros,
          totalEmBranco: brancos,
        ),
      );
    }
    return MetricasDashboard(
      publicacaoId: p.id,
      media: media,
      mediana: mediana,
      maiorNota: notas.isEmpty ? null : notas.last,
      menorNota: notas.isEmpty ? null : notas.first,
      desvioPadrao: desvio,
      totalEstudantes: ids.length,
      totalRespondentes: ultimas.length,
      distribuicaoNotas: faixas,
      desempenhoQuestoes: desempenhos,
    );
  }

  void _semear() {
    final now = DateTime.now();
    const professorId = 'demo-professor', estudanteId = 'demo-estudante';
    usuarios.addAll([
      Professor(
        id: professorId,
        nome: 'Ana Silva',
        email: 'ana.silva@escola.com.br',
        senhaHash: novoHash('12345678'),
      ),
      Estudante(
        id: estudanteId,
        nome: 'Lucas Silva',
        email: 'lucas.silva@aluno.com',
        senhaHash: novoHash('12345678'),
      ),
    ]);
    for (final u in usuarios) {
      configuracoes[u.id] = ConfiguracaoUsuario(usuarioId: u.id);
    }
    final t = Turma(
      id: 'demo-turma',
      nome: 'Turma 3A — Programação',
      disciplina: 'Python',
      professorId: professorId,
      codigoConvite: 'TRM-3A2024',
      dataCriacao: now,
      estudanteIds: [estudanteId],
    );
    turmas.add(t);
    final dados = [
      [
        'Qual é o resultado de soma(5, 3), se soma retorna a + b?',
        '8',
        '5',
        '3',
        '15',
      ],
      [
        'Qual palavra-chave define uma função em Python?',
        'def',
        'function',
        'fun',
        'method',
      ],
      [
        'O operador // em Python realiza divisão inteira.',
        'Verdadeiro',
        'Falso',
      ],
      ['Explique a diferença entre uma lista e uma tupla em Python.'],
    ];
    for (var i = 0; i < dados.length; i++) {
      final d = dados[i];
      final alternativas = i == 3
          ? <Alternativa>[]
          : List.generate(
              d.length - 1,
              (j) => Alternativa(
                id: 'demo-q${i + 1}-a$j',
                texto: d[j + 1],
                ordem: j,
                correta: j == 0,
              ),
            );
      questoes.add(
        Questao(
          id: 'demo-q${i + 1}',
          professorId: professorId,
          enunciado: d[0],
          disciplina: 'Python',
          tipo: i == 3
              ? TipoQuestao.dissertativa
              : i == 2
              ? TipoQuestao.verdadeiroFalso
              : TipoQuestao.multiplaEscolha,
          alternativas: alternativas,
          dataCriacao: now,
          dataAtualizacao: now,
          explicacao: i == 0 ? 'A soma de 5 e 3 é 8.' : null,
        ),
      );
    }
    final q = Questionario(
      id: 'demo-questionario',
      professorId: professorId,
      titulo: 'Avaliação de Python — Funções',
      descricao: 'Avalie seus conhecimentos de funções, operadores e estruturas de dados.',
      dataCriacao: now,
      dataAtualizacao: now,
      duracaoMinutos: 45,
      itens: List.generate(
        4,
        (i) => ItemQuestionario(
          id: 'demo-item$i',
          questionarioId: 'demo-questionario',
          questaoId: 'demo-q${i + 1}',
          ordem: i,
          pontuacao: i == 3 ? 4 : 2,
        ),
      ),
    );
    questionarios.add(q);
    publicacoes.add(
      PublicacaoQuestionario(
        id: 'demo-publicacao',
        questionarioId: q.id,
        professorId: professorId,
        turmas: [t.id],
        inicioDisponibilidade: now.subtract(const Duration(days: 1)),
        prazo: now.add(const Duration(days: 7)),
        limiteTentativas: 2,
        mostrarResultado: true,
        embaralharQuestoes: false,
        dataPublicacao: now,
        conteudo: ConteudoAvaliacao(
          titulo: q.titulo,
          descricao: q.descricao,
          duracaoMinutos: q.duracaoMinutos,
          itens: decodeList(
            q.itens.map((e) => e.toJson()).toList(),
            ItemQuestionario.fromJson,
          ),
          questoes: questoes.map((e) => e.snapshot()).toList(),
        ),
      ),
    );
    _notificar(
      estudanteId,
      'Nova avaliação publicada',
      q.titulo,
      TipoNotificacao.novaAvaliacao,
      'demo-publicacao',
    );
  }
}
