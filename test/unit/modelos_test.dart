import 'package:flutter_test/flutter_test.dart';
import 'package:oposiwork/data/models/convocatoria.dart';
import 'package:oposiwork/data/models/perfil.dart';
import 'package:oposiwork/data/models/pregunta_test.dart';

final _ahora = DateTime(2026, 5, 9);

Convocatoria _convocatoria({
  String estado = 'abierta',
  DateTime? fechaInicioInstancias,
  DateTime? fechaFinInstancias,
  DateTime? fechaExamen,
}) =>
    Convocatoria(
      id: '1',
      oposicionId: '2',
      estado: estado,
      fechaExamenConfirmada: false,
      fechaInicioInstancias: fechaInicioInstancias,
      fechaFinInstancias: fechaFinInstancias,
      fechaExamen: fechaExamen,
      createdAt: _ahora,
      updatedAt: _ahora,
    );

Perfil _perfil({
  String plan = 'free',
  DateTime? planFin,
  String? nombre,
  String? apellidos,
}) =>
    Perfil(
      id: '1',
      plan: plan,
      planFin: planFin,
      nombre: nombre,
      apellidos: apellidos,
      notificacionesPush: true,
      notificacionesEmail: true,
      createdAt: _ahora,
      updatedAt: _ahora,
    );

void main() {
  group('Convocatoria — propiedades computadas', () {
    test('estaAbierta devuelve true cuando estado es abierta', () {
      final c = _convocatoria(estado: 'abierta');
      expect(c.estaAbierta, isTrue);
      expect(c.estaProxima, isFalse);
      expect(c.estaCerrada, isFalse);
    });

    test('estaCerrada incluye estado suspendida', () {
      expect(_convocatoria(estado: 'suspendida').estaCerrada, isTrue);
      expect(_convocatoria(estado: 'cerrada').estaCerrada, isTrue);
    });

    test('instanciasAbiertas true dentro del plazo', () {
      final c = _convocatoria(
        fechaInicioInstancias: DateTime.now().subtract(const Duration(days: 5)),
        fechaFinInstancias: DateTime.now().add(const Duration(days: 5)),
      );
      expect(c.instanciasAbiertas, isTrue);
    });

    test('instanciasAbiertas false cuando plazo cerrado', () {
      final c = _convocatoria(
        fechaFinInstancias: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(c.instanciasAbiertas, isFalse);
    });

    test('instanciasAbiertas false sin fechas', () {
      expect(_convocatoria().instanciasAbiertas, isFalse);
    });

    test('diasParaExamen calcula diferencia aproximada', () {
      final c = _convocatoria(
        fechaExamen: DateTime.now().add(const Duration(days: 30)),
      );
      expect(c.diasParaExamen, greaterThan(28));
      expect(c.diasParaExamen, lessThan(32));
    });

    test('diasParaExamen null sin fecha de examen', () {
      expect(_convocatoria().diasParaExamen, isNull);
    });
  });

  group('Perfil — propiedades computadas', () {
    test('esPremium true con plan monthly vigente', () {
      final p = _perfil(
        plan: 'monthly',
        planFin: DateTime.now().add(const Duration(days: 10)),
      );
      expect(p.esPremium, isTrue);
    });

    test('esPremium false con plan free', () {
      expect(_perfil(plan: 'free').esPremium, isFalse);
    });

    test('esPremium false con plan caducado', () {
      final p = _perfil(
        plan: 'annual',
        planFin: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(p.esPremium, isFalse);
    });

    test('esPremium false sin planFin aunque el plan no sea free', () {
      expect(_perfil(plan: 'monthly').esPremium, isFalse);
    });

    test('nombreCompleto combina nombre y apellidos', () {
      final p = _perfil(nombre: 'Ana', apellidos: 'García López');
      expect(p.nombreCompleto, 'Ana García López');
    });

    test('nombreCompleto solo nombre cuando no hay apellidos', () {
      expect(_perfil(nombre: 'Ana').nombreCompleto, 'Ana');
    });

    test('nombreCompleto devuelve Usuario cuando no hay datos', () {
      expect(_perfil().nombreCompleto, 'Usuario');
    });
  });

  group('PreguntaTest — métodos', () {
    final pregunta = PreguntaTest(
      id: '1',
      temaId: '2',
      oposicionId: '3',
      enunciado: '¿Cuál es la capital?',
      opcionA: 'Madrid',
      opcionB: 'Barcelona',
      opcionC: 'Valencia',
      opcionD: 'Sevilla',
      respuestaCorrecta: 'a',
      dificultad: 2,
      vecesFallada: 0,
      createdAt: _ahora,
    );

    test('esCorrecta devuelve true para respuesta correcta', () {
      expect(pregunta.esCorrecta('a'), isTrue);
    });

    test('esCorrecta devuelve false para respuesta incorrecta', () {
      expect(pregunta.esCorrecta('b'), isFalse);
    });

    test('opcionPorLetra devuelve texto de la opción', () {
      expect(pregunta.opcionPorLetra('a'), 'Madrid');
      expect(pregunta.opcionPorLetra('d'), 'Sevilla');
    });
  });
}
