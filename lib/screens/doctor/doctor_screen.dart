// FILE: lib/screens/doctor/doctor_screen.dart
// SELF-CONTAINED: PatientDetailScreen is defined in this same file
// This eliminates all import resolution errors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/doctor_service.dart';
import '../../models/medication_model.dart';
import '../../models/consultation_model.dart';
import '../../models/prescription_model.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'add_consultation_screen.dart';
import 'add_prescription_screen.dart';
import 'doctor_profile_screen.dart';
import 'schedule_screen.dart';
import 'appointments_screen.dart';
import '../../models/health_record_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOCTOR DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});
  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _doctorService = DoctorService();
  final _searchController = TextEditingController();
  String _doctorName = '';
  String _doctorId = '';
  String _searchQuery = '';

  static const _c1 = Color(0xFF0A84FF);

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _doctorId = user.uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      setState(() => _doctorName = (data?['name'] as String?) ?? 'Doctor');
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _c1,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.doctorHeader),
        ),
        title: const AppBarLogo(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DoctorProfileScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: AppGradients.doctorHeader,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x330A84FF),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        _doctorName.isNotEmpty ? 'Dr. $_doctorName' : '...',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('DOCTOR',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.medical_services_rounded,
                    size: 64, color: Colors.white.withOpacity(0.30)),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _doctorService.getMyPatients(_doctorId),
                    builder: (_, snap) {
                      if (snap.hasError) {
                        return _StatBox(
                          icon: Icons.people_alt_outlined,
                          value: '—',
                          label: 'Patients',
                          color: _c1,
                        );
                      }
                      return _StatBox(
                      icon: Icons.people_alt_outlined,
                      value: '${snap.data?.length ?? 0}',
                      label: 'Patients',
                      color: _c1,
                    );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder(
                    stream: _doctorService
                        .getDoctorConsultations(_doctorId),
                    builder: (_, snap) => _StatBox(
                      icon: Icons.note_alt_outlined,
                      value:
                          '${(snap.data as List?)?.length ?? 0}',
                      label: 'Consultations',
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DashboardAction(
                    icon: Icons.calendar_month_outlined,
                    label: 'Appointments',
                    color: _c1,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardAction(
                    icon: Icons.schedule_outlined,
                    label: 'My Schedule',
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScheduleScreen())),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(50),
                boxShadow: AppShadows.card,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          })
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                        const BorderSide(color: _c1, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text('My Patients',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _doctorService.getMyPatients(_doctorId),
                  builder: (_, snap) {
                    if (snap.hasError) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${snap.data?.length ?? 0} total',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                  },
                ),
              ],
            ),
          ),

          // Patient list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _doctorService.getMyPatients(_doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _c1));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading patients: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                var patients = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  patients = patients.where((p) {
                    final name =
                        (p['name'] as String? ?? '').toLowerCase();
                    final email =
                        (p['email'] as String? ?? '').toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (patients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No patients match "$_searchQuery"'
                              : 'No patients with accepted appointments yet',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    final name =
                        (p['name'] as String?) ?? 'Unknown';
                    final email =
                        (p['email'] as String?) ?? '';
                    final patientId = p['id'] as String;
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'P';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: AppShadows.card,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: AppGradients.doctorHeader,
                            shape: BoxShape.circle,
                          ),
                          child: Text(initial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        subtitle: Text(email,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _c1.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: _c1),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(
                              patientId: patientId,
                              patientName: name,
                              doctorId: _doctorId,
                              doctorName: _doctorName,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATIENT DETAIL SCREEN — 3 tabs
// ─────────────────────────────────────────────────────────────────────────────
class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
  });

  static const _c1 = Color(0xFF0891B2);

  @override
  Widget build(BuildContext context) {
    final service = DoctorService();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: _c1,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patientName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Text('Patient Record',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white70)),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(
                  icon: Icon(Icons.medication_outlined, size: 18),
                  text: 'Medications'),
              Tab(
                  icon: Icon(Icons.note_alt_outlined, size: 18),
                  text: 'Consultations'),
              Tab(
                  icon:
                      Icon(Icons.receipt_long_outlined, size: 18),
                  text: 'Prescriptions'),
              Tab(
                  icon: Icon(Icons.folder_open_outlined, size: 18),
                  text: 'Reports'),
            ],
          ),
        ),
        body: Column(
          children: [
            _PatientSummary(
                future: service.getPatientProfile(patientId)),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Medications
                  _MedicationsTab(
                      stream:
                          service.getPatientMedications(patientId)),
                  // Tab 2: Consultations
                  _ConsultationsTab(
                    stream:
                        service.getPatientConsultations(patientId),
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddConsultationScreen(
                          patientId: patientId,
                          patientName: patientName,
                          doctorId: doctorId,
                          doctorName: doctorName,
                        ),
                      ),
                    ),
                  ),
                  // Tab 3: Prescriptions
                  _PrescriptionsTab(
                    stream:
                        service.getPatientPrescriptions(patientId),
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPrescriptionScreen(
                          patientId: patientId,
                          patientName: patientName,
                          doctorId: doctorId,
                          doctorName: doctorName,
                        ),
                      ),
                    ),
                  ),
                  // Tab 4: Reports (patient-uploaded files, read-only)
                  _ReportsTab(
                      stream:
                          service.getPatientHealthRecords(patientId)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Patient medical summary header ──────────────────────────────────────────────
class _PatientSummary extends StatelessWidget {
  final Future<UserModel?> future;
  const _PatientSummary({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: future,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SizedBox.shrink();
        final chips = <Widget>[];
        if (user.bloodGroup.isNotEmpty) {
          chips.add(_chip(Icons.bloodtype_outlined, 'Blood: ${user.bloodGroup}',
              AppColors.error));
        }
        if (user.allergies.isNotEmpty) {
          chips.add(_chip(Icons.warning_amber_outlined,
              'Allergies: ${user.allergies}', AppColors.warning));
        }
        if (user.emergencyContact.isNotEmpty) {
          chips.add(_chip(Icons.emergency_outlined,
              'Emergency: ${user.emergencyContact}', AppColors.doctor));
        }
        if (user.phone.isNotEmpty) {
          chips.add(_chip(Icons.phone_outlined, user.phone, AppColors.success));
        }
        if (chips.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medical Summary',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Tab 4: Reports (patient-uploaded files) ─────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  final Stream<List<HealthRecordModel>> stream;
  const _ReportsTab({required this.stream});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file.')));
    }
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthRecordModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.doctor));
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const _EmptyTab(
            icon: Icons.folder_open_outlined,
            message: 'This patient has not uploaded any reports.',
            color: AppColors.doctor,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (_, i) {
            final r = records[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                onTap: () => _open(context, r.fileUrl),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: r.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.icon, color: r.iconColor),
                ),
                title: Text(r.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${r.fileName}  ·  ${_fmt(r.uploadedAt)}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.open_in_new,
                    size: 18, color: AppColors.primary),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab 1: Medications ─────────────────────────────────────────────────────────
class _MedicationsTab extends StatelessWidget {
  final Stream<List<MedicationModel>> stream;
  const _MedicationsTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicationModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary));
        }
        final meds = snapshot.data ?? [];
        if (meds.isEmpty) {
          return const _EmptyTab(
            icon: Icons.medication_outlined,
            message: 'No active medications for this patient.',
            color: AppColors.primary,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meds.length,
          itemBuilder: (_, i) {
            final med = meds[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication,
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(med.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: const Text('VIEW ONLY',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _row('Dosage', med.dosage),
                    _row('Frequency', med.frequency),
                    _row('Times', med.times.join('  ·  ')),
                    if (med.instructions.isNotEmpty)
                      _row('Instructions', med.instructions),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 90,
                  child: Text('$label:',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12))),
              Expanded(
                  child: Text(value,
                      style: const TextStyle(fontSize: 13))),
            ]),
      );
}

// ── Tab 2: Consultations ───────────────────────────────────────────────────────
class _ConsultationsTab extends StatelessWidget {
  final Stream<List<ConsultationModel>> stream;
  final VoidCallback onAdd;
  const _ConsultationsTab(
      {required this.stream, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: const Color(0xFF0891B2),
      ),
      body: StreamBuilder<List<ConsultationModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const _EmptyTab(
              icon: Icons.note_alt_outlined,
              message:
                  'No consultation notes yet.\nTap + to add.',
              color: Color(0xFF0891B2),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(_fmt(c.createdAt),
                            style: const TextStyle(
                                color:
                                    AppColors.textSecondary,
                                fontSize: 12)),
                        const Spacer(),
                        Text('Dr. ${c.doctorName}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0891B2),
                                fontWeight:
                                    FontWeight.w500)),
                      ]),
                      if (c.diagnosis.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.warning
                                    .withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(
                                Icons
                                    .medical_information_outlined,
                                size: 14,
                                color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    'Diagnosis: ${c.diagnosis}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.warning))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(c.notes,
                          style: const TextStyle(
                              fontSize: 14, height: 1.5)),
                      if (c.followUpDate.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.event_outlined,
                              size: 14,
                              color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                              'Follow-up: ${c.followUpDate}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight:
                                      FontWeight.w500)),
                        ]),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Tab 3: Prescriptions ───────────────────────────────────────────────────────
class _PrescriptionsTab extends StatelessWidget {
  final Stream<List<PrescriptionModel>> stream;
  final VoidCallback onAdd;
  const _PrescriptionsTab(
      {required this.stream, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
        backgroundColor: AppColors.success,
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.success));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const _EmptyTab(
              icon: Icons.receipt_long_outlined,
              message:
                  'No prescriptions yet.\nTap + to create one.',
              color: AppColors.success,
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.receipt_long,
                              color: AppColors.success,
                              size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Prescription — ${_fmt(p.createdAt)}',
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 14)),
                              Text('Dr. ${p.doctorName}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors
                                          .textSecondary)),
                            ],
                          ),
                        ),
                      ]),
                      const Divider(height: 16),
                      ...p.medicines.map((med) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 8),
                            child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin:
                                        const EdgeInsets.only(
                                            top: 5),
                                    width: 6,
                                    height: 6,
                                    decoration:
                                        const BoxDecoration(
                                            color: AppColors
                                                .success,
                                            shape: BoxShape
                                                .circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                            '${med.name}  •  ${med.dosage}',
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                fontSize: 13)),
                                        Text(
                                            '${med.frequency}  ·  ${med.duration}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary)),
                                        if (med.instructions
                                            .isNotEmpty)
                                          Text(
                                              med.instructions,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .warning)),
                                      ],
                                    ),
                                  ),
                                ]),
                          )),
                      if (p.validUntil.isNotEmpty) ...[
                        const Divider(height: 12),
                        Row(children: [
                          const Icon(
                              Icons.event_available_outlined,
                              size: 13,
                              color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                              'Valid until: ${p.validUntil}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight:
                                      FontWeight.w500)),
                        ]),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────────
String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyTab(
      {required this.icon,
      required this.message,
      required this.color});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14)),
          ],
        ),
      );
}

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DashboardAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ]),
        ]),
      );
}