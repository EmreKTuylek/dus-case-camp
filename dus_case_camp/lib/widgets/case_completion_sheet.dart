import 'package:flutter/material.dart';
import '../models/gamification_models.dart';

class CaseCompletionSheet extends StatelessWidget {
  final String caseTitle;
  final int earnedXp;
  final List<BadgeConfig> earnedBadges;
  final VoidCallback onNextCase;
  final VoidCallback onGoHome;

  const CaseCompletionSheet({
    super.key,
    required this.caseTitle,
    required this.earnedXp,
    required this.earnedBadges,
    required this.onNextCase,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Harika İş! 🎉',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$caseTitle" vakasını başarıyla tamamladın.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 24),

          // XP Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '+$earnedXp XP',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Text('Kazanıldı', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          if (earnedBadges.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Yeni Rozetler!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: earnedBadges.length,
                itemBuilder: (context, index) {
                  final badge = earnedBadges[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        if (badge.iconPath.isNotEmpty)
                          Image.asset(badge.iconPath, height: 50, width: 50)
                        else
                          const Icon(Icons.emoji_events,
                              size: 50, color: Colors.purple),
                        const SizedBox(height: 4),
                        Text(
                          badge.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onGoHome,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ana Sayfa'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNextCase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sonraki Vaka'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Bottom safety
        ],
      ),
    );
  }
}
