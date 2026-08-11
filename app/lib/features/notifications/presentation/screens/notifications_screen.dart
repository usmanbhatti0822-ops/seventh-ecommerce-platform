import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/notifications_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/error_view.dart";

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) => switch (type) {
        "order" => Icons.local_shipping_outlined,
        "promo" => Icons.local_offer_outlined,
        _ => Icons.notifications_none,
      };

  String _relativeTime(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return "";
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Notifications")),
      body: notificationsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
          ),
        ),
        error: (err, _) => ErrorView(message: "Could not load notifications", onRetry: () => ref.invalidate(notificationsProvider)),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(message: "No notifications yet", icon: Icons.notifications_none);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final read = n["read"] == true;
                return InkWell(
                  onTap: read
                      ? null
                      : () async {
                          await ref.read(notificationsRepositoryProvider).markRead(n["id"]);
                          ref.invalidate(notificationsProvider);
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: read ? AppColors.paperDim : AppColors.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.ink.withValues(alpha: 0.1),
                        child: Icon(_iconFor(n["type"]), color: AppColors.ink),
                      ),
                      title: Text(n["title"], style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      subtitle: Text(n["body"], style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_relativeTime(n["createdAt"]), style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft)),
                          if (!read) ...[
                            const SizedBox(height: 6),
                            const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
