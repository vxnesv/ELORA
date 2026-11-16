import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/domain/modelos_elora.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/dialogo_texto.dart';
import 'cuidado_conectado_screen.dart';

class CuidadoScreen extends StatefulWidget {
  const CuidadoScreen({super.key, required this.store});

  final EloraStore store;

  @override
  State<CuidadoScreen> createState() => _CuidadoScreenState();
}

class _CuidadoScreenState extends State<CuidadoScreen> {
  bool mostrandoMetas = false;

  void _addRecord([TipoIndicador initial = TipoIndicador.hidratacao]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _FormularioRegistro(store: widget.store, initial: initial),
    );
  }

  void _explain(TipoIndicador indicador) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                indicador.rotulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                indicador.explicacao,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              const AvisoDiscreto(
                icon: Icons.info_outline_rounded,
                text:
                    'Conteúdo educativo. Uma medição isolada não permite diagnóstico.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _addRecord(indicador);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addGoal([String suggested = '']) async {
    final title = await mostrarDialogoTexto(
      context,
      title: 'Nova meta de cuidado',
      label: 'O que você quer acompanhar?',
      initialValue: suggested,
    );
    if (title != null) widget.store.adicionarMeta(title);
  }

  Future<void> _editNote() async {
    final note = await mostrarDialogoTexto(
      context,
      title: 'Perguntas para a consulta',
      label: 'Anote dúvidas para conversar com um profissional',
      initialValue: widget.store.notaConsulta,
      maxLength: 500,
      maxLines: 5,
    );
    if (note != null) widget.store.definirNotaConsulta(note);
  }

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return ColunaConteudo(
      children: [
        const CabecalhoPagina(
          icon: Icons.favorite_border_rounded,
          title: 'Meu cuidado',
          subtitle: 'Acompanhe registros, hábitos e próximos passos.',
        ),
        const AvisoDiscreto(
          icon: Icons.science_outlined,
          text:
              'Os indicadores são informados por você. A ELORA não interpreta medições nem realiza diagnóstico clínico.',
        ),
        const SizedBox(height: 14),
        ItemAcao(
          icon: Icons.health_and_safety_outlined,
          title: 'Cuidado conectado',
          subtitle:
              'Smartwatch, diabetes, pressão, medicamentos e ciclo opcional.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CuidadoConectadoScreen(store: widget.store),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Indicadores'),
              icon: Icon(Icons.monitor_heart_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Metas'),
              icon: Icon(Icons.check_circle_outline_rounded),
            ),
          ],
          selected: {mostrandoMetas},
          onSelectionChanged: (selection) =>
              setState(() => mostrandoMetas = selection.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 22),
        if (!mostrandoMetas) ...[
          CabecalhoSecao(
            title: 'Seus indicadores',
            action: TextButton.icon(
              onPressed: () => _addRecord(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Registrar'),
            ),
          ),
          for (final indicador in TipoIndicador.values) ...[
            _CartaoIndicador(
              indicador: indicador,
              store: widget.store,
              onTap: () => _explain(indicador),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _addRecord(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar registro'),
          ),
          const SizedBox(height: 24),
          const CabecalhoSecao(title: 'Para a próxima consulta'),
          ItemAcao(
            icon: Icons.edit_note_rounded,
            title: widget.store.notaConsulta.isEmpty
                ? 'Anotar uma dúvida'
                : 'Editar suas anotações',
            subtitle: widget.store.notaConsulta.isEmpty
                ? 'Guarde perguntas para conversar com um profissional.'
                : widget.store.notaConsulta,
            onTap: _editNote,
          ),
        ] else ...[
          Text(
            '${widget.store.metasConcluidasHoje} de ${widget.store.metas.length} metas realizadas hoje',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          if (widget.store.metas.isEmpty) ...[
            const AvisoDiscreto(
              icon: Icons.flag_outlined,
              text:
                  'Você ainda não criou metas. Escolha uma ação simples que faça sentido para sua rotina.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Fazer uma pausa'),
                  onPressed: () => _addGoal('Fazer uma pausa'),
                ),
                ActionChip(
                  label: const Text('Organizar a consulta'),
                  onPressed: () => _addGoal('Organizar a consulta'),
                ),
              ],
            ),
          ] else
            for (final meta in widget.store.metas) ...[
              CartaoElora(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: meta.completedOn == chaveDia(DateTime.now()),
                      onChanged: (_) => widget.store.alternarMeta(meta.id),
                    ),
                    Expanded(
                      child: Text(
                        meta.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover meta',
                      onPressed: () => widget.store.removerMeta(meta.id),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _addGoal(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar meta'),
          ),
        ],
      ],
    );
  }
}

class _CartaoIndicador extends StatelessWidget {
  const _CartaoIndicador({
    required this.indicador,
    required this.store,
    required this.onTap,
  });
  final TipoIndicador indicador;
  final EloraStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final registro = store.ultimoRegistro(indicador);
    final colors = CoresElora.of(context);
    final icon = switch (indicador) {
      TipoIndicador.hidratacao => Icons.water_drop_outlined,
      TipoIndicador.sono => Icons.nightlight_outlined,
      TipoIndicador.frequenciaCardiaca => Icons.monitor_heart_outlined,
    };
    return CartaoElora(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 28, color: colors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicador.rotulo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  registro == null
                      ? 'Ainda sem registro'
                      : indicador.formatar(registro.value),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (registro != null)
                  Text(
                    'Registrado em ${dataCurta(registro.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Icon(Icons.info_outline_rounded, color: colors.muted),
        ],
      ),
    );
  }
}

class _FormularioRegistro extends StatefulWidget {
  const _FormularioRegistro({required this.store, required this.initial});
  final EloraStore store;
  final TipoIndicador initial;

  @override
  State<_FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<_FormularioRegistro> {
  final formKey = GlobalKey<FormState>();
  final valueController = TextEditingController();
  late TipoIndicador indicador = widget.initial;

  @override
  void dispose() {
    valueController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final value = double.parse(valueController.text.replaceAll(',', '.'));
    widget.store.adicionarRegistro(indicador, value);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adicionar registro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'Informe uma medição para acompanhar no seu histórico.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<TipoIndicador>(
              initialValue: indicador,
              decoration: const InputDecoration(labelText: 'Indicador'),
              items: TipoIndicador.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('${item.rotulo} (${item.unidade})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => indicador = value ?? indicador),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: valueController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Valor em ${indicador.unidade}',
              ),
              validator: (input) {
                final value = double.tryParse(
                  (input ?? '').replaceAll(',', '.'),
                );
                final maximum = switch (indicador) {
                  TipoIndicador.hidratacao => 10000.0,
                  TipoIndicador.sono => 24.0,
                  TipoIndicador.frequenciaCardiaca => 300.0,
                };
                if (value == null ||
                    !value.isFinite ||
                    value <= 0 ||
                    value > maximum) {
                  return 'Informe um valor entre 0 e ${maximum.toStringAsFixed(0)}.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar registro'),
            ),
          ],
        ),
      ),
    ),
  );
}
