// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/doctor/patient_detail_screen.dart
// PURPOSE: Doctor's view of a specific patient. Three tabs:
//   Tab 1 — Medications (read-only, patient's current meds)
//   Tab 2 — Consultations (doctor adds notes here)
//   Tab 3 — Prescriptions (doctor creates prescriptions here)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/doctor_service.dart';
import '../../models/medication_model.dart';
import '../../models/consultation_model.dart';
import '../../models/prescription_model.dart';
import 'add_consultation_screen.dart';
import 'add_prescription_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final doctorService = DoctorService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patientName),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.medication, size: 18), text: 'Medications'),
              Tab(icon: Icon(Icons.note_alt, size: 18), text: 'Consultations'),
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Prescriptions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Medications (read-only) ───────────────────────────
            _MedicationsTab(
              stream: doctorService.getPatientMedications(patientId),
            ),

            // ── Tab 2: Consultations ──────────────────────────────────────
            _ConsultationsTab(
              stream: doctorService.getPatientConsultations(patientId),
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

            // ── Tab 3: Prescriptions ──────────────────────────────────────
            _PrescriptionsTab(
              stream: doctorService.getPatientPrescriptions(patientId),
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Medications — read-only view of patient's current medications
// ─────────────────────────────────────────────────────────────────────────────
class _MedicationsTab extends StatelessWidget {
  final Stream<List<MedicationModel>> stream;
  const _MedicationsTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicationModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final meds = snapshot.data ?? [];

        if (meds.isEmpty) {
          return _emptyState(
            icon: Icons.medication_outlined,
            message: 'No active medications recorded.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meds.length,
          itemBuilder: (context, index) {
            final med = meds[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(med.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const Spacer(),
                        // Read-only badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('VIEW ONLY',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow('Dosage', med.dosage),
                    _infoRow('Frequency', med.frequency),
                    _infoRow('Times', med.times.join(', ')),
                    if (med.instructions.isNotEmpty)
                      _infoRow('Instructions', med.instructions),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Consultations
// ─────────────────────────────────────────────────────────────────────────────
class _ConsultationsTab extends StatelessWidget {
  final Stream<List<ConsultationModel>> stream;
  final VoidCallback onAdd;
  const _ConsultationsTab({required this.stream, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FAB to add new consultation note
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: StreamBuilder<List<ConsultationModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final consultations = snapshot.data ?? [];

          if (consultations.isEmpty) {
            return _emptyState(
              icon: Icons.note_alt_outlined,
              message: 'No consultation notes yet.\nTap + to add a note.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final c = consultations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(c.createdAt),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          const Spacer(),
                          Text('Dr. ${c.doctorName}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (c.diagnosis.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.medical_information,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Diagnosis: ${c.diagnosis}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(c.notes,
                          style: const TextStyle(fontSize: 14)),
                      if (c.followUpDate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Follow-up: ${c.followUpDate}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green)),
                          ],
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Prescriptions
// ─────────────────────────────────────────────────────────────────────────────
class _PrescriptionsTab extends StatelessWidget {
  final Stream<List<PrescriptionModel>> stream;
  final VoidCallback onAdd;
  const _PrescriptionsTab({required this.stream, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return _emptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No prescriptions yet.\nTap + to create one.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final p = prescriptions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('Prescription — ${_formatDate(p.createdAt)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('Dr. ${p.doctorName}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                      const Divider(height: 16),
                      // List medicines
                      ...p.medicines.map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 7, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${med.name} — ${med.dosage}',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        '${med.frequency} · ${med.duration}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                      if (med.instructions.isNotEmpty)
                                        Text(med.instructions,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (p.notes.isNotEmpty) ...[
                        const Divider(height: 12),
                        Text('Notes: ${p.notes}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                      if (p.validUntil.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.event_available,
                                size: 13, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Valid until: ${p.validUntil}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.green)),
                          ],
                        ),
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

// ── Shared helpers ─────────────────────────────────────────────────────────────
Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}