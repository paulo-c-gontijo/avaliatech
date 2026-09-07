import 'dart:convert';
import 'dart:math';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
DateTime? parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
String? dateJson(DateTime? value) => value?.toUtc().toIso8601String();
List<String> strings(Object? value) => (value as List? ?? []).cast<String>();
List<T> decodeList<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    (value as List? ?? [])
        .map((e) => parse(Map<String, dynamic>.from(e as Map)))
        .toList();

enum TipoQuestao {
  multiplaEscolha,
  verdadeiroFalso,
  respostaCurta,
  dissertativa,
}

enum StatusPublicacao { agendada, disponivel, encerrada, cancelada }

enum StatusTentativa { emAndamento, enviada, corrigida, expirada }

enum StatusConvite { pendente, aceito, recusado, expirado, cancelado }

enum TipoNotificacao {
  conviteTurma,
  novaAvaliacao,
  prazoProximo,
  resultadoDisponivel,
  novaResposta,
  publicacaoEncerrada,
  sistema,
}

enum Papel { professor, estudante }

abstract class Usuario {
  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    this.fotoPerfilUrl,
    this.ativo = true,
  });
  final String id;
  String nome, email, senhaHash;
  String? fotoPerfilUrl;
  bool ativo;
  Papel get papel;
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'senhaHash': senhaHash,
    'fotoPerfilUrl': fotoPerfilUrl,
    'ativo': ativo,
    'papel': papel.name,
  };
  void atualizarPerfil(String nome, String email) {
    this.nome = nome.trim();
    this.email = email.trim().toLowerCase();
  }

  void alterarSenha(String hash) => senhaHash = hash;
}

class Professor extends Usuario {
  Professor({
    required super.id,
    required super.nome,
    required super.email,
    required super.senhaHash,
    super.fotoPerfilUrl,
    super.ativo,
  });
  @override
  Papel get papel => Papel.professor;
  factory Professor.fromJson(Map<String, dynamic> j) => Professor(
    id: j['id'],
    nome: j['nome'],
    email: j['email'],
    senhaHash: j['senhaHash'] ?? '',
    fotoPerfilUrl: j['fotoPerfilUrl'],
    ativo: j['ativo'] ?? true,
  );
}

class Estudante extends Usuario {
  Estudante({
    required super.id,
    required super.nome,
    required super.email,
    required super.senhaHash,
    super.fotoPerfilUrl,
    super.ativo,
  });
  @override
  Papel get papel => Papel.estudante;
  factory Estudante.fromJson(Map<String, dynamic> j) => Estudante(
    id: j['id'],
    nome: j['nome'],
    email: j['email'],
    senhaHash: j['senhaHash'] ?? '',
    fotoPerfilUrl: j['fotoPerfilUrl'],
    ativo: j['ativo'] ?? true,
  );
}

Usuario usuarioFromJson(Map<String, dynamic> j) =>
    j['papel'] == 'professor' ? Professor.fromJson(j) : Estudante.fromJson(j);

class Turma {
  Turma({
    required this.id,
    required this.nome,
    required this.disciplina,
    required this.professorId,
    required this.codigoConvite,
    required this.dataCriacao,
    List<String>? estudanteIds,
    this.ativa = true,
  }) : estudanteIds = estudanteIds ?? [];
  final String id, professorId;
  String nome, disciplina, codigoConvite;
  DateTime dataCriacao;
  List<String> estudanteIds;
  bool ativa;
  void adicionarEstudante(String id) {
    if (!estudanteIds.contains(id)) estudanteIds.add(id);
  }

  void removerEstudante(String id) => estudanteIds.remove(id);
  void arquivar() => ativa = false;
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'disciplina': disciplina,
    'professorId': professorId,
    'codigoConvite': codigoConvite,
    'dataCriacao': dateJson(dataCriacao),
    'estudanteIds': estudanteIds,
    'ativa': ativa,
  };
  factory Turma.fromJson(Map<String, dynamic> j) => Turma(
    id: j['id'],
    nome: j['nome'],
    disciplina: j['disciplina'],
    professorId: j['professorId'],
    codigoConvite: j['codigoConvite'],
    dataCriacao: parseDate(j['dataCriacao'])!,
    estudanteIds: strings(j['estudanteIds']),
    ativa: j['ativa'] ?? true,
  );
}

class ConviteTurma {
  ConviteTurma({
    required this.id,
    required this.turmaId,
    required this.estudanteId,
    required this.professorId,
    required this.dataEnvio,
    this.dataExpiracao,
    this.status = StatusConvite.pendente,
  });
  final String id, turmaId, estudanteId, professorId;
  final DateTime dataEnvio;
  DateTime? dataExpiracao;
  StatusConvite status;
  bool expirou([DateTime? now]) =>
      dataExpiracao != null &&
      !(now ?? DateTime.now()).isBefore(dataExpiracao!);
  Map<String, dynamic> toJson() => {
    'id': id,
    'turmaId': turmaId,
    'estudanteId': estudanteId,
    'professorId': professorId,
    'dataEnvio': dateJson(dataEnvio),
    'dataExpiracao': dateJson(dataExpiracao),
    'status': status.name,
  };
  factory ConviteTurma.fromJson(Map<String, dynamic> j) => ConviteTurma(
    id: j['id'],
    turmaId: j['turmaId'],
    estudanteId: j['estudanteId'],
    professorId: j['professorId'],
    dataEnvio: parseDate(j['dataEnvio'])!,
    dataExpiracao: parseDate(j['dataExpiracao']),
    status: StatusConvite.values.byName(j['status']),
  );
}

class Alternativa {
  Alternativa({
    required this.id,
    required this.texto,
    required this.ordem,
    this.correta = false,
  });
  final String id;
  String texto;
  int ordem;
  bool correta;
  Map<String, dynamic> toJson() => {
    'id': id,
    'texto': texto,
    'ordem': ordem,
    'correta': correta,
  };
  factory Alternativa.fromJson(Map<String, dynamic> j) => Alternativa(
    id: j['id'],
    texto: j['texto'],
    ordem: j['ordem'],
    correta: j['correta'] ?? false,
  );
}

class Questao {
  Questao({
    required this.id,
    required this.professorId,
    required this.enunciado,
    required this.disciplina,
    required this.tipo,
    required this.dataCriacao,
    required this.dataAtualizacao,
    List<Alternativa>? alternativas,
    this.respostaCorreta,
    this.explicacao,
    this.ativa = true,
  }) : alternativas = alternativas ?? [];
  final String id, professorId;
  String enunciado, disciplina;
  TipoQuestao tipo;
  List<Alternativa> alternativas;
  String? respostaCorreta, explicacao;
  DateTime dataCriacao, dataAtualizacao;
  bool ativa;
  bool get objetiva =>
      tipo == TipoQuestao.multiplaEscolha ||
      tipo == TipoQuestao.verdadeiroFalso;
  void validar() {
    if (enunciado.trim().isEmpty || disciplina.trim().isEmpty)
      throw StateError('Preencha o enunciado e a disciplina.');
    if (objetiva &&
        (alternativas.length < 2 ||
            alternativas.where((a) => a.correta).length != 1 ||
            alternativas.any((a) => a.texto.trim().isEmpty)))
      throw StateError(
        'A questão objetiva precisa de alternativas válidas e exatamente uma correta.',
      );
  }

  bool? validarResposta(Resposta r) {
    if (objetiva)
      return alternativas.any(
        (a) => a.id == r.alternativaSelecionadaId && a.correta,
      );
    if (tipo == TipoQuestao.respostaCurta &&
        respostaCorreta != null &&
        respostaCorreta!.trim().isNotEmpty)
      return r.respostaTexto?.trim().toLowerCase() ==
          respostaCorreta!.trim().toLowerCase();
    return null;
  }

  Questao snapshot() => Questao.fromJson(toJson());
  Map<String, dynamic> toJson() => {
    'id': id,
    'professorId': professorId,
    'enunciado': enunciado,
    'disciplina': disciplina,
    'tipo': tipo.name,
    'alternativas': alternativas.map((e) => e.toJson()).toList(),
    'respostaCorreta': respostaCorreta,
    'explicacao': explicacao,
    'dataCriacao': dateJson(dataCriacao),
    'dataAtualizacao': dateJson(dataAtualizacao),
    'ativa': ativa,
  };
  factory Questao.fromJson(Map<String, dynamic> j) => Questao(
    id: j['id'],
    professorId: j['professorId'],
    enunciado: j['enunciado'],
    disciplina: j['disciplina'],
    tipo: TipoQuestao.values.byName(j['tipo']),
    alternativas: decodeList(j['alternativas'], Alternativa.fromJson),
    respostaCorreta: j['respostaCorreta'],
    explicacao: j['explicacao'],
    dataCriacao: parseDate(j['dataCriacao'])!,
    dataAtualizacao: parseDate(j['dataAtualizacao'])!,
    ativa: j['ativa'] ?? true,
  );
}

class ItemQuestionario {
  ItemQuestionario({
    required this.id,
    required this.questionarioId,
    required this.questaoId,
    required this.ordem,
    required this.pontuacao,
  });
  final String id, questionarioId, questaoId;
  int ordem;
  double pontuacao;
  Map<String, dynamic> toJson() => {
    'id': id,
    'questionarioId': questionarioId,
    'questaoId': questaoId,
    'ordem': ordem,
    'pontuacao': pontuacao,
  };
  factory ItemQuestionario.fromJson(Map<String, dynamic> j) => ItemQuestionario(
    id: j['id'],
    questionarioId: j['questionarioId'],
    questaoId: j['questaoId'],
    ordem: j['ordem'],
    pontuacao: (j['pontuacao'] as num).toDouble(),
  );
}

class Questionario {
  Questionario({
    required this.id,
    required this.professorId,
    required this.titulo,
    required this.descricao,
    required this.dataCriacao,
    required this.dataAtualizacao,
    List<ItemQuestionario>? itens,
    this.duracaoMinutos,
    this.embaralharQuestoes = false,
    this.ativo = true,
  }) : itens = itens ?? [];
  final String id, professorId;
  String titulo, descricao;
  List<ItemQuestionario> itens;
  int? duracaoMinutos;
  bool embaralharQuestoes, ativo;
  DateTime dataCriacao, dataAtualizacao;
  double get totalPontos => itens.fold(0, (s, i) => s + i.pontuacao);
  void validar() {
    if (titulo.trim().isEmpty ||
        itens.isEmpty ||
        itens.any((i) => i.pontuacao <= 0))
      throw StateError(
        'Informe um título e pelo menos uma questão com pontuação positiva.',
      );
    if (duracaoMinutos != null && duracaoMinutos! <= 0)
      throw StateError('A duração deve ser positiva.');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'professorId': professorId,
    'titulo': titulo,
    'descricao': descricao,
    'itens': itens.map((e) => e.toJson()).toList(),
    'duracaoMinutos': duracaoMinutos,
    'embaralharQuestoes': embaralharQuestoes,
    'dataCriacao': dateJson(dataCriacao),
    'dataAtualizacao': dateJson(dataAtualizacao),
    'ativo': ativo,
  };
  factory Questionario.fromJson(Map<String, dynamic> j) => Questionario(
    id: j['id'],
    professorId: j['professorId'],
    titulo: j['titulo'],
    descricao: j['descricao'],
    itens: decodeList(j['itens'], ItemQuestionario.fromJson),
    duracaoMinutos: j['duracaoMinutos'],
    embaralharQuestoes: j['embaralharQuestoes'] ?? false,
    dataCriacao: parseDate(j['dataCriacao'])!,
    dataAtualizacao: parseDate(j['dataAtualizacao'])!,
    ativo: j['ativo'] ?? true,
  );
}

class PublicacaoQuestionario {
  PublicacaoQuestionario({
    required this.id,
    required this.questionarioId,
    required this.professorId,
    required this.turmas,
    required this.inicioDisponibilidade,
    required this.prazo,
    required this.limiteTentativas,
    required this.mostrarResultado,
    required this.embaralharQuestoes,
    required this.dataPublicacao,
    this.status = StatusPublicacao.agendada,
    this.conteudo,
  });
  final String id, questionarioId, professorId;
  List<String> turmas;
  DateTime inicioDisponibilidade, prazo, dataPublicacao;
  int limiteTentativas;
  bool mostrarResultado, embaralharQuestoes;
  StatusPublicacao status;
  ConteudoAvaliacao? conteudo;
  StatusPublicacao estado([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (status == StatusPublicacao.cancelada ||
        status == StatusPublicacao.encerrada)
      return status;
    if (t.isBefore(inicioDisponibilidade)) return StatusPublicacao.agendada;
    if (!t.isBefore(prazo)) return StatusPublicacao.encerrada;
    return StatusPublicacao.disponivel;
  }

  bool estaDisponivel([DateTime? now]) =>
      estado(now) == StatusPublicacao.disponivel;
  void validar() {
    if (turmas.isEmpty ||
        limiteTentativas < 1 ||
        !prazo.isAfter(inicioDisponibilidade))
      throw StateError(
        'Selecione turmas, um prazo válido e pelo menos uma tentativa.',
      );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionarioId': questionarioId,
    'professorId': professorId,
    'turmas': turmas,
    'inicioDisponibilidade': dateJson(inicioDisponibilidade),
    'prazo': dateJson(prazo),
    'limiteTentativas': limiteTentativas,
    'mostrarResultado': mostrarResultado,
    'embaralharQuestoes': embaralharQuestoes,
    'status': status.name,
    'dataPublicacao': dateJson(dataPublicacao),
    'conteudo': conteudo?.toJson(),
  };
  factory PublicacaoQuestionario.fromJson(Map<String, dynamic> j) =>
      PublicacaoQuestionario(
        id: j['id'],
        questionarioId: j['questionarioId'],
        professorId: j['professorId'],
        turmas: strings(j['turmas']),
        inicioDisponibilidade: parseDate(j['inicioDisponibilidade'])!,
        prazo: parseDate(j['prazo'])!,
        limiteTentativas: j['limiteTentativas'],
        mostrarResultado: j['mostrarResultado'],
        embaralharQuestoes: j['embaralharQuestoes'],
        status: StatusPublicacao.values.byName(j['status']),
        dataPublicacao: parseDate(j['dataPublicacao'])!,
        conteudo: j['conteudo'] == null
            ? null
            : ConteudoAvaliacao.fromJson(
                Map<String, dynamic>.from(j['conteudo']),
              ),
      );
}

// Snapshot imutável do conteúdo publicado. Editar o banco nunca altera provas históricas.
class ConteudoAvaliacao {
  ConteudoAvaliacao({
    required this.titulo,
    required this.descricao,
    required this.duracaoMinutos,
    required this.itens,
    required this.questoes,
  });
  final String titulo, descricao;
  final int? duracaoMinutos;
  final List<ItemQuestionario> itens;
  final List<Questao> questoes;
  double get totalPontos => itens.fold(0, (s, i) => s + i.pontuacao);
  Questao questao(String id) => questoes.firstWhere((q) => q.id == id);
  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    'duracaoMinutos': duracaoMinutos,
    'itens': itens.map((e) => e.toJson()).toList(),
    'questoes': questoes.map((e) => e.toJson()).toList(),
  };
  factory ConteudoAvaliacao.fromJson(Map<String, dynamic> j) =>
      ConteudoAvaliacao(
        titulo: j['titulo'],
        descricao: j['descricao'],
        duracaoMinutos: j['duracaoMinutos'],
        itens: decodeList(j['itens'], ItemQuestionario.fromJson),
        questoes: decodeList(j['questoes'], Questao.fromJson),
      );
}

class Resposta {
  Resposta({
    required this.id,
    required this.tentativaId,
    required this.questaoId,
    required this.respondidaEm,
    this.alternativaSelecionadaId,
    this.respostaTexto,
    this.correta,
    this.pontuacaoObtida,
  });
  final String id, tentativaId, questaoId;
  String? alternativaSelecionadaId, respostaTexto;
  bool? correta;
  double? pontuacaoObtida;
  DateTime respondidaEm;
  bool get respondida =>
      alternativaSelecionadaId != null ||
      (respostaTexto?.trim().isNotEmpty ?? false);
  Map<String, dynamic> toJson() => {
    'id': id,
    'tentativaId': tentativaId,
    'questaoId': questaoId,
    'alternativaSelecionadaId': alternativaSelecionadaId,
    'respostaTexto': respostaTexto,
    'correta': correta,
    'pontuacaoObtida': pontuacaoObtida,
    'respondidaEm': dateJson(respondidaEm),
  };
  factory Resposta.fromJson(Map<String, dynamic> j) => Resposta(
    id: j['id'],
    tentativaId: j['tentativaId'],
    questaoId: j['questaoId'],
    alternativaSelecionadaId: j['alternativaSelecionadaId'],
    respostaTexto: j['respostaTexto'],
    correta: j['correta'],
    pontuacaoObtida: (j['pontuacaoObtida'] as num?)?.toDouble(),
    respondidaEm: parseDate(j['respondidaEm'])!,
  );
}

class Tentativa {
  Tentativa({
    required this.id,
    required this.estudanteId,
    required this.publicacaoId,
    required this.numeroTentativa,
    required this.inicio,
    List<Resposta>? respostas,
    List<String>? ordemQuestoes,
    this.fim,
    this.status = StatusTentativa.emAndamento,
    this.nota,
    this.percentualAcerto,
  }) : respostas = respostas ?? [],
       ordemQuestoes = ordemQuestoes ?? [];
  final String id, estudanteId, publicacaoId;
  final int numeroTentativa;
  final DateTime inicio;
  DateTime? fim;
  StatusTentativa status;
  double? nota, percentualAcerto;
  List<Resposta> respostas;
  List<String> ordemQuestoes;
  bool get editavel => status == StatusTentativa.emAndamento;
  Resposta? resposta(String questaoId) {
    for (final r in respostas) {
      if (r.questaoId == questaoId) return r;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'estudanteId': estudanteId,
    'publicacaoId': publicacaoId,
    'respostas': respostas.map((e) => e.toJson()).toList(),
    'ordemQuestoes': ordemQuestoes,
    'numeroTentativa': numeroTentativa,
    'inicio': dateJson(inicio),
    'fim': dateJson(fim),
    'status': status.name,
    'nota': nota,
    'percentualAcerto': percentualAcerto,
  };
  factory Tentativa.fromJson(Map<String, dynamic> j) => Tentativa(
    id: j['id'],
    estudanteId: j['estudanteId'],
    publicacaoId: j['publicacaoId'],
    respostas: decodeList(j['respostas'], Resposta.fromJson),
    ordemQuestoes: strings(j['ordemQuestoes']),
    numeroTentativa: j['numeroTentativa'],
    inicio: parseDate(j['inicio'])!,
    fim: parseDate(j['fim']),
    status: StatusTentativa.values.byName(j['status']),
    nota: (j['nota'] as num?)?.toDouble(),
    percentualAcerto: (j['percentualAcerto'] as num?)?.toDouble(),
  );
}

class Resultado {
  Resultado({
    required this.id,
    required this.tentativaId,
    required this.estudanteId,
    required this.publicacaoId,
    required this.nota,
    required this.totalQuestoes,
    required this.acertos,
    required this.erros,
    required this.emBranco,
    required this.percentualAcerto,
    required this.dataConclusao,
    this.provisorio = false,
  });
  final String id, tentativaId, estudanteId, publicacaoId;
  final double nota, percentualAcerto;
  final int totalQuestoes, acertos, erros, emBranco;
  final DateTime dataConclusao;
  final bool provisorio;
  Map<String, dynamic> toJson() => {
    'id': id,
    'tentativaId': tentativaId,
    'estudanteId': estudanteId,
    'publicacaoId': publicacaoId,
    'nota': nota,
    'totalQuestoes': totalQuestoes,
    'acertos': acertos,
    'erros': erros,
    'emBranco': emBranco,
    'percentualAcerto': percentualAcerto,
    'dataConclusao': dateJson(dataConclusao),
    'provisorio': provisorio,
  };
  factory Resultado.fromJson(Map<String, dynamic> j) => Resultado(
    id: j['id'],
    tentativaId: j['tentativaId'],
    estudanteId: j['estudanteId'],
    publicacaoId: j['publicacaoId'],
    nota: (j['nota'] as num).toDouble(),
    totalQuestoes: j['totalQuestoes'],
    acertos: j['acertos'],
    erros: j['erros'],
    emBranco: j['emBranco'],
    percentualAcerto: (j['percentualAcerto'] as num).toDouble(),
    dataConclusao: parseDate(j['dataConclusao'])!,
    provisorio: j['provisorio'] ?? false,
  );
}

class Notificacao {
  Notificacao({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.dataCriacao,
    this.lida = false,
    this.referenciaId,
  });
  final String id, usuarioId, titulo, mensagem;
  final TipoNotificacao tipo;
  final DateTime dataCriacao;
  bool lida;
  final String? referenciaId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioId': usuarioId,
    'titulo': titulo,
    'mensagem': mensagem,
    'tipo': tipo.name,
    'dataCriacao': dateJson(dataCriacao),
    'lida': lida,
    'referenciaId': referenciaId,
  };
  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
    id: j['id'],
    usuarioId: j['usuarioId'],
    titulo: j['titulo'],
    mensagem: j['mensagem'],
    tipo: TipoNotificacao.values.byName(j['tipo']),
    dataCriacao: parseDate(j['dataCriacao'])!,
    lida: j['lida'] ?? false,
    referenciaId: j['referenciaId'],
  );
}

class ConfiguracaoUsuario {
  ConfiguracaoUsuario({
    required this.usuarioId,
    this.notificacoesAtivas = true,
    this.notificacaoNovaAvaliacao = true,
    this.notificacaoPrazo = true,
    this.notificacaoResultado = true,
    this.temaEscuro = false,
  });
  final String usuarioId;
  bool notificacoesAtivas,
      notificacaoNovaAvaliacao,
      notificacaoPrazo,
      notificacaoResultado,
      temaEscuro;
  Map<String, dynamic> toJson() => {
    'usuarioId': usuarioId,
    'notificacoesAtivas': notificacoesAtivas,
    'notificacaoNovaAvaliacao': notificacaoNovaAvaliacao,
    'notificacaoPrazo': notificacaoPrazo,
    'notificacaoResultado': notificacaoResultado,
    'temaEscuro': temaEscuro,
  };
  factory ConfiguracaoUsuario.fromJson(Map<String, dynamic> j) =>
      ConfiguracaoUsuario(
        usuarioId: j['usuarioId'],
        notificacoesAtivas: j['notificacoesAtivas'] ?? true,
        notificacaoNovaAvaliacao: j['notificacaoNovaAvaliacao'] ?? true,
        notificacaoPrazo: j['notificacaoPrazo'] ?? true,
        notificacaoResultado: j['notificacaoResultado'] ?? true,
        temaEscuro: j['temaEscuro'] ?? false,
      );
}

class FaixaNota {
  FaixaNota(this.rotulo, this.quantidade);
  final String rotulo;
  final int quantidade;
}

class DesempenhoQuestao {
  DesempenhoQuestao({
    required this.questaoId,
    required this.totalRespostas,
    required this.totalAcertos,
    required this.totalErros,
    required this.totalEmBranco,
  });
  final String questaoId;
  final int totalRespostas, totalAcertos, totalErros, totalEmBranco;
  double get percentualAcerto =>
      totalRespostas == 0 ? 0 : 100 * totalAcertos / totalRespostas;
  double get percentualErro =>
      totalRespostas == 0 ? 0 : 100 * totalErros / totalRespostas;
}

class MetricasDashboard {
  MetricasDashboard({
    required this.publicacaoId,
    required this.media,
    required this.mediana,
    required this.maiorNota,
    required this.menorNota,
    required this.desvioPadrao,
    required this.totalEstudantes,
    required this.totalRespondentes,
    required this.distribuicaoNotas,
    required this.desempenhoQuestoes,
  });
  final String publicacaoId;
  final double? media, mediana, maiorNota, menorNota, desvioPadrao;
  final int totalEstudantes, totalRespondentes;
  final List<FaixaNota> distribuicaoNotas;
  final List<DesempenhoQuestao> desempenhoQuestoes;
  double get taxaParticipacao =>
      totalEstudantes == 0 ? 0 : 100 * totalRespondentes / totalEstudantes;
}
