import 'package:flutter/material.dart';
import '../widgets/slant_clipper.dart';
import 'lists_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light blue-grey background
      body: SafeArea(
        child: Column(
          children: [
            // ── Top header ──
            ClipPath(
              clipper: TopSlantClipper(),
              child: Container(
                color: Colors.indigo,
                height: sh * 0.18,
                width: double.infinity,
                alignment: Alignment.center,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'NotiBac',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Middle body ──
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.school_rounded, size: 50, color: Colors.indigo),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'مرحباً بك!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'التطبيق الأذكى لحفظ التواريخ والأحداث التاريخية بكل سهولة من خلال نوافذ منبثقة تفاعلية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Status card showing app is ready
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded, color: Colors.indigo, size: 28),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'أضف أحداثك في قسم الإدارة، ثم فعّل الخدمة التلقائية من الإعدادات لتبدأ الاختبارات.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Action Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: 'الأحداث',
                              icon: Icons.calendar_month_rounded,
                              color: Colors.teal,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ListsPage()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: 'الإعدادات',
                              icon: Icons.settings_rounded,
                              color: Colors.blueGrey,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
