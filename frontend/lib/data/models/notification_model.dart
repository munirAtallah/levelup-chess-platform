import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

String _getRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    final mins = difference.inMinutes;
    return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
  } else if (difference.inHours < 24) {
    final hrs = difference.inHours;
    return '$hrs ${hrs == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  } else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'assignment', 'grade', 'lesson', 'material'
  final String? relatedId; // ID of the related assignment/lesson
  bool isRead;
  final DateTime createdAt;
  final String recipientUid;

  String get time => _getRelativeTime(createdAt);

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    required this.recipientUid,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String documentId) {
    return AppNotification(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      relatedId: map['relatedId'] as String?,
      isRead: map['isRead'] ?? false,
      createdAt: _parseDate(map['createdAt']),
      recipientUid: map['recipientUid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'recipientUid': recipientUid,
    };
  }
}
