import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gamification_provider.dart';
import '../services/gamification_service.dart';
import '../models/gamification_models.dart';

class BadgeNotificationManager extends ConsumerStatefulWidget {
  final Widget child;

  const BadgeNotificationManager({super.key, required this.child});

  @override
  ConsumerState<BadgeNotificationManager> createState() =>
      _BadgeNotificationManagerState();
}

class _BadgeNotificationManagerState
    extends ConsumerState<BadgeNotificationManager> {
  Set<String> _knownBadgeIds = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    // Listen to the stream
    ref.listen<AsyncValue<List<UserBadge>>>(userBadgesProvider, (prev, next) {
      next.whenData((badges) {
        if (!_initialized) {
          // First load: just populate the set, don't notify
          _knownBadgeIds = badges.map((b) => b.badgeId).toSet();
          _initialized = true;
          return;
        }

        // Subsequent updates: check for new badges
        for (final badge in badges) {
          if (!_knownBadgeIds.contains(badge.badgeId)) {
            _knownBadgeIds.add(badge.badgeId);
            _showBadgeNotification(badge);
          }
        }
      });
    });

    return widget.child;
  }

  void _showBadgeNotification(UserBadge badge) {
    // Find config
    final badgeConfig = GamificationService.AVAILABLE_BADGES.firstWhere(
      (b) => b.id == badge.badgeId,
      orElse: () => BadgeConfig(
        id: badge.badgeId,
        name: 'New Badge',
        description: 'You earned a new badge!',
        iconPath: 'assets/badges/starter.png',
      ),
    );

    // Show Dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie or Image
              Image.asset(badgeConfig.iconPath, height: 100, width: 100,
                  errorBuilder: (c, e, s) {
                return const Icon(Icons.emoji_events,
                    size: 80, color: Colors.amber);
              }),
              const SizedBox(height: 16),
              const Text(
                'Tebrikler!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                '${badgeConfig.name} rozetini kazandın!',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                badgeConfig.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Harika!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
