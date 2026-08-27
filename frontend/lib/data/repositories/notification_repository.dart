import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<List<AppNotification>> getNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _col
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snap.docs
        .map((d) => AppNotification.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  Future<void> addNotification(AppNotification notification) async {
    final data = notification.toMap();
    // Set Firestore server timestamp for precise creation time
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.add(data);
  }
}
