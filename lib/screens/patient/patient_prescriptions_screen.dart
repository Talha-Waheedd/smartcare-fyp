// FILE: lib/screens/patient/patient_prescriptions_screen.dart
// PURPOSE: Patient can VIEW prescriptions created by doctors.
//          READ-ONLY — patients cannot create or edit prescriptions.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/prescription_model.dart';
import '../../theme/app_theme.dart';

class PatientPrescriptionsScreen extends StatelessWidget {
  const PatientPrescriptionsScreen({super.key});

  Stream<List<PrescriptionModel>> _stream(String uid) {
    return FirebaseFirestore.instance
        .collection('prescriptions')
        .where('patientId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PrescriptionModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: AppColors.success,
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: _stream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.success),
                  ),
                  const SizedBox(height: 16),
                  const Text('No prescriptions yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Prescriptions from your doctor\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (_, i) {
              final p = prescriptions[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long,
                                color: AppColors.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prescribed by Dr. ${p.doctorName}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                                Text(_formatDate(p.createdAt),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          // Read-only badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('READ ONLY',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Medicines list
                      ...p.medicines.map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${med.name}  •  ${med.dosage}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${med.frequency}  ·  ${med.duration}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                      if (med.instructions.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.info_outline,
                                                  size: 12,
                                                  color: AppColors.warning),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  med.instructions,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.warning),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                      // Notes + valid until
                      if (p.notes.isNotEmpty) ...[
                        const Divider(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(p.notes,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                      if (p.validUntil.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_available,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text('Valid until: ${p.validUntil}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500)),
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