import 'package:flutter/material.dart';
import '../../core/model/notification_model.dart';
import '../../core/services/fcm_notification_services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FcmNotificationServices _notificationService =
  FcmNotificationServices();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications =
      await _notificationService.getSavedNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await _notificationService.clearNotifications();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "নোটিফিকেশন",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: "সব মুছুন",
            ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())

          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "কোনো নোটিফিকেশন নেই",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )

          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];

          return Card(
            color: isDark
                ? const Color(0xFF1E1E32)
                : Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                const Color(0xFF60DCB2).withOpacity(0.2),
                child: const Icon(
                  Icons.notifications,
                  color: Color(0xFF60DCB2),
                ),
              ),

              title: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notification.body),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} মিনিট আগে";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} ঘণ্টা আগে";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }
}