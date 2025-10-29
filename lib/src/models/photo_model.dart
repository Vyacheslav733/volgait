class Photo {
  final String id;
  final String path;
  final String? title;
  final DateTime? creationDate;
  final double? latitude;
  final double? longitude;
  final bool hasGeolocation;

  Photo({
    required this.id,
    required this.path,
    this.title,
    this.creationDate,
    this.latitude,
    this.longitude,
    required this.hasGeolocation,
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
    };
  }
}
