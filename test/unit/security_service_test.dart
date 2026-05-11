import 'package:flutter_test/flutter_test.dart';
import 'package:oposiwork/core/services/security_service.dart';

void main() {
  group('SecurityService.sanitizar', () {
    test('elimina caracteres de control', () {
      expect(SecurityService.sanitizar('hola\x00mundo'), 'holamundo');
      expect(SecurityService.sanitizar('texto\x1Fmalicioso'), 'textomalicioso');
    });

    test('elimina tags HTML', () {
      expect(SecurityService.sanitizar('<script>alert(1)</script>'), 'alert(1)');
      expect(SecurityService.sanitizar('<b>negrita</b>'), 'negrita');
    });

    test('conserva texto normal', () {
      expect(SecurityService.sanitizar('  texto limpio  '), 'texto limpio');
      expect(SecurityService.sanitizar('Correo válido: hola@test.com'), 'Correo válido: hola@test.com');
    });

    test('conserva saltos de línea legítimos', () {
      expect(SecurityService.sanitizar('línea1\nlínea2'), 'línea1\nlínea2');
    });
  });

  group('SecurityService.sanitizarNombre', () {
    test('permite letras con acentos', () {
      expect(SecurityService.sanitizarNombre('María José'), 'María José');
      expect(SecurityService.sanitizarNombre('François Müller'), 'François Müller');
    });

    test('permite guiones y apóstrofes', () {
      expect(SecurityService.sanitizarNombre("O'Brien"), "O'Brien");
      expect(SecurityService.sanitizarNombre('López-García'), 'López-García');
    });

    test('elimina caracteres no permitidos en nombres', () {
      expect(SecurityService.sanitizarNombre('Juan<script>'), 'Juan');
      expect(SecurityService.sanitizarNombre('Ana123'), 'Ana');
    });
  });

  group('SecurityService.esUuidValido', () {
    test('acepta UUIDs válidos', () {
      expect(SecurityService.esUuidValido('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(SecurityService.esUuidValido('00000000-0000-0000-0000-000000000000'), isTrue);
    });

    test('rechaza cadenas inválidas', () {
      expect(SecurityService.esUuidValido('no-es-un-uuid'), isFalse);
      expect(SecurityService.esUuidValido(''), isFalse);
      expect(SecurityService.esUuidValido('550e8400-e29b-41d4-a716'), isFalse);
    });
  });

  group('SecurityService.esEmailValido', () {
    test('acepta emails válidos', () {
      expect(SecurityService.esEmailValido('usuario@dominio.com'), isTrue);
      expect(SecurityService.esEmailValido('nombre.apellido@empresa.es'), isTrue);
    });

    test('rechaza emails inválidos', () {
      expect(SecurityService.esEmailValido('sinArroba'), isFalse);
      expect(SecurityService.esEmailValido('@dominio.com'), isFalse);
      expect(SecurityService.esEmailValido('usuario@'), isFalse);
    });
  });

  group('SecurityService.longitudValida', () {
    test('verifica límites correctamente', () {
      expect(SecurityService.longitudValida('abc', min: 1, max: 5), isTrue);
      expect(SecurityService.longitudValida('', min: 1, max: 5), isFalse);
      expect(SecurityService.longitudValida('abcdefgh', min: 1, max: 5), isFalse);
    });
  });
}
