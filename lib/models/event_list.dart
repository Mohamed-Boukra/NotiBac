class EventList {
  final int? id;
  final String name;
  final String description;
  final bool isEnabled;
  final bool isPredefined;

  EventList({
    this.id,
    required this.name,
    required this.description,
    this.isEnabled = true,
    this.isPredefined = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'isPredefined': isPredefined,
    };
  }

  factory EventList.fromJson(Map<String, dynamic> json) {
    return EventList(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      isPredefined: json['isPredefined'] as bool? ?? false,
    );
  }

  EventList copyWith({
    int? id,
    String? name,
    String? description,
    bool? isEnabled,
    bool? isPredefined,
  }) {
    return EventList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      isPredefined: isPredefined ?? this.isPredefined,
    );
  }
}
