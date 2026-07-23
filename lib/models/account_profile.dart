import 'package:uuid/uuid.dart';

class AccountProfile {
  final String id;
  final String label;
  final String providerId; // ProviderId.rawValue
  final bool isEnabled;
  final int sortOrder;
  final DateTime createdAt;

  AccountProfile({
    String? id,
    required this.label,
    required this.providerId,
    this.isEnabled = true,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AccountProfile copyWith({
    String? label,
    String? providerId,
    bool? isEnabled,
    int? sortOrder,
  }) {
    return AccountProfile(
      id: id,
      label: label ?? this.label,
      providerId: providerId ?? this.providerId,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'providerId': providerId,
        'isEnabled': isEnabled,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
        id: json['id'] as String,
        label: json['label'] as String,
        providerId: json['providerId'] as String,
        isEnabled: json['isEnabled'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AccountProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
