class HistoryModel {
  final String id;
  final String type; // 'generated' or 'scanned'
  final String qrType; // 'Text', 'Website', 'Wi-Fi', etc.
  final String title;
  final String data;
  final DateTime createdAt;
  final bool saved;
  final bool shared;

  HistoryModel({
    required this.id,
    required this.type,
    required this.qrType,
    required this.title,
    required this.data,
    required this.createdAt,
    this.saved = false,
    this.shared = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'qrType': qrType,
      'title': title,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'saved': saved,
      'shared': shared,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HistoryModel(
      id: documentId,
      type: map['type'] ?? 'generated',
      qrType: map['qrType'] ?? 'Text',
      title: map['title'] ?? '',
      data: map['data'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      saved: map['saved'] ?? false,
      shared: map['shared'] ?? false,
    );
  }
}