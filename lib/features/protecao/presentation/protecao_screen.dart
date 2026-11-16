import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/abrir_externo.dart';
import '../../../core/presentation/dialogo_texto.dart';

class ProtecaoScreen extends StatelessWidget {
  const ProtecaoScreen({super.key, required this.store});

  final EloraStore store;

  Future<void> _addTask(BuildContext context) async {
    final title = await mostrarDialogoTexto(
      context,
      title: 'Novo item do plano',
      label: 'Ex.: deixar cópia dos documentos',
      maxLength: 100,
    );
    if (title != null) store.adicionarTarefa(title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return ColunaConteudo(
      children: [
        const CabecalhoPagina(
          icon: Icons.shield_outlined,
          title: 'Proteção e ajuda',
          subtitle: 'Prepare-se e encontre apoio quando precisar.',
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.heroStart, colors.heroEnd],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.emergency_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 10),
              const Text(
                'Preciso de ajuda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Acesse telefones de emergência e orientações oficiais. A ELORA não faz triagem.',
                style: TextStyle(color: Color(0xFFFFEBDD), height: 1.35),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AjudaScreen()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE8C4),
                  foregroundColor: const Color(0xFF5E2414),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Abrir ajuda agora'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Orientações para se preparar'),
        for (final guide in guides) ...[
          ItemAcao(
            icon: guide.icon,
            title: guide.title,
            subtitle: guide.subtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => GuiaScreen(guide: guide)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        CabecalhoSecao(
          title: 'Meu plano de ação',
          action: TextButton.icon(
            onPressed: () => _addTask(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Adicionar'),
          ),
        ),
        Text(
          '${store.tarefasPlanoConcluidas} de ${store.plano.length} itens preparados',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final tarefa in store.plano) ...[
          CartaoElora(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: tarefa.done,
                  onChanged: (_) => store.alternarTarefa(tarefa.id),
                ),
                Expanded(
                  child: Text(
                    tarefa.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: () => store.removerTarefa(tarefa.id),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (store.plano.isEmpty)
          const AvisoDiscreto(
            icon: Icons.list_alt_rounded,
            text:
                'Seu plano está vazio. Adicione os itens importantes para você.',
          ),
        const SizedBox(height: 12),
        const AvisoDiscreto(
          icon: Icons.info_outline_rounded,
          text:
              'Este checklist é pessoal. Consulte a Defesa Civil da sua região e siga os alertas oficiais em uma situação real.',
        ),
      ],
    );
  }
}

class Guia {
  const Guia({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.steps,
    required this.source,
    required this.urlFonte,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> steps;
  final String source;
  final String urlFonte;
}

const guides = <Guia>[
  Guia(
    title: 'Calor intenso',
    subtitle: 'Cuidados simples e sinais para buscar avaliação.',
    icon: Icons.wb_sunny_outlined,
    steps: [
      'Beba água regularmente e procure ambientes frescos ou com sombra.',
      'Reduza a exposição prolongada ao sol e adapte atividades intensas quando possível.',
      'Se houver tontura, fraqueza, náuseas ou outros sintomas, procure uma unidade de saúde para avaliação.',
    ],
    source: 'Ministério da Saúde · Ondas de calor',
    urlFonte:
        'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/o/ondas-de-calor',
  ),
  Guia(
    title: 'Enchentes',
    subtitle: 'Preparação e proteção diante de água elevada.',
    icon: Icons.water_outlined,
    steps: [
      'Mantenha documentos, medicamentos e itens essenciais em local acessível e protegido.',
      'Não entre nem atravesse áreas alagadas. Procure uma rota segura indicada pelas autoridades.',
      'Acompanhe os alertas da Defesa Civil e siga as orientações locais de saída ou abrigo.',
    ],
    source: 'Ministério da Saúde · Enchentes e inundações',
    urlFonte:
        'https://miniapps.saude.gov.br/guia-clima/como-podemos-contribuir/populacao-em-geral/enchentes-e-inundacoes',
  ),
  Guia(
    title: 'Deslizamentos',
    subtitle: 'Reconheça sinais de risco e siga autoridades.',
    icon: Icons.landscape_outlined,
    steps: [
      'Observe rachaduras, movimentação do solo e sinais apontados pela Defesa Civil local.',
      'Diante de risco aparente, saia da área e procure um lugar seguro.',
      'Siga orientações de evacuação e só retorne quando houver liberação oficial.',
    ],
    source: 'Defesa Civil do Paraná · Dicas',
    urlFonte: 'https://www.defesacivil.pr.gov.br/Pagina/Dicas',
  ),
];

class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key, required this.guide});
  final Guia guide;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(guide.title)),
    body: ColunaConteudo(
      children: [
        CabecalhoPagina(
          icon: guide.icon,
          title: guide.title,
          subtitle: guide.subtitle,
        ),
        const AvisoDiscreto(
          icon: Icons.menu_book_outlined,
          text:
              'Conteúdo educativo. Consulte as instruções oficiais atualizadas para sua localidade.',
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < guide.steps.length; index++) ...[
          CartaoElora(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 15, child: Text('${index + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guide.steps[index],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => abrirLinkExterno(context, guide.urlFonte),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text('Abrir fonte: ${guide.source}'),
        ),
      ],
    ),
  );
}

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preciso de ajuda')),
    body: ColunaConteudo(
      children: [
        const CabecalhoPagina(
          icon: Icons.emergency_outlined,
          title: 'Ajuda agora',
          subtitle:
              'Em perigo imediato, procure socorro pelos canais oficiais.',
        ),
        const AvisoDiscreto(
          icon: Icons.warning_amber_rounded,
          text:
              'A ELORA não avalia urgências. Descreva a situação e sua localização ao serviço acionado e siga as orientações recebidas.',
        ),
        const SizedBox(height: 18),
        _ItemEmergencia(
          number: '192',
          name: 'SAMU',
          description: 'Urgência e emergência em saúde.',
          icon: Icons.medical_services_outlined,
        ),
        const SizedBox(height: 10),
        _ItemEmergencia(
          number: '193',
          name: 'Bombeiros',
          description: 'Resgate e ocorrências de risco.',
          icon: Icons.fire_truck_outlined,
        ),
        const SizedBox(height: 10),
        _ItemEmergencia(
          number: '199',
          name: 'Defesa Civil',
          description: 'Riscos e desastres na sua região.',
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => abrirLinkExterno(
            context,
            'https://www.gov.br/saude/pt-br/composicao/saes/samu-192/samu-192',
          ),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Informações oficiais do SAMU'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => abrirLinkExterno(
            context,
            'https://www.gov.br/mdr/pt-br/assuntos/protecao-e-defesa-civil/alertas-de-desastres-1',
          ),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Alertas oficiais da Defesa Civil'),
        ),
      ],
    ),
  );
}

class _ItemEmergencia extends StatelessWidget {
  const _ItemEmergencia({
    required this.number,
    required this.name,
    required this.description,
    required this.icon,
  });
  final String number;
  final String name;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return CartaoElora(
      child: Row(
        children: [
          Icon(icon, color: colors.accent, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · $number',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Discar $number',
            onPressed: () => abrirLinkExterno(context, 'tel:$number'),
            icon: const Icon(Icons.call_rounded),
          ),
        ],
      ),
    );
  }
}
