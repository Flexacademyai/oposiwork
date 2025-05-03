import 'package:equatable/equatable.dart';

class Temario extends Equatable {
  final String id;
  final String opositionId;
  final String title;
  final String description;
  final String accessType;
  final List<Topic> topics;
  final List<Resource>? resources;
  final DateTime updatedAt;

  const Temario({
    required this.id,
    required this.opositionId,
    required this.title,
    required this.description,
    required this.accessType,
    required this.topics,
    this.resources,
    required this.updatedAt,
  });

  bool get isPremium => accessType == 'premium';

  Temario copyWith({
    String? id,
    String? opositionId,
    String? title,
    String? description,
    String? accessType,
    List<Topic>? topics,
    List<Resource>? resources,
    DateTime? updatedAt,
  }) {
    return Temario(
      id: id ?? this.id,
      opositionId: opositionId ?? this.opositionId,
      title: title ?? this.title,
      description: description ?? this.description,
      accessType: accessType ?? this.accessType,
      topics: topics ?? this.topics,
      resources: resources ?? this.resources,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        opositionId,
        title,
        description,
        accessType,
        topics,
        resources,
        updatedAt,
      ];
}

class Topic extends Equatable {
  final int number;
  final String title;
  final String summary;
  final FullContent? fullContent;

  const Topic({
    required this.number,
    required this.title,
    required this.summary,
    this.fullContent,
  });

  bool get hasPremiumContent => fullContent != null;

  @override
  List<Object?> get props => [number, title, summary, fullContent];
}

class FullContent extends Equatable {
  final String? text;
  final String? pdfUrl;

  const FullContent({
    this.text,
    this.pdfUrl,
  });

  @override
  List<Object?> get props => [text, pdfUrl];
}

class Resource extends Equatable {
  final String title;
  final String description;
  final String type;
  final String url;
  final String accessType;

  const Resource({
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.accessType,
  });

  bool get isPremium => accessType == 'premium';

  @override
  List<Object?> get props => [title, description, type, url, accessType];
}
