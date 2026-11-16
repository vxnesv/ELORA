import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({
    super.key,
    required this.store,
    required this.onNavigate,
    required this.onAssistente,
    required this.onTrabalho,
    required this.onAmbiente,
  });

  final EloraStore store;
  final ValueChanged<int> onNavigate;
  final VoidCallback onAssistente;
  final VoidCallback onTrabalho;
  final VoidCallback onAmbiente;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return ColunaConteudo(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${store.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Como posso ajudar você hoje?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const LogoCircular(size: 55),
          ],
        ),
        if (store.falhaAoSalvar) ...[
          const SizedBox(height: 12),
          const AvisoDiscreto(
            icon: Icons.warning_amber_rounded,
            text:
                'Não foi possível confirmar o armazenamento local. Revise os dados antes de fechar o aplicativo.',
          ),
        ],
        const SizedBox(height: 18),
        _DestaqueAssistente(onTap: onAssistente),
        const SizedBox(height: 20),
        CartaoElora(
          color: colors.surfaceAlt,
          onTap: onAmbiente,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: colors.accent, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cenário ilustrativo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Calor intenso · 32°C (exemplo)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sem consulta ao clima em tempo real',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.accent),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Escolha por onde começar'),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 40) return const SizedBox.shrink();
            final itemWidth = constraints.maxWidth < 320
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Atalho(
                  width: itemWidth,
                  icon: Icons.favorite_border_rounded,
                  title: 'Minha saúde',
                  subtitle: 'Indicadores e metas',
                  onTap: () => onNavigate(1),
                ),
                _Atalho(
                  width: itemWidth,
                  icon: Icons.work_outline_rounded,
                  title: 'Meu trabalho',
                  subtitle: 'Rotina e pausas',
                  onTap: onTrabalho,
                ),
                _Atalho(
                  width: itemWidth,
                  icon: Icons.eco_outlined,
                  title: 'Meu ambiente',
                  subtitle: 'Contexto e clima',
                  onTap: onAmbiente,
                ),
                _Atalho(
                  width: itemWidth,
                  icon: Icons.shield_outlined,
                  title: 'Minha proteção',
                  subtitle: 'Plano e ajuda',
                  onTap: () => onNavigate(2),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        CartaoElora(
          onTap: () => onNavigate(4),
          child: Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: colors.accent, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu cuidado contínuo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.registros.length} registros · ${store.metasConcluidasHoje} metas hoje · ${store.tarefasPlanoConcluidas}/${store.plano.length} itens do plano',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestaqueAssistente extends StatelessWidget {
  const _DestaqueAssistente({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroStart, colors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -15,
            top: -25,
            child: Opacity(opacity: 0.7, child: LogoCircular(size: 170)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: Color(0xFFFFDCA6),
                ),
                const Spacer(),
                const Text(
                  'Como posso te ajudar hoje?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Entenda um indicador, prepare-se para o calor ou organize sua próxima consulta.',
                  style: TextStyle(
                    color: Color(0xFFFFE9D9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEACB),
                    foregroundColor: const Color(0xFF5D2413),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Conversar com a ELORA'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return SizedBox(
      width: width,
      height: 124,
      child: CartaoElora(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colors.accent, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
