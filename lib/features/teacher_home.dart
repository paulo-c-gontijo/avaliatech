import 'package:flutter/material.dart';

import '../data/avaliation_store.dart';
import '../domain/models.dart';
import '../ui/common.dart';
import 'teacher_editor.dart';
import 'results.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final name = s.usuario.nome.split(' ').first;
    final pending = s.correcoesPendentes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Olá, Prof. $name!',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel(DateTime.now()),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatCard(
                'Turmas',
                '${s.minhasTurmas.length}',
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                'Questões',
                '${s.minhasQuestoes.length}',
                icon: Icons.quiz_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                'Ativas',
                '${s.minhasPublicacoes.where((p) => p.estaDisponivel()).length}',
                icon: Icons.insights_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Acesso Rápido'),
        Row(
          children: [
            Expanded(
              child: _Shortcut(
                'Banco de\nQuestões',
                Icons.storage_outlined,
                () => AppNav.go(context, 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Shortcut(
                'Questionários',
                Icons.description_outlined,
                () => AppNav.go(context, 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Shortcut(
                'Resultados',
                Icons.bar_chart_outlined,
                () => AppNav.go(context, 3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionTitle(
          'Atividade Recente',
          trailing: pending.isEmpty
              ? null
              : AppTag('${pending.length} Pendentes', color: AppColors.warning),
        ),
        if (pending.isNotEmpty) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correções manuais pendentes',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pending.length} tentativa(s) aguardando correção.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                AppButton(
                  'Abrir correções',
                  onPressed: () => openPage(context, const ManualGradingPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (s.minhasPublicacoes.isEmpty)
          const EmptyState(
            'Nenhuma publicação',
            'Crie um questionário e publique-o para suas turmas.',
          )
        else
          ...s.minhasPublicacoes.reversed
              .take(4)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Panel(
                    child: InkWell(
                      onTap: () =>
                          openPage(context, DashboardPage(publicacaoId: p.id)),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.conteudo(p).titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${p.turmas.length} turma(s) • ${statusLabel(p.estado())}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
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
        const Text(
          'Os indicadores refletem os registros reais deste dispositivo.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class TeacherClasses extends StatefulWidget {
  const TeacherClasses({super.key});
  @override
  State<TeacherClasses> createState() => _TeacherClassesState();
}

class _TeacherClassesState extends State<TeacherClasses> {
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
            const SizedBox(height: 16),
            if (list.isEmpty)
              EmptyState(
                'Nenhuma turma encontrada',
                'Crie sua primeira turma para começar.',
                action: AppButton(
                  'Criar turma',
                  onPressed: () => openPage(context, const ClassEditor()),
                ),
              )
            else
              ...list.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: InkWell(
                      onTap: () => openPage(context, TeacherClassDetails(t.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const AppTag('Ativa', color: AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              AppTag(t.disciplina),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${t.estudanteIds.length} alunos',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
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
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () => openPage(context, const ClassEditor()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class ClassEditor extends StatefulWidget {
  const ClassEditor({super.key, this.initial});
  final Turma? initial;
  @override
  State<ClassEditor> createState() => _ClassEditorState();
}

class _ClassEditorState extends State<ClassEditor> {
  late final TextEditingController nome, disciplina;
  @override
  void initState() {
    super.initState();
    nome = TextEditingController(text: widget.initial?.nome);
    disciplina = TextEditingController(text: widget.initial?.disciplina);
  }

  @override
  void dispose() {
    nome.dispose();
    disciplina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppPage(
      title: widget.initial == null ? 'Criar Turma' : 'Editar Turma',
      child: Column(
        children: [
          AppField(
            'Nome da turma',
            controller: nome,
            hint: 'Ex.: Turma 3A — Programação',
          ),
          const SizedBox(height: 16),
          AppField('Disciplina', controller: disciplina, hint: 'Ex.: Python'),
          const SizedBox(height: 24),
          AppButton(
            'Salvar Turma',
            onPressed: () async {
              final t = await runAction(
                context,
                () => s.salvarTurma(
                  id: widget.initial?.id,
                  nome: nome.text,
                  disciplina: disciplina.text,
                ),
                success: 'Turma salva.',
              );
              if (t != null && context.mounted) Navigator.pop(context, t);
            },
          ),
        ],
      ),
    );
  }
}

class TeacherClassDetails extends StatefulWidget {
  const TeacherClassDetails(this.turmaId, {super.key});
  final String turmaId;
  @override
  State<TeacherClassDetails> createState() => _TeacherClassDetailsState();
}

class _TeacherClassDetailsState extends State<TeacherClassDetails> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.turma(widget.turmaId);
    final pubs = s.minhasPublicacoes
        .where((p) => p.turmas.contains(t.id))
        .toList();
    return AppPage(
      title: t.nome,
      subtitle: 'Disciplina: ${t.disciplina} • ${t.estudanteIds.length} alunos',
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'editar') openPage(context, ClassEditor(initial: t));
            if (v == 'codigo')
              await runAction(
                context,
                () => s.gerarNovoCodigo(t.id),
                success: 'Novo código gerado.',
              );
            if (v == 'arquivar' &&
                await confirmAction(
                  context,
                  'Arquivar turma',
                  'A turma deixará de aparecer na listagem ativa.',
                  destructive: true,
                )) {
              if (context.mounted) {
                await runAction(context, () => s.arquivarTurma(t.id));
                if (context.mounted) Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar turma')),
            PopupMenuItem(value: 'codigo', child: Text('Gerar novo código')),
            PopupMenuItem(value: 'arquivar', child: Text('Arquivar turma')),
          ],
        ),
      ],
      child: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Alunos')),
              ButtonSegment(value: 1, label: Text('Avaliações')),
              ButtonSegment(value: 2, label: Text('Resultados')),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
          const SizedBox(height: 18),
          if (tab == 0) ...[
            Panel(
              color: AppColors.warning.withValues(alpha: .08),
              child: Column(
                children: [
                  const Text(
                    'Código da Turma',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    t.codigoConvite,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Válido apenas para contas deste dispositivo no modo local.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(
              'Lista de Alunos',
              trailing: TextButton.icon(
                onPressed: () => _invite(context, t),
                icon: const Icon(Icons.person_add_alt_1, size: 17),
                label: const Text('Convidar'),
              ),
            ),
            if (t.estudanteIds.isEmpty)
              const EmptyState(
                'Nenhum aluno',
                'Convide um estudante cadastrado ou compartilhe o código.',
              )
            else
              ...t.estudanteIds.map((id) {
                final u = s.usuarioPorId(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Panel(
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(u.nome[0])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                u.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover aluno',
                          onPressed: () async {
                            if (await confirmAction(
                              context,
                              'Remover aluno',
                              'Remover ${u.nome} desta turma?',
                              destructive: true,
                            )) {
                              if (context.mounted)
                                await runAction(
                                  context,
                                  () => s.removerEstudante(t.id, id),
                                );
                            }
                          },
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ] else if (tab == 1) ...[
            const SectionTitle('Publicações da Turma'),
            if (pubs.isEmpty)
              const EmptyState(
                'Sem avaliações',
                'Publique um questionário para esta turma.',
              )
            else
              ...pubs.map((p) => _ClassPublication(p)),
          ] else ...[
            const SectionTitle('Resultados da Turma'),
            if (pubs.isEmpty)
              const EmptyState(
                'Sem resultados',
                'As análises aparecerão após a publicação de uma avaliação.',
              )
            else
              ...pubs.map((p) => _ClassPublication(p, results: true)),
          ],
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext context, Turma t) async {
    final s = AppScope.of(context);
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Convidar estudante'),
        content: AppField(
          'E-mail do estudante',
          controller: controller,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await runAction(
                c,
                () => s.convidar(t.id, controller.text),
                success: 'Convite enviado.',
              );
              if (result != null && c.mounted) Navigator.pop(c);
            },
            child: const Text('Convidar'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _ClassPublication extends StatelessWidget {
  const _ClassPublication(this.p, {this.results = false});
  final PublicacaoQuestionario p;
  final bool results;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.conteudo(p).titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
            const SizedBox(height: 7),
            Text(
              '${shortDate(p.inicioDisponibilidade)} – ${shortDate(p.prazo)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            AppButton(
              results ? 'Abrir Dashboard' : 'Ver publicação',
              outlined: true,
              onPressed: () =>
                  openPage(context, DashboardPage(publicacaoId: p.id)),
            ),
          ],
        ),
      ),
    );
  }
}
