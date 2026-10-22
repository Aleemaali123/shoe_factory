import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Shop.of(context).notices.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notices = Shop.of(context).notices.notices;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notice = notices[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_none,
                        color: AppColors.deepGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(notice.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900))),
                    Text(notice.timeLabel,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notice.body,
                    style:
                        const TextStyle(color: AppColors.muted, height: 1.4)),
              ],
            ),
          );
        },
      ),
    );
  }
}
