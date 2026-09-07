import 'package:flutter/material.dart';

import '../data/avaliation_store.dart';
import '../domain/models.dart';
import '../ui/common.dart';

class ResultsHome extends StatefulWidget {
  const ResultsHome({super.key});
  @override
  State<ResultsHome> createState() => _ResultsHomeState();
}

class _ResultsHomeState extends State<ResultsHome> {
  String? turmaId;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pubs =
        s.minhasPublicacoes
            .where((p) => turmaId == null || p.turmas.contains(turmaId))
            .toList()
          ..sort((a, b) => b.dataPublicacao.compareTo(a.dataPublicacao));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Selecione uma turma e uma publicação para analisar os resultados.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: turmaId,
          decoration: const InputDecoration(labelText: 'Turma'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas as turmas')),
            ...s.minhasTurmas.map(
              (t) => DropdownMenuItem(
                value: t.id,
                child: Text(
                  t.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => turmaId = v),
        ),
        const SizedBox(height: 20),
        SectionTitle(
          'Publicações',
          trailing: s.correcoesPendentes.isEmpty
              ? null
              : TextButton(
                  onPressed: () => openPage(context, const ManualGradingPage()),
                  child: AppTag(
                    '${s.correcoesPendentes.length} correções',
                    color: AppColors.warning,
                  ),
                ),
        ),
        if (pubs.isEmpty)
          const EmptyState(
            'Nenhuma publicação',
            'Publique um questionário para começar a acompanhar os resultados.',
          )
        else
          ...pubs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.conteudo(p).titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      p.turmas.map((id) => s.turma(id).nome).join(', '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AppTag(
                          statusLabel(p.estado()),
                          color: p.estaDisponivel()
                              ? AppColors.success
                              : AppColors.muted,
                        ),
                        const Spacer(),
                        Text(
                          '${s.resultadosDe(p.id).length} envios',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      'Abrir Dashboard',
                      icon: Icons.insights_outlined,
                      onPressed: () => openPage(
                        context,
                        DashboardPage(
                          publicacaoId: p.id,
                          initialTurmaId: turmaId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.publicacaoId,
    this.initialTurmaId,
  });
  final String publicacaoId;
  final String? initialTurmaId;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? turmaId, estudanteId;
  DateTimeRange? period;
  @override
  void initState() {
    super.initState();
    turmaId = widget.initialTurmaId;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.publicacao(widget.publicacaoId);
    final c = s.conteudo(p);
    final m = s.metricas(
      p.id,
      turmaId: turmaId,
      estudanteId: estudanteId,
      inicio: period?.start,
      fim: period?.end
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1)),
    );
    final ids = <String>{};
    for (final tid in p.turmas) {
      if (turmaId == null || turmaId == tid)
        ids.addAll(s.turma(tid).estudanteIds);
    }
    final selectedStudent = ids.contains(estudanteId) ? estudanteId : null;
    final pending = s.resultadosDe(p.id).where((r) => r.provisorio).length;
    return AppPage(
      title: 'Dashboard de Resultados',
      subtitle: c.titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Filtros de Análise'),
          DropdownButtonFormField<String>(
            key: ValueKey('turma-$turmaId'),
            initialValue: turmaId,
            decoration: const InputDecoration(labelText: 'Turma'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todas as turmas'),
              ),
              ...p.turmas.map(
                (id) => DropdownMenuItem(
                  value: id,
                  child: Text(
                    s.turma(id).nome,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() {
              turmaId = v;
              estudanteId = null;
            }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('aluno-$selectedStudent-$turmaId'),
            initialValue: selectedStudent,
            decoration: const InputDecoration(labelText: 'Estudante'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos os estudantes'),
              ),
              ...ids.map(
                (id) => DropdownMenuItem(
                  value: id,
                  child: Text(s.usuarioPorId(id).nome),
                ),
              ),
            ],
            onChanged: (v) => setState(() => estudanteId = v),
          ),
          const SizedBox(height: 10),
          AppButton(
            period == null
                ? 'Filtrar por período'
                : '${shortDate(period!.start)} – ${shortDate(period!.end)}',
            outlined: true,
            icon: Icons.date_range_outlined,
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: period,
              );
              if (range != null) setState(() => period = range);
            },
          ),
          if (period != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => period = null),
                child: const Text('Limpar período'),
              ),
            ),
          const SizedBox(height: 20),
          const SectionTitle('Visão Geral'),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  'Média',
                  score(m.media),
                  icon: Icons.insights_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  'Mediana',
                  score(m.mediana),
                  icon: Icons.stacked_bar_chart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  'Participação',
                  '${m.taxaParticipacao.toStringAsFixed(0)}%',
                  icon: Icons.groups_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Panel(
            child: Column(
              children: [
                InfoRow(
                  'Respondentes',
                  '${m.totalRespondentes} / ${m.totalEstudantes}',
                ),
                InfoRow('Maior nota', score(m.maiorNota)),
                InfoRow('Menor nota', score(m.menorNota)),
                InfoRow('Desvio-padrão', score(m.desvioPadrao)),
                InfoRow('Correções pendentes', '$pending'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Distribuição de Notas'),
          Panel(
            child: m.media == null
                ? const Text(
                    'Ainda não existem notas finais suficientes para calcular a distribuição.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                : Column(
                    children: [
                      for (final f in m.distribuicaoNotas)
                        _MetricBar(
                          f.rotulo,
                          f.quantidade.toDouble(),
                          m.totalRespondentes.toDouble(),
                          valueLabel: '${f.quantidade}',
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Desempenho por Questão'),
          if (m.desempenhoQuestoes.isEmpty)
            const EmptyState('Sem questões', 'Não há questões para analisar.')
          else
            Panel(
              child: Column(
                children: [
                  for (var i = 0; i < m.desempenhoQuestoes.length; i++) ...[
                    Text(
                      'Q${i + 1} • ${c.questao(m.desempenhoQuestoes[i].questaoId).enunciado}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetricBar(
                      'Acertos',
                      m.desempenhoQuestoes[i].percentualAcerto,
                      100,
                      valueLabel:
                          '${m.desempenhoQuestoes[i].percentualAcerto.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Notas são calculadas a partir das últimas tentativas de cada estudante com correção finalizada. Respostas em correção não são incluídas na média. A participação considera envios, inclusive os que aguardam correção.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          ActionRow(
            children: [
              AppButton(
                'Analisar Questões',
                outlined: true,
                onPressed: () => openPage(
                  context,
                  QuestionAnalysisPage(p.id, turmaId: turmaId),
                ),
              ),
              AppButton(
                'Ver Alunos',
                onPressed: () => openPage(
                  context,
                  StudentResultsPage(p.id, turmaId: turmaId),
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 14),
            AppButton(
              'Correções Pendentes',
              outlined: true,
              icon: Icons.rate_review_outlined,
              onPressed: () =>
                  openPage(context, ManualGradingPage(publicacaoId: p.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar(this.label, this.value, this.maximum, {this.valueLabel});
  final String label;
  final double value, maximum;
  final String? valueLabel;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maximum == 0 ? 0 : (value / maximum).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            valueLabel ?? value.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class QuestionAnalysisPage extends StatelessWidget {
  const QuestionAnalysisPage(this.id, {super.key, this.turmaId});
  final String id;
  final String? turmaId;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.publicacao(id);
    final c = s.conteudo(p);
    final m = s.metricas(id, turmaId: turmaId);
    return AppPage(
      title: 'Analisar Questões',
      subtitle: c.titulo,
      child: Column(
        children: List.generate(c.itens.length, (i) {
          final item = c.itens[i];
          final q = c.questao(item.questaoId);
          final d = m.desempenhoQuestoes[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppTag('Questão ${i + 1}'),
                      const Spacer(),
                      AppTag(tipoLabel(q.tipo)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.enunciado,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  _MetricBar(
                    'Acertos',
                    d.percentualAcerto,
                    100,
                    valueLabel: '${d.percentualAcerto.toStringAsFixed(0)}%',
                  ),
                  InfoRow('Respostas analisadas', '${d.totalRespostas}'),
                  InfoRow('Acertos', '${d.totalAcertos}'),
                  InfoRow('Erros', '${d.totalErros}'),
                  InfoRow('Em branco', '${d.totalEmBranco}'),
                  InfoRow('Pontuação máxima', '${item.pontuacao}'),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StudentResultsPage extends StatelessWidget {
  const StudentResultsPage(this.id, {super.key, this.turmaId});
  final String id;
  final String? turmaId;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.publicacao(id);
    final allowed = <String>{};
    for (final tid in p.turmas) {
      if (turmaId == null || tid == turmaId)
        allowed.addAll(s.turma(tid).estudanteIds);
    }
    final attempts =
        s
            .tentativasDe(id)
            .where((t) => allowed.contains(t.estudanteId) && !t.editavel)
            .toList()
          ..sort((a, b) => a.estudanteId.compareTo(b.estudanteId));
    return AppPage(
      title: 'Resultados dos Alunos',
      subtitle: s.conteudo(p).titulo,
      child: attempts.isEmpty
          ? const EmptyState(
              'Nenhum envio',
              'Os resultados individuais aparecerão após as avaliações serem enviadas.',
            )
          : Column(
              children: [
                for (final t in attempts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.usuarioPorId(t.estudanteId).nome,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          InfoRow('Tentativa', '${t.numeroTentativa}'),
                          InfoRow(
                            'Nota',
                            s.resultadoDaTentativa(t.id)?.provisorio == true
                                ? 'Em correção'
                                : score(s.resultadoDaTentativa(t.id)?.nota),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            'Ver Detalhes',
                            outlined: true,
                            onPressed: () =>
                                openPage(context, AttemptResultPage(t.id)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ManualGradingPage extends StatelessWidget {
  const ManualGradingPage({super.key, this.publicacaoId});
  final String? publicacaoId;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.correcoesPendentes
        .where((t) => publicacaoId == null || t.publicacaoId == publicacaoId)
        .toList();
    return AppPage(
      title: 'Correções Pendentes',
      subtitle: 'Respostas que exigem avaliação manual',
      child: list.isEmpty
          ? const EmptyState(
              'Tudo corrigido',
              'Não há respostas aguardando correção.',
            )
          : Column(
              children: [
                for (final t in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.usuarioPorId(t.estudanteId).nome,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            s.conteudo(s.publicacao(t.publicacaoId)).titulo,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            'Corrigir Respostas',
                            onPressed: () =>
                                openPage(context, GradeAttemptPage(t.id)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class GradeAttemptPage extends StatelessWidget {
  const GradeAttemptPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.tentativa(id);
    final p = s.publicacao(t.publicacaoId);
    final c = s.conteudo(p);
    final pending = c.itens.where((i) {
      final q = c.questao(i.questaoId);
      final r = t.resposta(q.id);
      return !q.objetiva &&
          r != null &&
          r.respondida &&
          r.pontuacaoObtida == null;
    }).toList();
    return AppPage(
      title: 'Correção Manual',
      subtitle: s.usuarioPorId(t.estudanteId).nome,
      child: pending.isEmpty
          ? const EmptyState(
              'Correção finalizada',
              'Todas as respostas desta tentativa foram corrigidas.',
            )
          : Column(
              children: [
                for (final item in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTag(tipoLabel(c.questao(item.questaoId).tipo)),
                          const SizedBox(height: 12),
                          Text(
                            c.questao(item.questaoId).enunciado,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Resposta do estudante',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(t.resposta(item.questaoId)?.respostaTexto ?? ''),
                          if (c
                                  .questao(item.questaoId)
                                  .respostaCorreta
                                  ?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Referência de correção',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(c.questao(item.questaoId).respostaCorreta!),
                          ],
                          const SizedBox(height: 14),
                          AppButton(
                            'Atribuir nota (máx. ${item.pontuacao})',
                            onPressed: () => _grade(context, s, t, item),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _grade(
    BuildContext context,
    AvaliationStore s,
    Tentativa t,
    ItemQuestionario item,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Atribuir pontuação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Valor entre 0 e ${item.pontuacao} pontos.'),
            const SizedBox(height: 12),
            AppField(
              'Pontuação obtida',
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(controller.text.replaceAll(',', '.'));
              if (n == null || n < 0 || n > item.pontuacao) {
                showMessage(c, 'Pontuação inválida.', error: true);
                return;
              }
              Navigator.pop(c, n);
            },
            child: const Text('Salvar Correção'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && context.mounted)
      await runAction(
        context,
        () => s.corrigirResposta(t.id, item.questaoId, value),
        success: 'Correção registrada.',
      );
  }
}

class AttemptResultPage extends StatelessWidget {
  const AttemptResultPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.tentativa(id);
    try {
      s.exigirResultadoVisivel(t);
    } catch (e) {
      return const AppPage(
        title: 'Resultado indisponível',
        child: EmptyState(
          'Acesso não autorizado',
          'Este resultado não está disponível para sua conta.',
        ),
      );
    }
    final p = s.publicacao(t.publicacaoId);
    final c = s.conteudo(p);
    final r = s.resultadoDaTentativa(t.id);
    if (r == null)
      return const AppPage(
        title: 'Resultado',
        child: EmptyState(
          'Ainda não há resultado',
          'A tentativa precisa ser enviada para gerar um resultado.',
        ),
      );
    return AppPage(
      title: 'Resultado da Avaliação',
      subtitle: c.titulo,
      child: Column(
        children: [
          const SizedBox(height: 8),
          if (r.provisorio)
            const Panel(
              child: Text(
                'Correção em andamento. A nota final e os indicadores consolidados ainda não estão disponíveis.',
              ),
            )
          else ...[
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withValues(alpha: .08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score(r.nota),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'de 10 pontos',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nota Final',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 20),
          Panel(
            child: Column(
              children: [
                InfoRow('Questões', '${r.totalQuestoes}'),
                InfoRow('Acertos', '${r.acertos}'),
                InfoRow('Erros', '${r.erros}'),
                InfoRow('Em branco', '${r.emBranco}'),
                if (!r.provisorio)
                  InfoRow(
                    'Percentual de acerto',
                    '${r.percentualAcerto.toStringAsFixed(1)}%',
                  ),
                InfoRow('Conclusão', dateLabel(r.dataConclusao)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Detalhamento'),
          AppButton(
            'Ver Questão por Questão',
            onPressed: () => openPage(context, AnswerDetailsPage(t.id)),
          ),
        ],
      ),
    );
  }
}

class AnswerDetailsPage extends StatelessWidget {
  const AnswerDetailsPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.tentativa(id);
    try {
      s.exigirResultadoVisivel(t);
    } catch (e) {
      return const AppPage(
        title: 'Acesso não autorizado',
        child: EmptyState(
          'Resultado oculto',
          'O professor ainda não liberou o detalhamento.',
        ),
      );
    }
    final c = s.conteudo(s.publicacao(t.publicacaoId));
    return AppPage(
      title: 'Detalhamento',
      subtitle: c.titulo,
      child: Column(
        children: List.generate(c.itens.length, (i) {
          final item = c.itens[i];
          final q = c.questao(item.questaoId);
          final r = t.resposta(q.id);
          final blank = r == null || !r.respondida;
          final pending = !blank && r.pontuacaoObtida == null;
          final partial =
              !pending &&
              !blank &&
              r!.pontuacaoObtida! > 0 &&
              r.pontuacaoObtida! < item.pontuacao;
          final label = blank
              ? 'Em branco'
              : pending
              ? 'Em correção'
              : partial
              ? 'Parcial'
              : r!.correta == true
              ? 'Correta'
              : 'Incorreta';
          final color = blank || pending
              ? AppColors.muted
              : partial
              ? AppColors.warning
              : r!.correta == true
              ? AppColors.success
              : AppColors.danger;
          final selected = q.objetiva
              ? (() {
                  for (final a in q.alternativas) {
                    if (a.id == r?.alternativaSelecionadaId) return a.texto;
                  }
                  return 'Sem resposta';
                })()
              : r?.respostaTexto ?? 'Sem resposta';
          final correct = q.objetiva
              ? q.alternativas
                    .where((a) => a.correta)
                    .map((a) => a.texto)
                    .join(', ')
              : q.respostaCorreta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppTag('Questão ${i + 1}'),
                      const Spacer(),
                      AppTag(label, color: color),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.enunciado,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sua resposta',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(selected),
                  if (correct != null && correct.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Resposta correta / referência',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(correct),
                  ],
                  if (q.explicacao?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      q.explicacao!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const Divider(height: 25),
                  InfoRow(
                    'Pontuação',
                    pending
                        ? 'Aguardando correção'
                        : '${r?.pontuacaoObtida ?? 0} / ${item.pontuacao}',
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
