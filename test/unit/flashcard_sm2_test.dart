import 'package:flutter_test/flutter_test.dart';
import 'package:oposiwork/data/models/flashcard.dart';

Flashcard _flashcardBase() => Flashcard(
      id: '00000000-0000-0000-0000-000000000001',
      temaId: '00000000-0000-0000-0000-000000000002',
      pregunta: 'Pregunta',
      respuesta: 'Respuesta',
      dificultad: 1,
      createdAt: DateTime(2026, 5, 9),
      intervalo: 1,
      repeticion: 0,
      facilidad: 2.5,
      proximaRevision: DateTime.now(),
    );

void main() {
  group('Flashcard SM-2 — calificacion 0 (no sabía)', () {
    test('reinicia intervalo y repeticion', () {
      final fc = _flashcardBase().copyWith(repeticion: 3, intervalo: 10);
      final siguiente = fc.calcularSiguienteRevision(0);
      expect(siguiente.repeticion, 0);
      expect(siguiente.intervalo, 1);
    });

    test('reduce facilidad pero no por debajo de 1.3', () {
      final fc = _flashcardBase().copyWith(facilidad: 1.4);
      final siguiente = fc.calcularSiguienteRevision(0);
      expect(siguiente.facilidad, greaterThanOrEqualTo(1.3));
    });

    test('proxima revision es mañana', () {
      final hoy = DateTime.now();
      final fc = _flashcardBase();
      final siguiente = fc.calcularSiguienteRevision(0);
      final diferencia = siguiente.proximaRevision.difference(hoy).inDays;
      expect(diferencia, lessThanOrEqualTo(1));
    });
  });

  group('Flashcard SM-2 — calificacion 2 (lo sabía)', () {
    test('primera repetición da intervalo 1', () {
      final fc = _flashcardBase().copyWith(repeticion: 0);
      final siguiente = fc.calcularSiguienteRevision(2);
      expect(siguiente.repeticion, 1);
      expect(siguiente.intervalo, 1);
    });

    test('segunda repetición da intervalo 6', () {
      final fc = _flashcardBase().copyWith(repeticion: 1, intervalo: 1);
      final siguiente = fc.calcularSiguienteRevision(2);
      expect(siguiente.repeticion, 2);
      expect(siguiente.intervalo, 6);
    });

    test('repeticiones sucesivas multiplican por facilidad', () {
      final fc = _flashcardBase().copyWith(repeticion: 2, intervalo: 6, facilidad: 2.5);
      final siguiente = fc.calcularSiguienteRevision(2);
      expect(siguiente.intervalo, (6 * 2.5).round());
    });
  });

  group('Flashcard SM-2 — calificacion 1 (dudé)', () {
    test('reinicia como calificacion 0', () {
      final fc = _flashcardBase().copyWith(repeticion: 5, intervalo: 20);
      final siguiente = fc.calcularSiguienteRevision(1);
      expect(siguiente.intervalo, 1);
      expect(siguiente.repeticion, 0);
    });
  });

  group('Flashcard.copyWith', () {
    test('crea copia con valores modificados', () {
      final fc = _flashcardBase();
      final copia = fc.copyWith(pregunta: 'Nueva pregunta', dificultad: 3);
      expect(copia.pregunta, 'Nueva pregunta');
      expect(copia.dificultad, 3);
      expect(copia.id, fc.id);
    });
  });
}
