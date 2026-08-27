/// Presentation Tier — Screen
/// Path: lib/presentation/screens/student/notifications_screen.dart
///
///  Zero mock data — notifications from StudentNotificationController
///  Uses ListenableBuilder for reactivity
library;

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/golden_icon.dart';
import 'package:go_router/go_router.dart';
import '../../../logic/controllers/student_notification_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class StudentNotificationsScreen extends StatelessWidget {
  final VoidCallback? onNavigateToHome;
  const StudentNotificationsScreen({super.key, this.onNavigateToHome});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<StudentNotificationController>();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final notifications = controller.notifications;
        final unreadCount = controller.unreadCount;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.alertsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.notificationsCount(notifications.length.toString()), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                      ])),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                          child: Text(AppLocalizations.of(context)!.newNotificationsCount(unreadCount.toString()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white)),
                        ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: notifications.isEmpty
                      ? EmptyState(icon: Icons.notifications, title: AppLocalizations.of(context)!.noNotifications, subtitle: AppLocalizations.of(context)!.allCaughtUpNotif)
                      : ListView.builder(
                          padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 100),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final item = notifications[index];

                            IconData icon;
                            Color color;
                            switch (item.type) {
                              case 'assignment':
                                icon = Icons.assignment_outlined;
                                color = AppColors.warning;
                                break;
                              case 'grade':
                                icon = Icons.emoji_events_outlined;
                                color = AppColors.success;
                                break;
                              case 'material':
                              case 'lesson':
                                icon = Icons.menu_book_outlined;
                                color = AppColors.primary;
                                break;
                              default:
                                icon = Icons.info_outline;
                                color = const Color(0xFF3B82F6);
                            }

                            return GestureDetector(
                              onTap: () {
                                controller.markAsRead(item);

                                if ((item.type == 'assignment' || item.type == 'grade') && item.relatedId != null) {
                                  context.push('/student-assignment/${item.relatedId}');
                                } else if (item.type == 'lesson' || item.type == 'material') {
                                  if (onNavigateToHome != null) {
                                    onNavigateToHome!();
                                  } else {
                                    context.go('/student');
                                  }
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: !item.isRead ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!item.isRead)
                                      Container(width: 3, height: 38, margin: const EdgeInsetsDirectional.only(end: 12), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                    GoldenIcon(icon: icon, size: 44, iconSize: 20, radius: 12),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text)),
                                      const SizedBox(height: 4),
                                      Text(item.body, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground, height: 1.3)),
                                      const SizedBox(height: 6),
                                      Text(item.time, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                                    ])),
                                    if (!item.isRead)
                                      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
