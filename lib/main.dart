
import 'package:flutter/material.dart';

void main() {
  runApp(const PianoXApp());
}

// 1. Application entry point
class PianoXApp extends StatelessWidget {
  const PianoXApp({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PianoX',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const DashboardPage(),
    );
  }
}

// 2. Main dashboard
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const gold = Color(0xFFD4AF37);
  static const panel = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF181818),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PIANOX',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your musical journey',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 40),

                const SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: true,
                ),
                const SidebarItem(
                  icon: Icons.piano,
                  label: 'Play Piano',
                ),
                const SidebarItem(
                  icon: Icons.school,
                  label: 'Lessons',
                ),
                const SidebarItem(
                  icon: Icons.library_music,
                  label: 'Song Library',
                ),
                const SidebarItem(
                  icon: Icons.bar_chart,
                  label: 'My Progress',
                ),

                const Spacer(),

                const SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to PianoX',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learn, practise and master the piano.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Featured practice panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR NEXT STEP',
                          style: TextStyle(
                            color: gold,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Every great pianist starts somewhere.',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Start practising and build your musical skills '
                          'one lesson at a time.',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Practising'),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Your Learning Workspace',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Feature cards
                  const Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      FeatureCard(
                        icon: Icons.piano,
                        title: 'Virtual Piano',
                        description: 'Play and explore musical notes.',
                      ),
                      FeatureCard(
                        icon: Icons.school,
                        title: 'Lessons',
                        description: 'Develop your skills step by step.',
                      ),
                      FeatureCard(
                        icon: Icons.library_music,
                        title: 'Song Library',
                        description: 'Discover music to practise.',
                      ),
                      FeatureCard(
                        icon: Icons.insights,
                        title: 'Progress',
                        description: 'Track your musical development.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Reusable sidebar navigation item
class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? DashboardPage.gold.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? DashboardPage.gold : Colors.white60,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? DashboardPage.gold : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

// 4. Reusable dashboard feature card
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardPage.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: DashboardPage.gold,
            size: 30,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
