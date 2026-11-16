import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';

class TrabalhoScreen extends StatelessWidget {
  const TrabalhoScreen({super.key, required this.store});

  final EloraStore store;

  static const _rotinas = {
    'Escritório': [
      'Alterne a postura e faça pausas curtas ao longo do dia.',
      'Ajuste tela, cadeira e iluminação para reduzir desconfortos.',
      'Anote dúvidas ou incômodos persistentes para buscar orientação profissional.',
    ],
    'Em casa': [
      'Reserve momentos de pausa e organize limites entre trabalho e descanso.',
      'Observe postura, iluminação e conforto do espaço de trabalho.',
      'Mantenha água acessível e ajuste a rotina às suas necessidades.',
    ],
    'Comércio': [
      'Planeje pausas e momentos para beber água conforme sua rotina.',
      'Observe o tempo em pé e, quando possível, varie os movimentos.',
      'Procure orientação se perceber desconforto persistente.',
    ],
    'Externo': [
      'Busque sombra e acesso a água em dias quentes.',
      'Sempre que possível, evite esforço intenso nos períodos mais quentes.',
      'Acompanhe avisos oficiais de clima e de Defesa Civil da sua região.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    final dicas = _rotinas[store.contextoTrabalho] ?? _rotinas['Escritório']!;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu trabalho')),
      body: ColunaConteudo(
        children: [
          const CabecalhoPagina(
            icon: Icons.work_outline_rounded,
            title: 'Meu trabalho',
            subtitle: 'Cuidados simples para diferentes rotinas.',
          ),
          const AvisoDiscreto(
            icon: Icons.privacy_tip_outlined,
            text:
                'Escolha voluntariamente sua rotina. Este protótipo não compartilha dados com empregadores.',
          ),
          const SizedBox(height: 24),
          const CabecalhoSecao(title: 'Como é sua rotina?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rotinas.keys
                .map(
                  (rotina) => ChoiceChip(
                    label: Text(rotina),
                    selected: store.contextoTrabalho == rotina,
                    onSelected: (_) => store.definirContextoTrabalho(rotina),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          CabecalhoSecao(title: 'Para ${store.contextoTrabalho.toLowerCase()}'),
          for (var index = 0; index < dicas.length; index++) ...[
            CartaoElora(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    index == 0
                        ? Icons.access_time_rounded
                        : index == 1
                        ? Icons.self_improvement_rounded
                        : Icons.info_outline_rounded,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dicas[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              store.adicionarMeta('Fazer uma pausa durante o trabalho');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meta adicionada em Meu cuidado.'),
                ),
              );
            },
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Adicionar meta de pausa'),
          ),
        ],
      ),
    );
  }
}
