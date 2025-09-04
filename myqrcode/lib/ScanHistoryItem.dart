
class ScanHistoryItem {
  final String data;
  final String type;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.data,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'data': data,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      data: json['data'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
