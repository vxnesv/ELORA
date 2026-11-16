import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/domain/contexto_cuidado.dart';
import '../../../core/domain/modelos_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/dialogo_texto.dart';
import '../../../core/presentation/tema_elora.dart';
import '../data/health_integration_service.dart';
import '../data/medication_notification_service.dart';

class CuidadoConectadoScreen extends StatefulWidget {
  CuidadoConectadoScreen({
    super.key,
    required this.store,
    HealthIntegrationService? healthService,
    MedicationNotificationService? notificationService,
  }) : healthService = healthService ?? HealthIntegrationService(),
       notificationService =
           notificationService ?? MedicationNotificationService();

  final EloraStore store;
  final HealthIntegrationService healthService;
  final MedicationNotificationService notificationService;

  @override
  State<CuidadoConectadoScreen> createState() => _CuidadoConectadoScreenState();
}

class _CuidadoConectadoScreenState extends State<CuidadoConectadoScreen> {
  bool _importando = false;
  bool _configurandoAlertas = false;

  Future<void> _importarSaude() async {
    setState(() => _importando = true);
    try {
      final result = await widget.healthService.autorizarEImportar();
      if (!mounted) return;
      switch (result.estado) {
        case EstadoIntegracaoSaude.concluida:
          widget.store.salvarMetricasImportadas(result.metricas);
          _message(
            result.metricas.isEmpty
                ? 'Permissão concedida, mas nenhum registro foi encontrado nos últimos 7 dias.'
                : '${result.metricas.length} registros importados com sua autorização.',
          );
        case EstadoIntegracaoSaude.negada:
          _message('A permissão não foi concedida. Nenhum dado foi importado.');
        case EstadoIntegracaoSaude.indisponivel:
          _message(
            'A integração está disponível em celulares com Health Connect ou Apple Saúde.',
          );
      }
    } catch (_) {
      if (mounted) {
        _message(
          'Não foi possível acessar os dados de saúde neste dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<void> _registrarNumero(
    TipoMetricaConectada type, {
    String? label,
  }) async {
    final input = await mostrarDialogoTexto(
      context,
      title: 'Registrar ${type.rotulo.toLowerCase()}',
      label: label ?? 'Valor em ${type.unidade}',
      maxLength: 10,
    );
    if (input == null || !mounted) return;
    final value = double.tryParse(input.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0 || value > 10000) {
      _message('Digite um valor numérico válido.');
      return;
    }
    widget.store.adicionarMetricaManual(type, value);
  }

  Future<void> _registrarPressao() async {
    final systolic = await mostrarDialogoTexto(
      context,
      title: 'Registrar pressão',
      label: 'Primeiro valor mostrado no aparelho',
      maxLength: 3,
    );
    if (systolic == null || !mounted) return;
    final diastolic = await mostrarDialogoTexto(
      context,
      title: 'Registrar pressão',
      label: 'Segundo valor mostrado no aparelho',
      maxLength: 3,
    );
    if (diastolic == null || !mounted) return;
    final first = double.tryParse(systolic.trim());
    final second = double.tryParse(diastolic.trim());
    if (first == null || second == null || first <= 0 || second <= 0) {
      _message('Confira os dois valores informados.');
      return;
    }
    widget.store
      ..adicionarMetricaManual(TipoMetricaConectada.pressaoSistolica, first)
      ..adicionarMetricaManual(TipoMetricaConectada.pressaoDiastolica, second);
  }

  Future<void> _registrarInsulina() async {
    final input = await mostrarDialogoTexto(
      context,
      title: 'Registrar insulina',
      label: 'Quantidade aplicada conforme sua prescrição',
      maxLength: 8,
    );
    if (input == null || !mounted) return;
    final units = double.tryParse(input.trim().replaceAll(',', '.'));
    if (units == null || units <= 0 || units > 1000) {
      _message('Confira a quantidade informada.');
      return;
    }
    widget.store.registrarInsulina(units);
  }

  Future<void> _adicionarMedicamento() async {
    final name = await mostrarDialogoTexto(
      context,
      title: 'Novo lembrete',
      label: 'Nome usado por você para identificar o medicamento',
      maxLength: 80,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'HORÁRIO DEFINIDO NA SUA ROTINA',
    );
    if (time == null) return;
    final medication = widget.store.adicionarMedicamento(
      name,
      TimeOfDayValue(time.hour, time.minute),
    );
    if (medication != null && widget.store.lembretesSistemaAtivos) {
      final scheduled = await widget.notificationService.scheduleDaily(
        medication,
      );
      if (!scheduled && mounted) {
        widget.store.definirLembretesSistema(false);
        _message(
          'O lembrete foi salvo no app, mas o alerta do celular precisa ser ativado novamente.',
        );
      }
    }
  }

  Future<void> _ativarAlertas() async {
    setState(() => _configurandoAlertas = true);
    final allowed = await widget.notificationService.requestPermission();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _configurandoAlertas = false);
      _message(
        'Sem a permissão de notificações, os lembretes continuam visíveis apenas dentro da ELORA.',
      );
      return;
    }
    var scheduled = true;
    for (final medication in widget.store.medicamentos) {
      scheduled =
          await widget.notificationService.scheduleDaily(medication) &&
          scheduled;
    }
    widget.store.definirLembretesSistema(scheduled);
    setState(() => _configurandoAlertas = false);
    _message(
      scheduled
          ? 'Alertas diários ativados. O texto da tela bloqueada será discreto.'
          : 'A permissão foi concedida, mas não foi possível programar os alertas.',
    );
  }

  Future<void> _removerMedicamento(MedicamentoAgendado medication) async {
    await widget.notificationService.cancel(medication);
    widget.store.removerMedicamento(medication.id);
  }

  Future<void> _confirmarMedicamento(MedicamentoAgendado medication) async {
    widget.store.confirmarMedicamento(medication.id);
    if (widget.store.lembretesSistemaAtivos) {
      await widget.notificationService.scheduleDaily(
        medication,
        startTomorrow: true,
      );
    }
  }

  Future<void> _registrarSintoma() async {
    final symptom = await mostrarDialogoTexto(
      context,
      title: 'Registrar sintoma',
      label: 'Descreva com suas palavras',
      maxLength: 120,
      maxLines: 3,
    );
    if (symptom != null && symptom.trim().isNotEmpty) {
      widget.store.registrarEventoCiclo(
        TipoEventoCiclo.sintoma,
        description: symptom,
      );
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final colors = CoresElora.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuidado conectado')),
      body: ColunaConteudo(
        children: [
          const CabecalhoPagina(
            icon: Icons.health_and_safety_outlined,
            title: 'Seu cuidado, do seu jeito',
            subtitle:
                'Escolha somente o que faz sentido para você. Tudo é opcional.',
          ),
          const AvisoDiscreto(
            icon: Icons.privacy_tip_outlined,
            text:
                'A ELORA organiza registros e lembretes. Não diagnostica, não altera tratamentos e não recomenda doses.',
          ),
          const SizedBox(height: 22),
          const CabecalhoSecao(title: 'Orientações para agora'),
          if (store.orientacoesContextuais.isEmpty)
            const AvisoDiscreto(
              icon: Icons.check_circle_outline_rounded,
              text: 'Nenhum lembrete pendente neste momento.',
            )
          else
            for (final insight in store.orientacoesContextuais) ...[
              CartaoElora(
                color: colors.surfaceAlt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      insight.mensagem,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 18),
          const CabecalhoSecao(title: 'Relógio e aplicativos de saúde'),
          CartaoElora(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Importar dados autorizados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'A ELORA solicitará acesso de leitura a batimentos, glicemia e pressão. Só aparecem dados que um dispositivo compatível registrou.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (store.ultimaSincronizacaoSaude != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Última atualização: ${dataCurta(store.ultimaSincronizacaoSaude!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _importando ? null : _importarSaude,
                  icon: _importando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.watch_outlined),
                  label: Text(
                    store.integracaoSaudeAtiva
                        ? 'Atualizar dados conectados'
                        : 'Conectar com minha autorização',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const CabecalhoSecao(title: 'Necessidades de cuidado'),
          CartaoElora(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Diabetes'),
                  subtitle: const Text(
                    'Refeições, glicemia e registro de insulina.',
                  ),
                  value: store.diabetesAtivo,
                  onChanged: store.definirDiabetes,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hipertensão'),
                  subtitle: const Text('Organização de medições de pressão.'),
                  value: store.hipertensaoAtiva,
                  onChanged: store.definirHipertensao,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Acompanhar ciclo menstrual'),
                  subtitle: const Text(
                    'Datas e sintomas, sem previsão clínica ou de fertilidade.',
                  ),
                  value: store.cicloAtivo,
                  onChanged: store.definirCiclo,
                ),
              ],
            ),
          ),
          if (store.diabetesAtivo) ...[
            const SizedBox(height: 18),
            const CabecalhoSecao(title: 'Diabetes e rotina'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: store.registrarRefeicao,
                  icon: const Icon(Icons.restaurant_outlined),
                  label: const Text('Já me alimentei'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _registrarNumero(TipoMetricaConectada.glicemia),
                  icon: const Icon(Icons.bloodtype_outlined),
                  label: const Text('Registrar glicemia'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _registrarInsulina,
                  icon: const Icon(Icons.vaccines_outlined),
                  label: const Text('Registrar insulina'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lembrar de conferir a refeição após aproximadamente ${store.intervaloRefeicaoHoras} horas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: store.intervaloRefeicaoHoras.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: '${store.intervaloRefeicaoHoras} h',
              onChanged: (value) =>
                  store.definirIntervaloRefeicao(value.round()),
            ),
          ],
          if (store.hipertensaoAtiva) ...[
            const SizedBox(height: 18),
            const CabecalhoSecao(title: 'Pressão arterial'),
            FilledButton.tonalIcon(
              onPressed: _registrarPressao,
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Registrar medição do aparelho'),
            ),
          ],
          const SizedBox(height: 24),
          CabecalhoSecao(
            title: 'Lembretes de medicamentos',
            action: TextButton.icon(
              onPressed: _adicionarMedicamento,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Adicionar'),
            ),
          ),
          const AvisoDiscreto(
            icon: Icons.medication_outlined,
            text:
                'Use o horário orientado pelo seu profissional. A ELORA apenas lembra e registra a confirmação.',
          ),
          const SizedBox(height: 10),
          if (!store.lembretesSistemaAtivos)
            OutlinedButton.icon(
              onPressed: _configurandoAlertas ? null : _ativarAlertas,
              icon: _configurandoAlertas
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: const Text('Ativar alertas no celular'),
            )
          else
            const AvisoDiscreto(
              icon: Icons.notifications_active_rounded,
              text: 'Alertas diários do celular estão ativos.',
            ),
          const SizedBox(height: 10),
          if (store.medicamentos.isEmpty)
            Text(
              'Nenhum lembrete configurado.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final medication in store.medicamentos) ...[
              CartaoElora(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(child: Text(medication.horarioFormatado)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        medication.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!medication.confirmadoEm(DateTime.now()))
                      IconButton.filledTonal(
                        tooltip: 'Confirmar que tomei',
                        onPressed: () => _confirmarMedicamento(medication),
                        icon: const Icon(Icons.check_rounded),
                      )
                    else
                      Icon(Icons.check_circle_rounded, color: colors.accent),
                    IconButton(
                      tooltip: 'Remover lembrete',
                      onPressed: () => _removerMedicamento(medication),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (store.cicloAtivo) ...[
            const SizedBox(height: 24),
            const CabecalhoSecao(title: 'Ciclo menstrual'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () =>
                      store.registrarEventoCiclo(TipoEventoCiclo.inicio),
                  child: const Text('Registrar início'),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      store.registrarEventoCiclo(TipoEventoCiclo.fim),
                  child: const Text('Registrar fim'),
                ),
                FilledButton.tonal(
                  onPressed: _registrarSintoma,
                  child: const Text('Registrar sintoma'),
                ),
              ],
            ),
          ],
          if (store.metricasConectadas.isNotEmpty) ...[
            const SizedBox(height: 24),
            const CabecalhoSecao(title: 'Registros recentes'),
            for (final metric in store.metricasConectadas.take(8)) ...[
              CartaoElora(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(metric.tipo.rotulo),
                          Text(
                            '${dataCurta(metric.registradaEm)} · ${metric.fonte}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${metric.valor.toStringAsFixed(metric.valor == metric.valor.roundToDouble() ? 0 : 1)} ${metric.tipo.unidade}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
