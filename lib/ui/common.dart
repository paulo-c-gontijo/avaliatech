import 'package:flutter/material.dart';

import '../data/avaliation_store.dart';
import '../domain/models.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF8490A3);
  static const background = Color(0xFFF8FAFD);
  static const border = Color(0xFFE1E7F0);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

ThemeData appTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF101827)
        : AppColors.background,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101827) : AppColors.background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
        .textTheme
        .apply(
          fontFamily: 'Roboto',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        ),
  );
}

class AppScope extends InheritedNotifier<AvaliationStore> {
  const AppScope({
    super.key,
    required AvaliationStore store,
    required super.child,
  }) : super(notifier: store);
  static AvaliationStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class AppNav {
  static final selected = ValueNotifier<int>(0);
  static void go(BuildContext context, int index) {
    selected.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

String dateLabel(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
}

String shortDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

String score(double? value) => value == null ? '—' : value.toStringAsFixed(1);
String tipoLabel(TipoQuestao tipo) => switch (tipo) {
  TipoQuestao.multiplaEscolha => 'Múltipla Escolha',
  TipoQuestao.verdadeiroFalso => 'Verdadeiro / Falso',
  TipoQuestao.respostaCurta => 'Resposta Curta',
  TipoQuestao.dissertativa => 'Dissertativa',
};
String statusLabel(StatusPublicacao status) => switch (status) {
  StatusPublicacao.agendada => 'Agendada',
  StatusPublicacao.disponivel => 'Disponível',
  StatusPublicacao.encerrada => 'Encerrada',
  StatusPublicacao.cancelada => 'Cancelada',
};

void showMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : null,
    ),
  );
}

Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
}) async {
  try {
    final result = await action();
    if (context.mounted && success != null) showMessage(context, success);
    return result;
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        e is AvaliaTechException ? e.message : e.toString(),
        error: true,
      );
    }
    return null;
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String confirm = 'Confirmar',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.bottom,
    this.floating,
    this.showNavigation = true,
    this.scroll = true,
    this.leading,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom, floating, leading;
  final bool showNavigation, scroll;
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: subtitle == null ? 58 : 72,
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: scroll
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [child],
                    )
                  : child,
            ),
            if (bottom != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: bottom!,
              ),
          ],
        ),
      ),
      floatingActionButton: floating,
      bottomNavigationBar: showNavigation
          ? AppBottomNav(professor: store.professor)
          : null,
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.professor});
  final bool professor;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: AppNav.selected,
    builder: (context, index, _) => BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index.clamp(0, 3),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      showUnselectedLabels: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onTap: (i) => AppNav.go(context, i),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Turmas',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Avaliações',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            professor ? Icons.insights_outlined : Icons.person_outline,
          ),
          activeIcon: Icon(professor ? Icons.insights : Icons.person),
          label: professor ? 'Resultados' : 'Perfil',
        ),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined, danger;
  @override
  Widget build(BuildContext context) {
    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: danger ? AppColors.danger : AppColors.primary,
            side: BorderSide(
              color: danger ? AppColors.danger : AppColors.border,
            ),
            minimumSize: const Size(0, 46),
          )
        : FilledButton.styleFrom(
            backgroundColor: danger ? AppColors.danger : AppColors.primary,
            minimumSize: const Size(0, 46),
          );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

class AppField extends StatelessWidget {
  const AppField(
    this.label, {
    super.key,
    this.controller,
    this.initialValue,
    this.hint,
    this.lines = 1,
    this.keyboardType,
    this.obscure = false,
    this.onChanged,
    this.validator,
    this.suffix,
  });
  final String label;
  final TextEditingController? controller;
  final String? initialValue, hint;
  final int lines;
  final TextInputType? keyboardType;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? suffix;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        initialValue: initialValue,
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        maxLines: obscure ? 1 : lines,
        minLines: lines == 1 ? 1 : null,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: onChanged,
        validator: validator,
      ),
    ],
  );
}

class AppTag extends StatelessWidget {
  const AppTag(this.text, {super.key, this.color = AppColors.primary});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 42, color: AppColors.muted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard(
    this.label,
    this.value, {
    super.key,
    this.icon = Icons.insights_outlined,
    this.color = AppColors.primary,
    this.caption,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final String? caption;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        if (caption != null)
          Text(
            caption!,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
      ],
    ),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Buscar...',
  });
  final ValueChanged<String> onChanged;
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search, color: AppColors.muted),
      hintText: hint,
      isDense: true,
    ),
  );
}

class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: children[i]),
      ],
    ],
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.icon});
  final String label, value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: AppColors.muted),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class StepHeader extends StatelessWidget {
  const StepHeader(this.step, this.labels, {super.key});
  final int step;
  final List<String> labels;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          labels.length,
          (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 5),
              decoration: BoxDecoration(
                color: i <= step ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Text(
            'Passo ${step + 1} de ${labels.length}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            labels[step],
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 18),
    ],
  );
}
