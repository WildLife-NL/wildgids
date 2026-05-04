import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  static const Color primaryGreen = AppColors.primaryGreen;
  static const Color softGreen = Color(0xFFEAF7E6);
  static const Color pageBackground = Color(0xFFF6FAF3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mijn voortgang',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ProgressHeaderCard(),
            SizedBox(height: 24),

            SectionTitle(title: 'Statistieken'),
            SizedBox(height: 12),
            StatsGrid(),
            SizedBox(height: 24),

            SectionTitle(title: 'Recente badges'),
            SizedBox(height: 12),
            BadgeRow(),
            SizedBox(height: 24),

            SectionTitle(title: 'Actieve uitdagingen'),
            SizedBox(height: 12),
            ChallengeCard(
              icon: Icons.forest,
              title: 'Spot 3 bosdieren',
              subtitle: 'Nog 1 dier te gaan',
              progress: 0.66,
              value: '2/3',
              xp: '+50 XP',
            ),
            ChallengeCard(
              icon: Icons.wb_sunny,
              title: 'Ochtend ontdekker',
              subtitle: 'Doe een waarneming voor 09:00',
              progress: 0.0,
              value: '0/1',
              xp: '+30 XP',
            ),
            ChallengeCard(
              icon: Icons.location_on,
              title: 'Nieuwe plek',
              subtitle: 'Bezoek een nieuwe locatie',
              progress: 1.0,
              value: '1/1',
              xp: '+40 XP',
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressHeaderCard extends StatelessWidget {
  const ProgressHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ChallengeScreen.primaryGreen,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: ChallengeScreen.primaryGreen,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Natuur Ontdekker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Level 3',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '680 / 1000 XP tot Level 4',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderDefault.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ChallengeScreen.primaryGreen, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        StatCard(icon: Icons.visibility, value: '27', label: 'Waarnemingen'),
        StatCard(icon: Icons.pets, value: '14', label: 'Soorten gezien'),
        StatCard(icon: Icons.place, value: '8', label: 'Locaties'),
        StatCard(icon: Icons.workspace_premium, value: '6', label: 'Badges'),
      ],
    );
  }
}

class BadgeRow extends StatelessWidget {
  const BadgeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          BadgeItem(icon: Icons.forest, label: 'Bos'),
          BadgeItem(icon: Icons.pets, label: 'Dieren'),
          BadgeItem(icon: Icons.camera_alt, label: 'Foto'),
          BadgeItem(icon: Icons.lock, label: 'Locked', locked: true),
        ],
      ),
    );
  }
}

class BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool locked;

  const BadgeItem({
    super.key,
    required this.icon,
    required this.label,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.35 : 1,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: ChallengeScreen.softGreen,
              borderRadius: BorderRadius.circular(18),
             
            ),
            child: Icon(
              icon,
              color: ChallengeScreen.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final String value;
  final String xp;

  const ChallengeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.value,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ChallengeScreen.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: ChallengeScreen.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ChallengeScreen.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            xp,
            style: const TextStyle(
              color: ChallengeScreen.primaryGreen,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.borderDefault.withOpacity(0.6)),
   
  );
}