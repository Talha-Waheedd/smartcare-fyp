// FILE: lib/screens/patient/patient_screen.dart
// Full polished patient dashboard — all tiles connected

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'medication_screen.dart';
import 'ai_suggestions_screen.dart';
import 'health_record_screen.dart';
import 'patient_prescriptions_screen.dart';
import 'view_consultations_screen.dart';
import 'profile_screen.dart';
import 'doctor_search_screen.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  String? _uid;
  final MedicationService _medService = MedicationService();
  final NotificationService _notifService = NotificationService();
  String _name = '';
  bool _notifInit = false;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
      return;
    }
    _loadName();
    _initNotifications();
  }

  Future<void> _loadName() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() => _name = (data['name'] as String?) ??
            FirebaseAuth.instance.currentUser?.email ?? 'Patient');
      }
    } catch (_) {}
  }

  Future<void> _initNotifications() async {
    if (_notifInit || _uid == null) return;
    try {
      await _notifService.initialize();
      await _notifService.saveFCMToken(_uid!);
      _notifInit = true;
    } catch (_) {}
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeTab(),
          const MedicationScreen(),
          const HealthRecordScreen(),
          const AiSuggestionScreen(),
          _ProfileTab(name: _name, onLogout: _logout),
        ],
      ),
      bottomNavigationBar: _PatientBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadName(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Custom gradient hero header (replaces AppBar) ─────────
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 30),
                decoration: const BoxDecoration(
                  gradient: AppGradients.patientHeader,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332D6BFF),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar: logo + actions
                      Row(
                        children: [
                          const AppBarLogo(),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Notifications — coming soon')),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Greeting + illustration
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_greeting,',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.85),
                                          fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                      _name.isNotEmpty ? '$_name!' : '...',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('How are you feeling today?',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 13)),
                                  const SizedBox(height: 12),
                                  const RoleBadge(role: 'patient'),
                                ],
                              ),
                            ),
                            Icon(Icons.monitor_heart_rounded,
                                size: 60,
                                color: Colors.white.withOpacity(0.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Today's Medications Card ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 100),
                from: 30,
                child: _TodaysMedsCard(uid: _uid!, medService: _medService),
              ),
            ),

            // ── Appointments ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text('Appointments',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  from: 30,
                  child: _ConsultationCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'See Appointments',
                    subtitle: 'View your booking history',
                    gradient: const [
                      AppColors.primary,
                      AppColors.primaryDark
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ViewConsultationsScreen()),
                    ),
                  ),
                ),
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _ActionTile(
                    index: 0,
                    icon: Icons.medication_rounded,
                    label: 'Medications',
                    subtitle: 'Manage & reminders',
                    gradient: const [AppColors.primary, Color(0xFF5B8FFF)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MedicationScreen())),
                  ),
                  _ActionTile(
                    index: 1,
                    icon: Icons.folder_open_rounded,
                    label: 'Health Records',
                    subtitle: 'Upload & view files',
                    gradient: const [AppColors.secondary, Color(0xFF00E5C0)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const HealthRecordScreen())),
                  ),
                  _ActionTile(
                    index: 2,
                    icon: Icons.psychology_rounded,
                    label: 'Wellness Tips',
                    subtitle: 'Wellness tips',
                    gradient: const [Color(0xFF7B5EA7), Color(0xFFA78BDB)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AiSuggestionScreen())),
                  ),
                  _ActionTile(
                    index: 3,
                    icon: Icons.receipt_long_rounded,
                    label: 'Prescriptions',
                    subtitle: 'From your doctor',
                    gradient: const [AppColors.warning, Color(0xFFFFB84D)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PatientPrescriptionsScreen())),
                  ),
                  _ActionTile(
                    index: 4,
                    icon: Icons.search_rounded,
                    label: 'Find Doctors',
                    subtitle: 'Search by specialty',
                    gradient: const [AppColors.doctor, Color(0xFF4FB0FF)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const DoctorSearchScreen())),
                  ),
                  _ActionTile(
                    index: 5,
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    subtitle: 'Personal & medical info',
                    gradient: const [AppColors.patient, Color(0xFF00E5C0)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Today's Medications Card ───────────────────────────────────────────────────
class _TodaysMedsCard extends StatelessWidget {
  final String uid;
  final MedicationService medService;
  const _TodaysMedsCard({required this.uid, required this.medService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicationModel>>(
      stream: medService.getMedications(uid),
      builder: (context, snapshot) {
        final meds = snapshot.data ?? [];
        String nextDose = 'No medications scheduled';

        if (meds.isNotEmpty) {
          final now = TimeOfDay.now();
          final entries = <MapEntry<String, TimeOfDay>>[];
          for (final m in meds) {
            for (final t in m.times) {
              final parts = t.split(':');
              if (parts.length == 2) {
                entries.add(MapEntry(m.name,
                    TimeOfDay(hour: int.tryParse(parts[0]) ?? 0,
                              minute: int.tryParse(parts[1]) ?? 0)));
              }
            }
          }
          entries.sort((a, b) =>
              (a.value.hour * 60 + a.value.minute)
                  .compareTo(b.value.hour * 60 + b.value.minute));
          final nowMin = now.hour * 60 + now.minute;
          final upcoming = entries.where(
              (e) => (e.value.hour * 60 + e.value.minute) > nowMin).toList();
          if (upcoming.isNotEmpty) {
            final n = upcoming.first;
            final h = n.value.hour.toString().padLeft(2, '0');
            final m = n.value.minute.toString().padLeft(2, '0');
            nextDose = '${n.key} at $h:$m';
          } else if (entries.isNotEmpty) {
            nextDose = 'All doses taken for today 🎉';
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Medications",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppGradients.button,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text('${meds.length} active',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (meds.isEmpty)
                const Text(
                  'No medications added yet.\nTap Medications below to get started.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                )
              else ...[
                ...meds.take(2).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${m.name} — ${m.dosage}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ),
                        Text(m.times.isNotEmpty ? m.times.first : '',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ]),
                    )),
                if (meds.length > 2)
                  Text('+${meds.length - 2} more',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12)),
              ],
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.schedule,
                    size: 15, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Next: $nextDose',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.warning)),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ── Consultation gradient card ───────────────────────────────────────────────
class _ConsultationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ConsultationCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Tile ────────────────────────────────────────────────────────────────
class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int index;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * widget.index),
      from: 24,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.first.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(widget.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Patient Bottom Navigation Bar ───────────────────────────────────────────────
class _PatientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PatientBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    [Icons.home_rounded, Icons.home_outlined, 'Home'],
    [Icons.medication_rounded, Icons.medication_outlined, 'Medications'],
    [Icons.folder_rounded, Icons.folder_outlined, 'Records'],
    [Icons.psychology_rounded, Icons.psychology_outlined, 'AI Tips'],
    [Icons.person_rounded, Icons.person_outline, 'Profile'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.nav),
          topRight: Radius.circular(AppRadius.nav),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x142D6BFF),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.nav),
          topRight: Radius.circular(AppRadius.nav),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == currentIndex;
                final item = _items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 5,
                          width: selected ? 5 : 0,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AnimatedScale(
                          scale: selected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: Icon(
                            selected
                                ? item[0] as IconData
                                : item[1] as IconData,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item[2] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile tab (simple info card) ──────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  const _ProfileTab({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              decoration: const BoxDecoration(
                gradient: AppGradients.patientHeader,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text('My Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 14),
                    Text(name.isNotEmpty ? name : 'Patient',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileInfoCard(
                    icon: Icons.person_rounded,
                    title: 'Personal & Medical Info',
                    subtitle: 'Edit your full profile details',
                    color: AppColors.patient,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'My Appointments',
                    subtitle: 'View your booking history',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ViewConsultationsScreen())),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Log out of your account',
                    color: AppColors.error,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}