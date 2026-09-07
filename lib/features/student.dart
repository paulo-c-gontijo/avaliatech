import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/avaliation_store.dart';
import '../domain/models.dart';
import '../ui/common.dart';
import 'results.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final available =
        s.minhasPublicacoes
            .where(
              (p) =>
                  p.estaDisponivel() &&
                  (s.podeIniciar(p) || s.tentativaEmAndamento(p.id) != null),
            )
            .toList()
          ..sort((a, b) => a.prazo.compareTo(b.prazo));
    final invites = s.convites
        .where(
          (c) =>
              c.estudanteId == s.uid &&
              c.status == StatusConvite.pendente &&
              !c.expirou(),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Olá, ${s.usuario.nome.split(' ').first}!',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pronto para aprender algo novo?',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Próxima Avaliação'),
        if (available.isEmpty)
          const EmptyState(
            'Tudo em dia!',
            'Nenhuma avaliação disponível no momento.',
            icon: Icons.task_alt,
          )
        else
          StudentAssessmentCard(available.first, highlight: true),
        const SizedBox(height: 22),
        SectionTitle(
          'Minhas Turmas',
          trailing: TextButton(
            onPressed: () => AppNav.go(context, 1),
            child: const Text('Ver todas'),
          ),
        ),
        if (s.minhasTurmas.isEmpty)
          const EmptyState(
            'Você ainda não está em uma turma',
            'Entre com o código fornecido pelo professor.',
          )
        else
          ...s.minhasTurmas
              .take(3)
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: InkWell(
                      onTap: () => openPage(context, StudentClassDetails(t.id)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: .1,
                            ),
                            child: const Icon(
                              Icons.groups_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  t.disciplina,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        SectionTitle(
          'Pendências',
          trailing: AppTag('${available.length + invites.length}'),
        ),
        for (final c in invites)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Convite: ${s.turma(c.turmaId).nome}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  ActionRow(
                    children: [
                      AppButton(
                        'Recusar',
                        outlined: true,
                        onPressed: () => runAction(
                          context,
                          () => s.responderConvite(c.id, false),
                        ),
                      ),
                      AppButton(
                        'Aceitar',
                        onPressed: () => runAction(
                          context,
                          () => s.responderConvite(c.id, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (available.length > 1)
          ...available.skip(1).take(3).map((p) => StudentAssessmentCard(p)),
        if (invites.isEmpty && available.length <= 1)
          const Text(
            'Sem outras pendências.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
      ],
    );
  }
}

class StudentClasses extends StatefulWidget {
  const StudentClasses({super.key});
  @override
  State<StudentClasses> createState() => _StudentClassesState();
}

class _StudentClassesState extends State<StudentClasses> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.minhasTurmas
        .where(
          (t) => '${t.nome} ${t.disciplina}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            SearchField(
              hint: 'Buscar turma...',
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const EmptyState(
                'Nenhuma turma encontrada',
                'Entre em uma turma com o código de convite.',
              )
            else
              ...list.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: InkWell(
                      onTap: () => openPage(context, StudentClassDetails(t.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              AppTag(t.disciplina),
                              const Spacer(),
                              Text(
                                '${t.estudanteIds.length} alunos',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Prof. ${s.usuarioPorId(t.professorId).nome}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () => openPage(context, const JoinClassPage()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});
  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppPage(
      title: 'Entrar em uma Turma',
      child: Column(
        children: [
          const Panel(
            child: Text(
              'Peça ao professor o código da turma. No modo de demonstração, a turma e a conta precisam estar cadastradas no mesmo dispositivo.',
            ),
          ),
          const SizedBox(height: 18),
          AppField('Código da Turma', controller: code, hint: 'TRM-XXXXXX'),
          const SizedBox(height: 22),
          AppButton(
            'Entrar na Turma',
            onPressed: () async {
              final ok = await runAction(
                context,
                () => s.entrarNaTurma(code.text).then((_) => true),
                success: 'Você entrou na turma.',
              );
              if (ok == true && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class StudentClassDetails extends StatelessWidget {
  const StudentClassDetails(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.turma(id);
    final pubs = s.minhasPublicacoes
        .where((p) => p.turmas.contains(t.id))
        .toList();
    return AppPage(
      title: t.nome,
      subtitle: t.disciplina,
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'sair' &&
                await confirmAction(
                  context,
                  'Sair da turma',
                  'Você deixará de visualizar as novas avaliações desta turma.',
                  confirm: 'Sair',
                  destructive: true,
                )) {
              if (context.mounted) {
                final ok = await runAction(
                  context,
                  () => s.sairDaTurma(t.id).then((_) => true),
                );
                if (ok == true && context.mounted) Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'sair', child: Text('Sair da turma')),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações da Turma',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                InfoRow('Professor', s.usuarioPorId(t.professorId).nome),
                InfoRow('Disciplina', t.disciplina),
                InfoRow('Alunos', '${t.estudanteIds.length}'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Avaliações da Turma'),
          if (pubs.isEmpty)
            const EmptyState(
              'Nenhuma avaliação',
              'O professor ainda não publicou atividades para esta turma.',
            )
          else
            ...pubs.map((p) => StudentAssessmentCard(p)),
        ],
      ),
    );
  }
}

class StudentEvaluations extends StatefulWidget {
  const StudentEvaluations({super.key});
  @override
  State<StudentEvaluations> createState() => _StudentEvaluationsState();
}

class _StudentEvaluationsState extends State<StudentEvaluations> {
  int tab = 0;
  String search = '';
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list =
        s.minhasPublicacoes
            .where(
              (p) =>
                  s
                      .conteudo(p)
                      .titulo
                      .toLowerCase()
                      .contains(search.toLowerCase()) &&
                  (tab == 0
                      ? s
                            .tentativasDe(p.id, estudanteId: s.uid)
                            .every((t) => t.editavel)
                      : s
                            .tentativasDe(p.id, estudanteId: s.uid)
                            .any((t) => !t.editavel)),
            )
            .toList()
          ..sort((a, b) => a.prazo.compareTo(b.prazo));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Pendentes')),
            ButtonSegment(value: 1, label: Text('Concluídas')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 16),
        SearchField(
          hint: 'Buscar avaliação...',
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          EmptyState(
            tab == 0
                ? 'Nenhuma avaliação pendente'
                : 'Nenhuma avaliação concluída',
            tab == 0 ? 'Suas próximas atividades aparecerão aqui.' : 'Quando você enviar uma avaliação, ela aparecerá no histórico.',
          )
        else
          ...list.map((p) => StudentAssessmentCard(p, completed: tab == 1)),
      ],
    );
  }
}

class StudentAssessmentCard extends StatelessWidget {
  const StudentAssessmentCard(
    this.p, {
    super.key,
    this.highlight = false,
    this.completed = false,
  });
  final PublicacaoQuestionario p;
  final bool highlight, completed;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.conteudo(p);
    final attempts = s.tentativasDe(p.id, estudanteId: s.uid);
    final done = attempts.where((t) => !t.editavel).toList();
    final open = s.tentativaEmAndamento(p.id);
    final status = p.estado();
    final exhausted = attempts.length >= p.limiteTentativas && open == null;
    final canStart = s.podeIniciar(p) || open != null;
    final label = open != null
        ? 'Continuar'
        : status == StatusPublicacao.agendada
        ? 'Agendada'
        : status == StatusPublicacao.encerrada
        ? 'Encerrada'
        : exhausted
        ? 'Limite atingido'
        : 'Responder';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        color: highlight ? AppColors.primary.withValues(alpha: .035) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                AppTag(
                  completed ? 'Concluída' : statusLabel(status),
                  color: completed
                      ? AppColors.success
                      : status == StatusPublicacao.disponivel
                      ? AppColors.success
                      : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              c.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 7,
              children: [
                _SmallInfo(Icons.quiz_outlined, '${c.itens.length} questões'),
                _SmallInfo(
                  Icons.timer_outlined,
                  c.duracaoMinutos == null
                      ? 'Sem duração'
                      : '${c.duracaoMinutos} min',
                ),
                _SmallInfo(Icons.event_outlined, shortDate(p.prazo)),
              ],
            ),
            const SizedBox(height: 12),
            if (completed && done.isNotEmpty) ...[
              Text(
                '${done.length} tentativa(s) enviada(s)',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...done.reversed.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: AppButton(
                    'Tentativa ${t.numeroTentativa} • ${p.mostrarResultado ? (s.resultadoDaTentativa(t.id)?.provisorio == true ? 'Em correção' : 'Nota ${score(s.resultadoDaTentativa(t.id)?.nota)}') : 'Resultado oculto'}',
                    outlined: true,
                    onPressed: () => openPage(context, AttemptResultPage(t.id)),
                  ),
                ),
              ),
              if (canStart)
                AppButton(
                  'Nova tentativa',
                  onPressed: () =>
                      openPage(context, AssessmentInstructions(p.id)),
                ),
            ] else
              AppButton(
                label,
                icon: Icons.play_arrow_rounded,
                onPressed: canStart
                    ? () => openPage(context, AssessmentInstructions(p.id))
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.muted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ],
  );
}

class AssessmentInstructions extends StatelessWidget {
  const AssessmentInstructions(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.publicacao(id);
    final c = s.conteudo(p);
    final open = s.tentativaEmAndamento(p.id);
    final count = s.tentativasDe(p.id, estudanteId: s.uid).length;
    final canStart = s.podeIniciar(p) || open != null;
    return AppPage(
      title: 'Instruções da Avaliação',
      showNavigation: false,
      bottom: AppButton(
        open != null ? 'Continuar Avaliação' : 'Iniciar Avaliação',
        onPressed: canStart
            ? () async {
                final t = await runAction(context, () => s.iniciar(p.id));
                if (t != null && context.mounted)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ExamSession(t.id)),
                  );
              }
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTag(
                  statusLabel(p.estado()),
                  color: p.estaDisponivel()
                      ? AppColors.success
                      : AppColors.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  c.titulo,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(c.descricao),
                const Divider(height: 28),
                InfoRow(
                  'Questões',
                  '${c.itens.length}',
                  icon: Icons.quiz_outlined,
                ),
                InfoRow(
                  'Duração',
                  c.duracaoMinutos == null
                      ? 'Sem limite próprio'
                      : '${c.duracaoMinutos} minutos',
                  icon: Icons.timer_outlined,
                ),
                InfoRow(
                  'Tentativas',
                  '$count / ${p.limiteTentativas} utilizadas',
                  icon: Icons.repeat,
                ),
                InfoRow(
                  'Abertura',
                  dateLabel(p.inicioDisponibilidade),
                  icon: Icons.event_available_outlined,
                ),
                InfoRow(
                  'Prazo',
                  dateLabel(p.prazo),
                  icon: Icons.event_busy_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Orientações'),
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Leia cada enunciado com atenção.'),
                SizedBox(height: 9),
                Text(
                  '• Suas respostas são preservadas ao navegar entre questões.',
                ),
                SizedBox(height: 9),
                Text('• Você poderá revisar as respostas antes de enviar.'),
                SizedBox(height: 9),
                Text('• A avaliação não será enviada ao pressionar Voltar.'),
                SizedBox(height: 9),
                Text(
                  '• O tempo é contado a partir do início e não é pausado ao sair.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExamSession extends StatefulWidget {
  const ExamSession(this.tentativaId, {super.key});
  final String tentativaId;
  @override
  State<ExamSession> createState() => _ExamSessionState();
}

class _ExamSessionState extends State<ExamSession> {
  AvaliationStore? store;
  Timer? timer;
  int index = 0;
  bool review = false, busy = false, allowPop = false;
  DateTime now = DateTime.now();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    store ??= AppScope.of(context);
    timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => now = DateTime.now());
      final t = store!.tentativa(widget.tentativaId);
      if (t.editavel && store!.tempoEsgotado(t, now)) _submit(expired: true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _exit() async {
    if (busy) return;
    final ok = await confirmAction(
      context,
      'Sair da avaliação?',
      'Suas respostas permanecerão salvas neste dispositivo. O cronômetro continuará contando. A avaliação não será enviada.',
      confirm: 'Sair',
    );
    if (ok && mounted) {
      setState(() => allowPop = true);
      Navigator.pop(context);
    }
  }

  Future<void> _submit({bool expired = false}) async {
    if (busy) return;
    final s = store!;
    final t = s.tentativa(widget.tentativaId);
    if (!t.editavel) return;
    if (!expired) {
      final ok = await confirmAction(
        context,
        'Enviar avaliação?',
        'Depois do envio, as respostas não poderão mais ser alteradas.',
        confirm: 'Enviar avaliação',
      );
      if (!ok || !mounted) return;
    }
    setState(() => busy = true);
    final r = await runAction(context, () => s.enviar(t.id));
    if (!mounted) return;
    setState(() => busy = false);
    if (r != null) {
      timer?.cancel();
      setState(() => allowPop = true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentComplete(t.id, expired: expired),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = store ?? AppScope.of(context);
    final t = s.tentativa(widget.tentativaId);
    final p = s.publicacao(t.publicacaoId);
    final c = s.conteudo(p);
    final order = t.ordemQuestoes.isEmpty
        ? c.itens.map((i) => i.questaoId).toList()
        : t.ordemQuestoes;
    final total = order.length;
    final answered = order
        .where((id) => t.resposta(id)?.respondida == true)
        .length;
    final end = s.limiteTempo(t);
    final seconds = end == null ? null : max(0, end.difference(now).inSeconds);
    String clock(int n) =>
        '${(n ~/ 3600).toString().padLeft(2, '0')}:${((n % 3600) ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: AppPage(
        title: review ? 'Revisar Respostas' : c.titulo,
        showNavigation: false,
        scroll: false,
        leading: IconButton(
          tooltip: 'Sair da prova',
          icon: const Icon(Icons.arrow_back),
          onPressed: _exit,
        ),
        actions: [
          if (seconds != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      clock(seconds),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        bottom: review
            ? ActionRow(
                children: [
                  AppButton(
                    'Voltar',
                    outlined: true,
                    onPressed: busy
                        ? null
                        : () => setState(() => review = false),
                  ),
                  AppButton(
                    busy ? 'Enviando...' : 'Enviar Avaliação',
                    onPressed: busy ? null : () => _submit(),
                  ),
                ],
              )
            : ActionRow(
                children: [
                  AppButton(
                    'Anterior',
                    outlined: true,
                    onPressed: busy || index == 0
                        ? null
                        : () => setState(() => index--),
                  ),
                  AppButton(
                    index == total - 1 ? 'Revisar' : 'Próxima',
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            if (index == total - 1)
                              review = true;
                            else
                              index++;
                          }),
                  ),
                ],
              ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        review
                            ? 'Revisão Final'
                            : 'Questão ${index + 1} de $total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$answered/$total respondidas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: review ? answered / total : (index + 1) / total,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(5),
                    backgroundColor: AppColors.border,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: review
                    ? _review(s, t, c, order)
                    : _question(s, t, c, order[index], index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(
    AvaliationStore s,
    Tentativa t,
    ConteudoAvaliacao c,
    String id,
    int index,
  ) {
    final q = c.questao(id);
    final r = t.resposta(id);
    final points = c.itens.firstWhere((i) => i.questaoId == id).pontuacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTag(tipoLabel(q.tipo)),
            const Spacer(),
            AppTag('$points pts', color: AppColors.muted),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          q.enunciado,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        if (q.objetiva)
          ...q.alternativas.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                color: r?.alternativaSelecionadaId == a.id
                    ? AppColors.primary.withValues(alpha: .05)
                    : null,
                child: InkWell(
                  onTap: busy
                      ? null
                      : () => runAction(
                          context,
                          () => s.responder(t.id, q.id, alternativaId: a.id),
                        ),
                  child: Row(
                    children: [
                      Icon(
                        r?.alternativaSelecionadaId == a.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: r?.alternativaSelecionadaId == a.id
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a.texto,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          TextFormField(
            key: ValueKey(q.id),
            initialValue: r?.respostaTexto,
            decoration: const InputDecoration(
              hintText: 'Digite sua resposta aqui...',
            ),
            minLines: q.tipo == TipoQuestao.dissertativa ? 6 : 2,
            maxLines: null,
            enabled: !busy,
            onChanged: (v) =>
                runAction(context, () => s.responder(t.id, q.id, texto: v)),
          ),
        const SizedBox(height: 16),
        Text(
          'Suas respostas são salvas automaticamente.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _review(
    AvaliationStore s,
    Tentativa t,
    ConteudoAvaliacao c,
    List<String> order,
  ) {
    final answered = order
        .where((id) => t.resposta(id)?.respondida == true)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          color: AppColors.primary.withValues(alpha: .04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confira antes de enviar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text('$answered de ${order.length} questões respondidas.'),
              if (answered < order.length) ...[
                const SizedBox(height: 8),
                Text(
                  '${order.length - answered} questão(ões) sem resposta.',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Situação das questões'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(order.length, (i) {
            final done = t.resposta(order[i])?.respondida == true;
            return InkWell(
              onTap: () => setState(() {
                index = i;
                review = false;
              }),
              child: Container(
                width: 62,
                height: 66,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.success.withValues(alpha: .08)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: done ? AppColors.success : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: done ? AppColors.success : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      done ? Icons.check_circle : Icons.circle_outlined,
                      color: done ? AppColors.success : AppColors.muted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        const Text(
          'Toque em uma questão para voltar e alterar sua resposta. Questões em branco podem ser enviadas sem resposta.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class AssessmentComplete extends StatelessWidget {
  const AssessmentComplete(this.id, {super.key, this.expired = false});
  final String id;
  final bool expired;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.tentativa(id);
    final p = s.publicacao(t.publicacaoId);
    final r = s.resultadoDaTentativa(id);
    final visible = p.mostrarResultado && r != null && !r.provisorio;
    return AppPage(
      title: 'Avaliação Concluída',
      showNavigation: false,
      bottom: AppButton(
        'Voltar para Avaliações',
        onPressed: () => AppNav.go(context, 2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.success.withValues(alpha: .1),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            expired ? 'Tempo encerrado' : 'Avaliação enviada!',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sua tentativa foi registrada neste dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              children: [
                InfoRow('Avaliação', s.conteudo(p).titulo),
                InfoRow('Tentativa', '${t.numeroTentativa}'),
                InfoRow('Enviada em', dateLabel(t.fim ?? DateTime.now())),
                if (visible) InfoRow('Nota', score(r.nota)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (r?.provisorio == true)
            const Panel(
              child: Text(
                'Sua avaliação contém respostas que precisam de correção manual. A nota final ainda não está disponível.',
              ),
            )
          else if (!p.mostrarResultado)
            const Panel(
              child: Text(
                'O resultado será disponibilizado quando o professor autorizar.',
              ),
            )
          else if (visible)
            AppButton(
              'Ver Resultado',
              onPressed: () => openPage(context, AttemptResultPage(t.id)),
            ),
        ],
      ),
    );
  }
}
