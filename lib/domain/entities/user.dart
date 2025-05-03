import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String subscriptionType;
  final DateTime? subscriptionEndDate;
  final List<String> favoriteOpositions;
  final List<String> downloadedTemarios;
  final UserPreferences preferences;

  const User({
    required this.id,
    required this.email,
    this.name,
    required this.subscriptionType,
    this.subscriptionEndDate,
    this.favoriteOpositions = const [],
    this.downloadedTemarios = const [],
    required this.preferences,
  });

  bool get isPremium => subscriptionType != 'free';

  bool get hasActiveSubscription {
    if (subscriptionType == 'free' || subscriptionEndDate == null) {
      return false;
    }
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? subscriptionType,
    DateTime? subscriptionEndDate,
    List<String>? favoriteOpositions,
    List<String>? downloadedTemarios,
    UserPreferences? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      favoriteOpositions: favoriteOpositions ?? this.favoriteOpositions,
      downloadedTemarios: downloadedTemarios ?? this.downloadedTemarios,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        subscriptionType,
        subscriptionEndDate,
        favoriteOpositions,
        downloadedTemarios,
        preferences,
      ];
}

class UserPreferences extends Equatable {
  final List<String> provinces;
  final List<String> opositionTypes;
  final List<String> academicLevels;
  final bool notifications;

  const UserPreferences({
    this.provinces = const [],
    this.opositionTypes = const [],
    this.academicLevels = const [],
    this.notifications = true,
  });

  UserPreferences copyWith({
    List<String>? provinces,
    List<String>? opositionTypes,
    List<String>? academicLevels,
    bool? notifications,
  }) {
    return UserPreferences(
      provinces: provinces ?? this.provinces,
      opositionTypes: opositionTypes ?? this.opositionTypes,
      academicLevels: academicLevels ?? this.academicLevels,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
        provinces,
        opositionTypes,
        academicLevels,
        notifications,
      ];
}
