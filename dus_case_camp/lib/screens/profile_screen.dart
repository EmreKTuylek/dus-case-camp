import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/gamification_service.dart';
import '../models/gamification_models.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabOverview),
              Tab(text: l10n.tabBadges),
              Tab(text: l10n.tabCertificates),
            ],
          ),
        ),
        body: userProfileAsync.when(
          data: (user) {
            if (user == null)
              return const Center(child: Text('User not found'));

            return TabBarView(
              children: [
                _buildOverviewTab(context, ref, user, l10n),
                _buildBadgesTab(context, user, l10n),
                _buildCertificatesTab(context, user.id, l10n),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref, UserModel user,
      AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          // XP Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${user.totalPoints} XP',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.indigo),
            title: Text(l10n.cardSchool),
            subtitle: Text(user.school ?? 'Not specified'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.indigo),
            title: Text(l10n.cardYear),
            subtitle: Text(user.yearOfStudy?.toString() ?? 'Not specified'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.pink),
            title: Text(l10n.cardFavorites),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/profile/favorites'),
          ),
          ListTile(
            leading: const Icon(Icons.watch_later, color: Colors.blue),
            title: Text(l10n.cardWatchLater),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/profile/watch-later'),
          ),
          const Divider(),
          if (user.role == UserRole.teacher || user.role == UserRole.admin)
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: Text(l10n.cardAdmin),
              onTap: () => context.go('/admin/dashboard'),
            ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: Text(l10n.cardSettings),
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.btnLogout),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab(
      BuildContext context, UserModel user, AppLocalizations l10n) {
    final badges = user.badges;

    if (badges.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(l10n.noBadges, style: TextStyle(color: Colors.grey[600])),
        ],
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badgeId = badges[index];
        final config = GamificationService.AVAILABLE_BADGES.firstWhere(
          (b) => b.id == badgeId,
          orElse: () => BadgeConfig(
              id: badgeId, name: 'Unknown', description: '', iconPath: ''),
        );

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.iconPath.isNotEmpty)
                Image.asset(config.iconPath,
                    height: 48,
                    width: 48,
                    errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events,
                        size: 48, color: Colors.amber))
              else
                const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
              const SizedBox(height: 8),
              Text(
                config.name,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificatesTab(
      BuildContext context, String userId, AppLocalizations l10n) {
    final _gamificationService = GamificationService();

    return StreamBuilder<List<UserCertificate>>(
      stream: _gamificationService.getUserCertificates(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(l10n.noCertificates));
        }

        final certs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: certs.length,
          itemBuilder: (context, index) {
            final cert = certs[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium,
                    color: Colors.purple, size: 40),
                title: Text(cert.title),
                subtitle: Text(cert.description),
                trailing: const Icon(Icons.download),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Downloading certificate...")));
                },
              ),
            );
          },
        );
      },
    );
  }
}
