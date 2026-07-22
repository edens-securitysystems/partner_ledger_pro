import 'package:equatable/equatable.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String ownerEmail;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String currency;
  final String? taxId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Business({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    required this.ownerEmail,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.currency = 'INR',
    this.taxId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Business copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    String? ownerEmail,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? currency,
    String? taxId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      currency: currency ?? this.currency,
      taxId: taxId ?? this.taxId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'ownerEmail': ownerEmail,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'currency': currency,
      'taxId': taxId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      logo: map['logo'] as String?,
      ownerEmail: map['ownerEmail'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      currency: map['currency'] as String? ?? 'INR',
      taxId: map['taxId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  String toJson() => throw UnimplementedError();

  factory Business.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory Business.fromJsonMap(Map<String, dynamic> json) =>
      Business.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logo,
        ownerEmail,
        address,
        phone,
        email,
        website,
        currency,
        taxId,
        createdAt,
        updatedAt,
        isActive,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Business &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.logo == logo &&
        other.ownerEmail == ownerEmail &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.website == website &&
        other.currency == currency &&
        other.taxId == taxId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      logo,
      ownerEmail,
      address,
      phone,
      email,
      website,
      currency,
      taxId,
      createdAt,
      updatedAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, ownerEmail: $ownerEmail, '
        'currency: $currency, isActive: $isActive)';
  }
}
