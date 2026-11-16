import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/domain/modelos_elora.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../domain/resumo_relatorio.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key, required this.store});

  final EloraStore store;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    final summary = montarResumoConsulta(
      registros: store.registros,
      metas: store.metas,
      note: store.notaConsulta,
      today: DateTime.now(),
    );
    return ColunaConteudo(
      children: [
        const CabecalhoPagina(
          icon: Icons.bar_chart_rounded,
          title: 'Relatórios',
          subtitle: 'Veja o que você registrou e prepare a próxima consulta.',
        ),
        const AvisoDiscreto(
          icon: Icons.info_outline_rounded,
          text:
              'Os números abaixo são calculados apenas com seus registros. Eles não representam avaliação de saúde.',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _CartaoEstatistica(
                label: 'Registros',
                value: '${store.registros.length}',
                icon: Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CartaoEstatistica(
                label: 'Metas hoje',
                value: '${store.metasConcluidasHoje}',
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CartaoEstatistica(
                label: 'Plano',
                value: '${store.tarefasPlanoConcluidas}/${store.plano.length}',
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Registros nos últimos 7 dias'),
        CartaoElora(
          child: store.registros.isEmpty
              ? const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Adicione um registro para ver seu histórico.'),
                  ),
                )
              : _BarrasSemanais(counts: store.registrosPorDiaRecente),
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Histórico recente'),
        if (store.registros.isEmpty)
          const AvisoDiscreto(
            icon: Icons.history_rounded,
            text: 'Nenhum indicador foi registrado ainda.',
          )
        else
          for (final registro in store.registros.take(5)) ...[
            CartaoElora(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(_iconFor(registro.indicador), color: colors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registro.indicador.rotulo,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          dataCurta(registro.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    registro.indicador.formatar(registro.value),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    tooltip: 'Excluir registro',
                    onPressed: () => store.removerRegistro(registro.id),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Resumo para a consulta'),
        CartaoElora(
          child: SelectableText(
            summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: summary));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Resumo copiado. Revise antes de compartilhar.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar resumo'),
        ),
      ],
    );
  }

  IconData _iconFor(TipoIndicador indicador) => switch (indicador) {
    TipoIndicador.hidratacao => Icons.water_drop_outlined,
    TipoIndicador.sono => Icons.nightlight_outlined,
    TipoIndicador.frequenciaCardiaca => Icons.monitor_heart_outlined,
  };
}

class _CartaoEstatistica extends StatelessWidget {
  const _CartaoEstatistica({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return CartaoElora(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 22),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BarrasSemanais extends StatelessWidget {
  const _BarrasSemanais({required this.counts});
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    final maxCount = math.max(1, counts.reduce(math.max));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quantidade de registros por dia',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final day = DateTime.now().subtract(Duration(days: 6 - index));
            return Expanded(
              child: Column(
                children: [
                  Text(
                    '${counts[index]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 90,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 20,
                        height: counts[index] == 0
                            ? 3
                            : 90 * counts[index] / maxCount,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}/${day.month}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
