import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_admin/core/services/firebase_notification_service.dart';
import 'package:crm_admin/core/constants/app_colors.dart';

/// Screen to view and test Firebase notifications
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notificationService = FirebaseNotificationService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() {
      _fcmToken = _notificationService.fcmToken;
    });
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Token copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'FCM Token',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_fcmToken != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          _fcmToken!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.info),
                        const SizedBox(width: 8),
                        const Text(
                          'How to Test Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Copy the FCM token above\n'
                      '2. Use Firebase Console or your backend to send a test notification\n'
                      '3. Notifications will work in:\n'
                      '   • Foreground (app open)\n'
                      '   • Background (app minimized)\n'
                      '   • Terminated (app closed)\n\n'
                      '4. Notification features:\n'
                      '   ✓ Sound\n'
                      '   ✓ Vibration\n'
                      '   ✓ Visual alerts\n'
                      '   ✓ Click handling',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Topic Subscription Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.topic, color: AppColors.accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Topic Subscriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Subscribe to topics to receive group notifications:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTopicChip('all_users'),
                        _buildTopicChip('leads_updates'),
                        _buildTopicChip('admin_alerts'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test with cURL
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.code, color: AppColors.warning),
                        const SizedBox(width: 8),
                        const Text(
                          'Test with cURL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        'Use Firebase Console > Cloud Messaging\n'
                        'or send via your backend API',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip(String topic) {
    return ActionChip(
      label: Text(topic),
      onPressed: () async {
        await _notificationService.subscribeToTopic(topic);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscribed to $topic'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: const TextStyle(color: AppColors.primary),
    );
  }
}
