

/// Metadata for a galaxy (collection of gratitude stars)
class GalaxyMetadata {
  static const int maxNameLength = 30;
  final String id;
  final String name;
  final DateTime createdAt;
  final bool deleted;
  final DateTime? deletedAt;
  final int starCount; // Cached count
  final DateTime? lastViewedAt;

  GalaxyMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deleted = false,
    this.deletedAt,
    this.starCount = 0,
    this.lastViewedAt,
  });

  /// Create a new galaxy with timestamp ID
  factory GalaxyMetadata.create({
    required String name,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return GalaxyMetadata(
      id: 'galaxy_${now.millisecondsSinceEpoch}',
      name: name,
      createdAt: now,
      lastViewedAt: now,
    );
  }

  GalaxyMetadata copyWith({
    String? name,
    bool? deleted,
    DateTime? deletedAt,
    int? starCount,
    DateTime? lastViewedAt,
  }) {
    return GalaxyMetadata(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      starCount: starCount ?? this.starCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'starCount': starCount,
      'lastViewedAt': lastViewedAt?.millisecondsSinceEpoch,
    };
  }

  factory GalaxyMetadata.fromJson(Map<String, dynamic> json) {
    return GalaxyMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      deleted: json['deleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'])
          : null,
      starCount: json['starCount'] ?? 0,
      lastViewedAt: json['lastViewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastViewedAt'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GalaxyMetadata &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Galaxy($id: $name, stars: $starCount)';
}