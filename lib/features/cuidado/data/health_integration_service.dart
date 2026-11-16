import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../../core/domain/contexto_cuidado.dart';

enum EstadoIntegracaoSaude { concluida, negada, indisponivel }

class ResultadoIntegracaoSaude {
  const ResultadoIntegracaoSaude(this.estado, this.metricas);

  final EstadoIntegracaoSaude estado;
  final List<MetricaConectada> metricas;
}

class HealthIntegrationService {
  HealthIntegrationService({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const _types = <HealthDataType>[
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  Future<ResultadoIntegracaoSaude> autorizarEImportar() async {
    if (kIsWeb ||
        !const {
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      return const ResultadoIntegracaoSaude(
        EstadoIntegracaoSaude.indisponivel,
        [],
      );
    }

    await _health.configure();
    if (defaultTargetPlatform == TargetPlatform.android &&
        !await _health.isHealthConnectAvailable()) {
      return const ResultadoIntegracaoSaude(
        EstadoIntegracaoSaude.indisponivel,
        [],
      );
    }

    final availableTypes = _types
        .where(_health.isDataTypeAvailable)
        .toList(growable: false);
    final permissions = List<HealthDataAccess>.filled(
      availableTypes.length,
      HealthDataAccess.READ,
    );
    final authorized = await _health.requestAuthorization(
      availableTypes,
      permissions: permissions,
    );
    if (!authorized) {
      return const ResultadoIntegracaoSaude(EstadoIntegracaoSaude.negada, []);
    }

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final points = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(
        types: availableTypes,
        startTime: start,
        endTime: end,
      ),
    );
    final metrics = points.map(_mapPoint).whereType<MetricaConectada>().toList()
      ..sort((a, b) => b.registradaEm.compareTo(a.registradaEm));
    return ResultadoIntegracaoSaude(
      EstadoIntegracaoSaude.concluida,
      metrics.take(200).toList(growable: false),
    );
  }

  MetricaConectada? _mapPoint(HealthDataPoint point) {
    final value = point.value;
    if (value is! NumericHealthValue) return null;
    final type = switch (point.type) {
      HealthDataType.HEART_RATE => TipoMetricaConectada.frequenciaCardiaca,
      HealthDataType.RESTING_HEART_RATE =>
        TipoMetricaConectada.frequenciaRepouso,
      HealthDataType.BLOOD_GLUCOSE => TipoMetricaConectada.glicemia,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC =>
        TipoMetricaConectada.pressaoSistolica,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC =>
        TipoMetricaConectada.pressaoDiastolica,
      _ => null,
    };
    if (type == null) return null;
    return MetricaConectada(
      id: point.uuid,
      tipo: type,
      valor: value.numericValue.toDouble(),
      registradaEm: point.dateTo,
      fonte: point.sourceName.trim().isEmpty
          ? point.sourcePlatform.name
          : point.sourceName,
    );
  }
}
