import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/app_notification.dart';
import '../data/notification_inbox_repository.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key, this.notificationId});

  final String? notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationId = this.notificationId;
    if (notificationId != null) {
      return _NotificationDetailScreen(notificationId: notificationId);
    }
    final notifications = ref.watch(notificationInboxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.notificationsLoadFailed),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(notificationInboxProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.notificationsEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _NotificationCard(
              notification: items[index],
              onTap: () =>
                  context.push(AppRoutes.notification(items[index].id)),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    if (notification.isRead) return;
    try {
      await ref
          .read(notificationInboxRepositoryProvider)
          .markRead(notification.id);
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          AppLocalizations.of(context).notificationMarkReadFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final createdAt = notification.createdAt;
    final dateText = createdAt == null
        ? l10n.notificationJustNow
        : DateFormat.yMMMd(
            l10n.localeName,
          ).add_jm().format(createdAt.toLocal());

    return Card(
      child: ListTile(
        onTap:
            onTap ??
            (notification.isRead ? null : () => _markRead(context, ref)),
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
          color: notification.isRead
              ? null
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          switch (notification.type) {
            AppNotificationType.passwordChanged =>
              l10n.passwordChangedNotificationTitle,
          },
          style: notification.isRead
              ? null
              : const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.passwordChangedNotificationBody),
            const SizedBox(height: AppSpacing.xs),
            Text(dateText),
          ],
        ),
        trailing: notification.isRead
            ? Icon(Icons.check, semanticLabel: l10n.notificationRead)
            : IconButton(
                tooltip: l10n.markNotificationRead,
                onPressed: () => _markRead(context, ref),
                icon: const Icon(Icons.mark_email_read_outlined),
              ),
      ),
    );
  }
}

class _NotificationDetailScreen extends ConsumerWidget {
  const _NotificationDetailScreen({required this.notificationId});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notification = ref.watch(notificationProvider(notificationId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: notification.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.notificationsLoadFailed),
              TextButton(
                onPressed: () =>
                    ref.invalidate(notificationProvider(notificationId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (item) {
          if (item == null) {
            return Center(child: Text(l10n.notificationNotFound));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _NotificationCard(notification: item),
              if (!item.isRead) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _markNotificationRead(context, ref, item.id),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: Text(l10n.markNotificationRead),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _markNotificationRead(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(notificationInboxRepositoryProvider).markRead(id);
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          AppLocalizations.of(context).notificationMarkReadFailed,
        );
      }
    }
  }
}
