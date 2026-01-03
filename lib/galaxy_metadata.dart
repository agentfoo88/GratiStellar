import 'core/config/season_config.dart';

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
  
  // Season tracking fields
  final bool seasonTrackingEnabled;
  final Season? currentSeason;
  final bool isManualOverride;
  final Hemisphere hemisphere;

  GalaxyMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deleted = false,
    this.deletedAt,
    this.starCount = 0,
    this.lastViewedAt,
    this.seasonTrackingEnabled = false,
    this.currentSeason,
    this.isManualOverride = false,
    this.hemisphere = Hemisphere.north,
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
    bool? seasonTrackingEnabled,
    Season? currentSeason,
    bool? isManualOverride,
    Hemisphere? hemisphere,
  }) {
    return GalaxyMetadata(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      starCount: starCount ?? this.starCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      seasonTrackingEnabled: seasonTrackingEnabled ?? this.seasonTrackingEnabled,
      currentSeason: currentSeason ?? this.currentSeason,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      hemisphere: hemisphere ?? this.hemisphere,
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
      'seasonTrackingEnabled': seasonTrackingEnabled,
      'currentSeason': currentSeason?.name,
      'isManualOverride': isManualOverride,
      'hemisphere': hemisphere.name,
    };
  }

  factory GalaxyMetadata.fromJson(Map<String, dynamic> json) {
    // Parse season with backward compatibility
    Season? parseSeason(String? seasonName) {
      if (seasonName == null) return null;
      try {
        return Season.values.firstWhere(
          (s) => s.name == seasonName,
          orElse: () => Season.winter, // Fallback
        );
      } catch (e) {
        return null;
      }
    }

    // Parse hemisphere with backward compatibility
    Hemisphere parseHemisphere(String? hemisphereName) {
      if (hemisphereName == null) return Hemisphere.north;
      try {
        return Hemisphere.values.firstWhere(
          (h) => h.name == hemisphereName,
          orElse: () => Hemisphere.north, // Default to north
        );
      } catch (e) {
        return Hemisphere.north;
      }
    }

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
      seasonTrackingEnabled: json['seasonTrackingEnabled'] ?? false,
      currentSeason: parseSeason(json['currentSeason'] as String?),
      isManualOverride: json['isManualOverride'] ?? false,
      hemisphere: parseHemisphere(json['hemisphere'] as String?),
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