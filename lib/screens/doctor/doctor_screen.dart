// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/doctor/doctor_screen.dart
// PURPOSE: Doctor's main dashboard showing:
//   - Welcome header with doctor name
//   - Stats row (total patients, total consultations)
//   - Searchable patient list with tap to view details
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';
import '../auth/login_screen.dart';
import 'patient_detail_screen.dart';

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
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() as Map<String, dynamic>?;
      setState(() {
        _doctorName = (data?['name'] as String?) ?? 'Doctor';
      });
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('SmartCare'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(),

          // ── Stats Row ───────────────────────────────────────────────────
          _buildStatsRow(),

          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Section label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Text('My Patients',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _doctorService.getPatients(),
                  builder: (context, snap) {
                    final count = snap.data?.length ?? 0;
                    return Text('$count total',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13));
                  },
                ),
              ],
            ),
          ),

          // ── Patient List ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _doctorService.getPatients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var patients = snapshot.data ?? [];

                // Filter by search
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
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No patients match "$_searchQuery"'
                              : 'No patients registered yet',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final name =
                        (patient['name'] as String?) ?? 'Unknown';
                    final email =
                        (patient['email'] as String?) ?? '';
                    final patientId = patient['id'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Colors.blue.shade100,
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(email,
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey),
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

  // ── Header banner ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back,',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            _doctorName.isNotEmpty ? 'Dr. $_doctorName' : '...',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('DOCTOR',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Total patients
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _doctorService.getPatients(),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return _StatCard(
                  icon: Icons.people,
                  label: 'Patients',
                  value: '$count',
                  color: Colors.blue,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Total consultations by this doctor
          Expanded(
            child: StreamBuilder(
              stream:
                  _doctorService.getDoctorConsultations(_doctorId),
              builder: (context, snap) {
                final count =
                    (snap.data as List?)?.length ?? 0;
                return _StatCard(
                  icon: Icons.note_alt_outlined,
                  label: 'Consultations',
                  value: '$count',
                  color: Colors.green,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}