// FILE: lib/screens/patient/patient_screen.dart
// Full polished patient dashboard — all tiles connected

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'medication_screen.dart';
import 'ai_suggestions_screen.dart';
import 'health_record_screen.dart';
import 'patient_prescriptions_screen.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final MedicationService _medService = MedicationService();
  final NotificationService _notifService = NotificationService();
  String _name = '';
  bool _notifInit = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _initNotifications();
  }

  Future<void> _loadName() async {
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
    if (_notifInit) return;
    try {
      await _notifService.initialize();
      await _notifService.saveFCMToken(_uid);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SmartCare'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications — coming soon')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadName(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Header ──────────────────────────────────────
              DashboardHeader(
                greeting: '$_greeting,',
                name: _name.isNotEmpty ? _name : '...',
                subtitle: 'How are you feeling today?',
                chips: [const RoleBadge(role: 'patient')],
              ),

              // ── Today's Medications Card ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TodaysMedsCard(uid: _uid, medService: _medService),
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
                  childAspectRatio: 1.25,
                  children: [
                    _ActionTile(
                      icon: Icons.medication_rounded,
                      label: 'Medications',
                      subtitle: 'Manage & reminders',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MedicationScreen())),
                    ),
                    _ActionTile(
                      icon: Icons.folder_open_rounded,
                      label: 'Health Records',
                      subtitle: 'Upload & view files',
                      color: AppColors.success,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const HealthRecordScreen())),
                    ),
                    _ActionTile(
                      icon: Icons.psychology_rounded,
                      label: 'AI Suggestions',
                      subtitle: 'Wellness tips',
                      color: const Color(0xFF7C3AED),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AiSuggestionScreen())),
                    ),
                    _ActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Prescriptions',
                      subtitle: 'From your doctor',
                      color: AppColors.warning,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const PatientPrescriptionsScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))
            ],
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
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${meds.length} active',
                        style: const TextStyle(
                            color: AppColors.primary,
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

// ── Action Tile ────────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}