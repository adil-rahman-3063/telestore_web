class FileItem {
  final String id;
  final String userId;
  final String? folderId;
  final String messageId;
  final String fileName;
  final DateTime createdAt;
  final String? channelId;

  FileItem({
    required this.id,
    required this.userId,
    this.folderId,
    required this.messageId,
    required this.fileName,
    required this.createdAt,
    this.channelId,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      userId: json['user_id'],
      folderId: json['folder_id'],
      messageId: json['message_id'].toString(),
      fileName: json['file_name'],
      createdAt: DateTime.parse(json['created_at']),
      channelId: json['channel_id']?.toString(),
    );
  }
}
