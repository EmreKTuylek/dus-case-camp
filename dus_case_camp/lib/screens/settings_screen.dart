import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _newWeekNotifications = true;
  bool _scoreNotifications = true; // Placeholder for direct score notifs

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newWeekNotifications = prefs.getBool('notifications_new_week') ?? true;
      _scoreNotifications = prefs.getBool('notifications_scores') ?? true;
    });
  }

  Future<void> _toggleNewWeek(bool value) async {
    setState(() => _newWeekNotifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_new_week', value);

    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic('new_weeks');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('new_weeks');
      }
    } catch (e) {
      debugPrint('Error toggling topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          Text(
            l10n.languageLabel.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildLanguageOption(
                  context: context,
                  title: l10n.languageTurkish,
                  flag: '🇹🇷',
                  isSelected: locale.languageCode == 'tr',
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('tr')),
                ),
                Divider(
                    height: 1, color: Theme.of(context).colorScheme.surfaceDim),
                _buildLanguageOption(
                  context: context,
                  title: l10n.languageEnglish,
                  flag: '🇬🇧',
                  isSelected: locale.languageCode == 'en',
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en')),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          Text(
            l10n.newWeekNotifications.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.newWeekNotifications),
                  subtitle: Text(l10n.newWeekNotificationsDesc),
                  value: _newWeekNotifications,
                  onChanged: _toggleNewWeek,
                  secondary: const Icon(Icons.notifications_active),
                ),
                Divider(
                    height: 1, color: Theme.of(context).colorScheme.surfaceDim),
                // Placeholder Score Notification
                ListTile(
                  title: const Text('Score Notifications'), // Not localized yet
                  subtitle: const Text('Always enabled.'),
                  leading: const Icon(Icons.score),
                  trailing:
                      Switch(value: true, onChanged: null), // Disabled switch
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Debug Tools Section
          if (true) ...[
            // Could check kDebugMode or admin check
            const Divider(),
            ListTile(
              title: const Text('Seed Dummy Videos (Debug)'),
              subtitle:
                  const Text('Add sample video to all cases for testing.'),
              leading: const Icon(Icons.video_library, color: Colors.orange),
              onTap: () => _seedDummyVideos(context),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color:
            isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: colorScheme.primary)
            else
              Icon(Icons.radio_button_unchecked, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDummyVideos(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final casesSnapshot =
          await FirebaseFirestore.instance.collection('cases').get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in casesSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> media = List.from(data['mediaUrls'] ?? []);
        bool hasVideo = media.any((url) => url.toString().contains('.mp4'));

        if (!hasVideo) {
          media.add(
              'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
          batch.update(doc.reference, {
            'mediaUrls': media,
            'videoUrl':
                'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            'videoType': 'vod',
          });
        }
      }

      await batch.commit();
      messenger.showSnackBar(
        const SnackBar(content: Text('All cases updated with dummy video!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error seeding videos: $e')),
      );
    }
  }
}
