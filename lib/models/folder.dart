class Folder {
  final String id;
  final String userId;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.userId,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      parentId: json['parent_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
