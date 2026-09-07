import 'package:flutter/material.dart';

import '../data/avaliation_store.dart';
import '../domain/models.dart';
import '../ui/common.dart';
import 'teacher_editor.dart';
import 'results.dart';

class TeacherEvaluations extends StatefulWidget {
  const TeacherEvaluations({super.key});
  @override
  State<TeacherEvaluations> createState() => _TeacherEvaluationsState();
}

class _TeacherEvaluationsState extends State<TeacherEvaluations> {
  int tab = 1;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Questões')),
              ButtonSegment(value: 1, label: Text('Questionários')),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
        ),
      ),
      Expanded(
        child: tab == 0
            ? const QuestionBankContent()
            : const QuestionnaireBankContent(),
      ),
    ],
  );
}

class QuestionBankPage extends StatelessWidget {
  const QuestionBankPage({
    super.key,
    this.select = false,
    this.excluded = const {},
  });
  final bool select;
  final Set<String> excluded;
  @override
  Widget build(BuildContext context) => AppPage(
    title: select ? 'Selecionar Questão' : 'Banco de Questões',
    subtitle: 'Busque e selecione questões prontas',
    scroll: false,
    child: QuestionBankContent(select: select, excluded: excluded),
  );
}

class QuestionBankContent extends StatefulWidget {
  const QuestionBankContent({
    super.key,
    this.select = false,
    this.excluded = const {},
  });
  final bool select;
  final Set<String> excluded;
  @override
  State<QuestionBankContent> createState() => _QuestionBankContentState();
}

class _QuestionBankContentState extends State<QuestionBankContent> {
  String search = '';
  TipoQuestao? filter;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.minhasQuestoes
        .where(
          (q) =>
              !widget.excluded.contains(q.id) &&
              (filter == null || q.tipo == filter) &&
              '${q.enunciado} ${q.disciplina}'.toLowerCase().contains(
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
              hint: 'Buscar por enunciado ou disciplina...',
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: filter == null,
                    onSelected: (_) => setState(() => filter = null),
                  ),
                  const SizedBox(width: 6),
                  ...TipoQuestao.values.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tipoLabel(t)),
                        selected: filter == t,
                        onSelected: (_) => setState(() => filter = t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              EmptyState(
                'Nenhuma questão encontrada',
                'Cadastre uma questão para começar.',
                action: widget.select
                    ? null
                    : AppButton(
                        'Nova questão',
                        onPressed: () =>
                            openPage(context, const QuestionEditor()),
                      ),
              )
            else
              ...list.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: InkWell(
                      onTap: () => widget.select
                          ? Navigator.pop(context, q)
                          : openPage(context, QuestionDetails(q.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.enunciado,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              AppTag(tipoLabel(q.tipo)),
                              const SizedBox(width: 6),
                              AppTag(q.disciplina, color: AppColors.warning),
                              const Spacer(),
                              if (widget.select)
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                )
                              else
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.muted,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (!widget.select)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => openPage(context, const QuestionEditor()),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}

class QuestionDetails extends StatelessWidget {
  const QuestionDetails(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = s.questao(id);
    return AppPage(
      title: 'Detalhes da Questão',
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'editar') openPage(context, QuestionEditor(initial: q));
            if (v == 'arquivar' &&
                await confirmAction(
                  context,
                  'Arquivar questão',
                  'A questão deixará de aparecer no banco, mas as publicações antigas serão preservadas.',
                  destructive: true,
                )) {
              if (context.mounted) {
                await runAction(context, () => s.arquivarQuestao(q.id));
                if (context.mounted) Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'arquivar', child: Text('Arquivar')),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTag(tipoLabel(q.tipo)),
              const SizedBox(width: 8),
              AppTag(q.disciplina, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 18),
          Panel(
            child: Text(
              q.enunciado,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          if (q.objetiva) ...[
            const SizedBox(height: 18),
            const SectionTitle('Alternativas'),
            ...q.alternativas.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  color: a.correta
                      ? AppColors.success.withValues(alpha: .06)
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        a.correta ? Icons.check_circle : Icons.circle_outlined,
                        color: a.correta ? AppColors.success : AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a.texto)),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (q.respostaCorreta != null) ...[
            const SizedBox(height: 16),
            SectionTitle('Resposta de referência'),
            Panel(child: Text(q.respostaCorreta!)),
          ],
          if (q.explicacao?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const SectionTitle('Explicação'),
            Panel(child: Text(q.explicacao!)),
          ],
          const SizedBox(height: 20),
          AppButton(
            'Editar Questão',
            onPressed: () => openPage(context, QuestionEditor(initial: q)),
          ),
        ],
      ),
    );
  }
}

class QuestionEditor extends StatefulWidget {
  const QuestionEditor({super.key, this.initial, this.disciplina});
  final Questao? initial;
  final String? disciplina;
  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late final TextEditingController enunciado, disciplina, explicacao, gabarito;
  late TipoQuestao tipo;
  late List<TextEditingController> alternatives;
  int correct = 0;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    enunciado = TextEditingController(text: q?.enunciado);
    disciplina = TextEditingController(
      text: q?.disciplina ?? widget.disciplina,
    );
    explicacao = TextEditingController(text: q?.explicacao);
    gabarito = TextEditingController(text: q?.respostaCorreta);
    tipo = q?.tipo ?? TipoQuestao.multiplaEscolha;
    alternatives = q == null
        ? List.generate(4, (_) => TextEditingController())
        : q.alternativas
              .map((a) => TextEditingController(text: a.texto))
              .toList();
    if (alternatives.isEmpty)
      alternatives = List.generate(4, (_) => TextEditingController());
    if (q != null && q.objetiva) {
      final i = q.alternativas.indexWhere((a) => a.correta);
      if (i >= 0) correct = i;
    }
  }

  @override
  void dispose() {
    enunciado.dispose();
    disciplina.dispose();
    explicacao.dispose();
    gabarito.dispose();
    for (final c in alternatives) {
      c.dispose();
    }
    super.dispose();
  }

  void changeType(TipoQuestao t) {
    setState(() {
      tipo = t;
      if (t == TipoQuestao.verdadeiroFalso) {
        for (final c in alternatives) {
          c.dispose();
        }
        alternatives = [
          TextEditingController(text: 'Verdadeiro'),
          TextEditingController(text: 'Falso'),
        ];
        correct = 0;
      } else if (t == TipoQuestao.multiplaEscolha && alternatives.length < 3) {
        for (final c in alternatives) {
          c.dispose();
        }
        alternatives = List.generate(4, (_) => TextEditingController());
        correct = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppPage(
      title: widget.initial == null ? 'Criar Questão' : 'Editar Questão',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppField(
            'Enunciado',
            controller: enunciado,
            lines: 3,
            hint: 'Digite o enunciado completo...',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoQuestao>(
            initialValue: tipo,
            decoration: const InputDecoration(labelText: 'Tipo de Questão'),
            items: TipoQuestao.values
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(tipoLabel(t))),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) changeType(v);
            },
          ),
          const SizedBox(height: 18),
          if (tipo == TipoQuestao.multiplaEscolha ||
              tipo == TipoQuestao.verdadeiroFalso) ...[
            const SectionTitle('Alternativas (marque a correta)'),
            ...List.generate(
              alternatives.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: correct,
                      onChanged: (v) => setState(() => correct = v ?? 0),
                    ),
                    Expanded(
                      child: TextField(
                        controller: alternatives[i],
                        decoration: InputDecoration(
                          hintText: 'Alternativa ${i + 1}',
                          isDense: true,
                        ),
                      ),
                    ),
                    if (tipo == TipoQuestao.multiplaEscolha &&
                        alternatives.length > 2)
                      IconButton(
                        tooltip: 'Remover alternativa',
                        onPressed: () {
                          setState(() {
                            alternatives.removeAt(i).dispose();
                            if (correct >= alternatives.length) correct = 0;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            if (tipo == TipoQuestao.multiplaEscolha)
              TextButton.icon(
                onPressed: () =>
                    setState(() => alternatives.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar alternativa'),
              ),
          ] else
            AppField(
              'Resposta de referência (opcional)',
              controller: gabarito,
              lines: tipo == TipoQuestao.dissertativa ? 3 : 1,
            ),
          const SizedBox(height: 16),
          AppField('Explicação da Resposta', controller: explicacao, lines: 3),
          const SizedBox(height: 16),
          AppField('Disciplina', controller: disciplina),
          const SizedBox(height: 24),
          AppButton(
            busy ? 'Salvando...' : 'Salvar Questão',
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final now = DateTime.now();
                    final old = widget.initial;
                    final q = Questao(
                      id: old?.id ?? newId(),
                      professorId: s.uid,
                      enunciado: enunciado.text,
                      disciplina: disciplina.text,
                      tipo: tipo,
                      dataCriacao: old?.dataCriacao ?? now,
                      dataAtualizacao: now,
                      alternativas:
                          tipo == TipoQuestao.multiplaEscolha ||
                              tipo == TipoQuestao.verdadeiroFalso
                          ? List.generate(
                              alternatives.length,
                              (i) => Alternativa(
                                id:
                                    old != null &&
                                        old.tipo == tipo &&
                                        i < old.alternativas.length
                                    ? old.alternativas[i].id
                                    : newId(),
                                texto: alternatives[i].text,
                                ordem: i,
                                correta: i == correct,
                              ),
                            )
                          : [],
                      respostaCorreta:
                          tipo == TipoQuestao.respostaCurta ||
                              tipo == TipoQuestao.dissertativa
                          ? gabarito.text
                          : null,
                      explicacao: explicacao.text,
                    );
                    final saved = await runAction(
                      context,
                      () => s.salvarQuestao(q),
                      success: 'Questão salva no banco.',
                    );
                    if (!mounted) return;
                    setState(() => busy = false);
                    if (saved != null) Navigator.pop(context, saved);
                  },
          ),
        ],
      ),
    );
  }
}

class QuestionnaireBankPage extends StatelessWidget {
  const QuestionnaireBankPage({super.key});
  @override
  Widget build(BuildContext context) => const AppPage(
    title: 'Meus Questionários',
    subtitle: 'Crie e gerencie provas e testes',
    scroll: false,
    child: QuestionnaireBankContent(),
  );
}

class QuestionnaireBankContent extends StatefulWidget {
  const QuestionnaireBankContent({super.key});
  @override
  State<QuestionnaireBankContent> createState() =>
      _QuestionnaireBankContentState();
}

class _QuestionnaireBankContentState extends State<QuestionnaireBankContent> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.meusQuestionarios
        .where((q) => q.titulo.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            SearchField(
              hint: 'Buscar questionário...',
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              EmptyState(
                'Nenhum questionário',
                'Crie seu primeiro questionário reutilizável.',
                action: AppButton(
                  'Criar Questionário',
                  onPressed: () =>
                      openPage(context, const QuestionnaireWizard()),
                ),
              )
            else
              ...list.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuestionnaireCard(q),
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () => openPage(context, const QuestionnaireWizard()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _QuestionnaireCard extends StatelessWidget {
  const _QuestionnaireCard(this.q);
  final Questionario q;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final count = s.minhasPublicacoes
        .where((p) => p.questionarioId == q.id)
        .length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  q.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Mais ações',
                onSelected: (v) async {
                  if (v == 'arquivar' &&
                      await confirmAction(
                        context,
                        'Arquivar questionário',
                        'As publicações anteriores e seus resultados serão preservados.',
                        destructive: true,
                      )) {
                    if (context.mounted)
                      await runAction(
                        context,
                        () => s.arquivarQuestionario(q.id),
                      );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'arquivar', child: Text('Arquivar')),
                ],
              ),
            ],
          ),
          if (q.descricao.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              q.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            children: [
              AppTag('${q.itens.length} questões'),
              AppTag('$count publicações', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          ActionRow(
            children: [
              AppButton(
                'Publicar',
                onPressed: () =>
                    openPage(context, PublicationEditor(questionarioId: q.id)),
              ),
              AppButton(
                'Editar',
                outlined: true,
                onPressed: () =>
                    openPage(context, QuestionnaireWizard(initial: q)),
              ),
              AppButton(
                'Histórico',
                outlined: true,
                onPressed: () => openPage(context, QuestionnaireHistory(q.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuestionnaireHistory extends StatelessWidget {
  const QuestionnaireHistory(this.questionarioId, {super.key});
  final String questionarioId;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = s.questionario(questionarioId);
    final pubs =
        s.minhasPublicacoes.where((p) => p.questionarioId == q.id).toList()
          ..sort((a, b) => b.dataPublicacao.compareTo(a.dataPublicacao));
    return AppPage(
      title: 'Histórico do Questionário',
      subtitle: q.titulo,
      bottom: AppButton(
        'Publicar em Nova Turma',
        outlined: true,
        icon: Icons.add_circle_outline,
        onPressed: () =>
            openPage(context, PublicationEditor(questionarioId: q.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Publicações Realizadas'),
          if (pubs.isEmpty)
            const EmptyState(
              'Nenhuma publicação',
              'O questionário foi criado e pode ser publicado a qualquer momento.',
            )
          else
            ...pubs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.turmas.map((id) => s.turma(id).nome).join(', '),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AppTag(
                            statusLabel(p.estado()),
                            color: p.estaDisponivel()
                                ? AppColors.success
                                : AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${dateLabel(p.inicioDisponibilidade)} – ${dateLabel(p.prazo)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ActionRow(
                        children: [
                          AppButton(
                            'Ver Resultados',
                            outlined: true,
                            onPressed: () => openPage(
                              context,
                              DashboardPage(publicacaoId: p.id),
                            ),
                          ),
                          AppButton(
                            'Ajustes',
                            outlined: true,
                            onPressed: () =>
                                openPage(context, PublicationSettings(p.id)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
