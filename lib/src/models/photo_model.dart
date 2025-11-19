class Photo {
  final String id;
  final String path;
  final String? title;
  final DateTime? creationDate;
  final double? latitude;
  final double? longitude;
  final bool hasGeolocation;
  final String? originalPath;
  final List<double>? lastCropRect;

  Photo({
    required this.id,
    required this.path,
    this.title,
    this.creationDate,
    this.latitude,
    this.longitude,
    required this.hasGeolocation,
    this.originalPath,
    this.lastCropRect,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      title: map['title'],
      creationDate: map['creationDate'] != null
          ? DateTime.parse(map['creationDate'])
          : null,
      latitude: map['latitude'],
      longitude: map['longitude'],
      hasGeolocation: map['hasGeolocation'] ?? false,
      originalPath: map['originalPath'],
      lastCropRect: (map['lastCropRect'] is List)
          ? (map['lastCropRect'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'creationDate': creationDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'hasGeolocation': hasGeolocation,
      'originalPath': originalPath,
      'lastCropRect': lastCropRect,
    };
  }

  Photo copyWith({
    String? id,
    String? path,
    String? title,
    DateTime? creationDate,
    double? latitude,
    double? longitude,
    bool? hasGeolocation,
    String? originalPath,
    List<double>? lastCropRect,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      creationDate: creationDate ?? this.creationDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hasGeolocation: hasGeolocation ?? this.hasGeolocation,
      originalPath: originalPath ?? this.originalPath,
      lastCropRect: lastCropRect ?? this.lastCropRect,
    );
  }
}
