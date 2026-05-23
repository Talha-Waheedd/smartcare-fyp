// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/patient_screen.dart
// UPDATED: AI Suggestions tile now opens AiSuggestionScreen (Phase 5)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'medication_screen.dart';
// import 'ai_suggestion_screen.dart';
import 'ai_suggestions_screen.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final MedicationService _medicationService = MedicationService();
  final NotificationService _notificationService = NotificationService();

  String _patientName = '';
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPatientName();
    _initNotifications();
  }

  Future<void> _loadPatientName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patientName = (data['name'] as String?) ??
              FirebaseAuth.instance.currentUser?.email ??
              'Patient';
        });
      }
    } catch (e) {
      debugPrint('Error loading name: $e');
    }
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    try {
      await _notificationService.initialize();
      await _notificationService.saveFCMToken(_uid);
      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('SmartCare'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification history — coming soon')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPatientName(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTodaysMedicationsCard(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_greeting,',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            _patientName.isNotEmpty ? _patientName : '...',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('How are you feeling today?',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Today's Medications ────────────────────────────────────────────────────
  Widget _buildTodaysMedicationsCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<MedicationModel>>(
        stream: _medicationService.getMedications(_uid),
        builder: (context, snapshot) {
          final meds = snapshot.data ?? [];
          final count = meds.length;

          String nextDose = 'No medications scheduled';
          if (meds.isNotEmpty) {
            final now = TimeOfDay.now();
            final allEntries = <MapEntry<String, TimeOfDay>>[];
            for (final m in meds) {
              for (final t in m.times) {
                final parts = t.split(':');
                if (parts.length == 2) {
                  final h = int.tryParse(parts[0]) ?? 0;
                  final min = int.tryParse(parts[1]) ?? 0;
                  allEntries
                      .add(MapEntry(m.name, TimeOfDay(hour: h, minute: min)));
                }
              }
            }
            allEntries.sort((a, b) =>
                (a.value.hour * 60 + a.value.minute)
                    .compareTo(b.value.hour * 60 + b.value.minute));
            final nowMin = now.hour * 60 + now.minute;
            final upcoming = allEntries
                .where((e) =>
                    (e.value.hour * 60 + e.value.minute) > nowMin)
                .toList();
            if (upcoming.isNotEmpty) {
              final next = upcoming.first;
              final h = next.value.hour.toString().padLeft(2, '0');
              final m = next.value.minute.toString().padLeft(2, '0');
              nextDose = '${next.key} at $h:$m';
            } else if (allEntries.isNotEmpty) {
              nextDose = 'All doses taken for today 🎉';
            }
          }

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Medications",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$count active',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (meds.isEmpty)
                    const Text(
                        'No medications added yet.\nTap Medications below to get started.',
                        style: TextStyle(color: Colors.grey))
                  else ...[
                    ...meds.take(2).map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 8, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text('${m.name} — ${m.dosage}',
                                      style: const TextStyle(fontSize: 13))),
                              Text(
                                  m.times.isNotEmpty ? m.times.first : '',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )),
                    if (meds.length > 2)
                      Text('+${meds.length - 2} more medications',
                          style: const TextStyle(
                              color: Colors.blue, fontSize: 12)),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Next: $nextDose',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.orange)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Quick Actions Grid ──────────────────────────────────────────────────────
  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _actionTile(
            icon: Icons.medication,
            label: 'Medications',
            color: Colors.blue,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MedicationScreen())),
          ),
          _actionTile(
            icon: Icons.folder_open,
            label: 'Health Records',
            color: Colors.green,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Health Records — coming soon')),
            ),
          ),
          // ✅ NOW CONNECTED to AiSuggestionScreen
          _actionTile(
            icon: Icons.psychology,
            label: 'AI Suggestions',
            color: Colors.purple,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AiSuggestionScreen())),
          ),
          _actionTile(
            icon: Icons.chat_outlined,
            label: 'Consultation',
            color: Colors.orange,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request consultation — coming soon')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}