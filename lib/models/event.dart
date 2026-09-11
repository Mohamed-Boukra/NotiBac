class Event {
  final int? id;
  final String title;
  final String date;
  final String description;
  final int listId;
  final bool isCustom;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.listId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'description': description,
      'listId': listId,
      'isCustom': isCustom,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      listId: json['listId'] as int? ?? 1,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Event copyWith({
    int? id,
    String? title,
    String? date,
    String? description,
    int? listId,
    bool? isCustom,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      listId: listId ?? this.listId,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
