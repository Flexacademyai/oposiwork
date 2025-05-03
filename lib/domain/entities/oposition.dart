import 'package:equatable/equatable.dart';

class Oposition extends Equatable {
  final String id;
  final String title;
  final String entity;
  final String entityType;
  final String? province;
  final String? autonomousCommunity;
  final String opositionType;
  final String academicLevel;
  final int places;
  final String status;
  final DateTime publicationDate;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final List<DateTime>? examDates;
  final List<String> requirements;
  final Salary? salary;
  final OriginalSource originalSource;
  final String? temarioId;
  final DateTime updatedAt;

  const Oposition({
    required this.id,
    required this.title,
    required this.entity,
    required this.entityType,
    this.province,
    this.autonomousCommunity,
    required this.opositionType,
    required this.academicLevel,
    required this.places,
    required this.status,
    required this.publicationDate,
    this.registrationStartDate,
    this.registrationEndDate,
    this.examDates,
    required this.requirements,
    this.salary,
    required this.originalSource,
    this.temarioId,
    required this.updatedAt,
  });

  bool get isOpen {
    if (status != 'abierta') return false;
    if (registrationEndDate == null) return true;
    return registrationEndDate!.isAfter(DateTime.now());
  }

  bool get isUpcoming {
    return status == 'proxima';
  }

  bool get isClosed {
    return status == 'cerrada' || 
           (status == 'abierta' && 
            registrationEndDate != null && 
            registrationEndDate!.isBefore(DateTime.now()));
  }

  Oposition copyWith({
    String? id,
    String? title,
    String? entity,
    String? entityType,
    String? province,
    String? autonomousCommunity,
    String? opositionType,
    String? academicLevel,
    int? places,
    String? status,
    DateTime? publicationDate,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    List<DateTime>? examDates,
    List<String>? requirements,
    Salary? salary,
    OriginalSource? originalSource,
    String? temarioId,
    DateTime? updatedAt,
  }) {
    return Oposition(
      id: id ?? this.id,
      title: title ?? this.title,
      entity: entity ?? this.entity,
      entityType: entityType ?? this.entityType,
      province: province ?? this.province,
      autonomousCommunity: autonomousCommunity ?? this.autonomousCommunity,
      opositionType: opositionType ?? this.opositionType,
      academicLevel: academicLevel ?? this.academicLevel,
      places: places ?? this.places,
      status: status ?? this.status,
      publicationDate: publicationDate ?? this.publicationDate,
      registrationStartDate: registrationStartDate ?? this.registrationStartDate,
      registrationEndDate: registrationEndDate ?? this.registrationEndDate,
      examDates: examDates ?? this.examDates,
      requirements: requirements ?? this.requirements,
      salary: salary ?? this.salary,
      originalSource: originalSource ?? this.originalSource,
      temarioId: temarioId ?? this.temarioId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        entity,
        entityType,
        province,
        autonomousCommunity,
        opositionType,
        academicLevel,
        places,
        status,
        publicationDate,
        registrationStartDate,
        registrationEndDate,
        examDates,
        requirements,
        salary,
        originalSource,
        temarioId,
        updatedAt,
      ];
}

class Salary extends Equatable {
  final double minimum;
  final double maximum;
  final String currency;

  const Salary({
    required this.minimum,
    required this.maximum,
    required this.currency,
  });

  @override
  List<Object?> get props => [minimum, maximum, currency];
}

class OriginalSource extends Equatable {
  final String type;
  final String url;
  final String? reference;

  const OriginalSource({
    required this.type,
    required this.url,
    this.reference,
  });

  @override
  List<Object?> get props => [type, url, reference];
}
