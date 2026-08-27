/// Logic Tier — Controller
/// Path: lib/logic/controllers/student_notification_controller.dart
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class StudentNotificationController extends ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _subscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppNotification> _notifications = [];

  StudentNotificationController(this._repository) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToNotifications(user.uid);
      } else {
        _unsubscribe();
      }
    });
  }

  void _subscribeToNotifications(String uid) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs
          .map((d) => AppNotification.fromMap(d.data(), d.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('StudentNotificationController stream error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Refetches notifications (no-op now since it's real-time stream).
  Future<void> refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _subscribeToNotifications(uid);
    }
  }

  // ── Getters ────────────────────────────
  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Marks a notification as read and persists it to Firestore.
  Future<void> markAsRead(AppNotification item) async {
    if (item.isRead) return;
    item.isRead = true;
    notifyListeners();
    try {
      await _repository.markAsRead(item.id);
    } catch (e) {
      debugPrint('StudentNotificationController.markAsRead error: $e');
      item.isRead = false;
      notifyListeners();
    }
  }

  /// Cancel all active Firestore stream subscriptions without disposing the
  /// controller. Called by the logout helper before FirebaseAuth.signOut().
  void cancelSubscriptions() {
    _authSub?.cancel();
    _authSub = null;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
