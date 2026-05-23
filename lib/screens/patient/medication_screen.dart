// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/medication_screen.dart
// PURPOSE: Shows patient's medication list. Each card shows name, dosage,
//          times. Patient can mark as taken, edit, or delete.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final medicationService = MedicationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      // FAB to add new medication
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<MedicationModel>>(
        stream: medicationService.getMedications(uid),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final medications = snapshot.data ?? [];

          // ── Empty state ──────────────────────────────────────────────
          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No medications yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first medication\nand set daily reminders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // ── Medication cards ─────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return _MedicationCard(
                medication: med,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddMedicationScreen(existingMed: med),
                  ),
                ),
                onDelete: () => _confirmDelete(context, med, medicationService),
                onMarkTaken: () => medicationService.logMedicationTaken(uid, med.id),
              );
            },
          );
        },
      ),
    );
  }

  // ── Delete confirmation dialog ──────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    MedicationModel med,
    MedicationService service,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
            'Remove "${med.name}" from your list? This will also cancel its reminders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              // Cancel scheduled notifications for this medication
              final baseId = med.id.hashCode.abs() % 100000;
              await NotificationService().cancelMedicationReminders(
                baseNotificationId: baseId,
                timesCount: med.times.length,
              );
              // Soft delete from Firestore
              await service.deleteMedication(med.userId, med.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${med.name} removed.')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Medication Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkTaken;

  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top row: name + menu ────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication,
                      color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        medication.dosage,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // 3-dot menu
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 20),

            // ── Frequency ───────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.repeat, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(medication.frequency,
                    style: const TextStyle(fontSize: 13)),
              ],
            ),

            const SizedBox(height: 8),

            // ── Times ───────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              children: medication.times.map((t) {
                return Chip(
                  avatar:
                      const Icon(Icons.access_time, size: 14),
                  label: Text(t,
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue.shade50,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            // ── Instructions ────────────────────────────────────────────
            if (medication.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      medication.instructions,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // ── Mark as Taken button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  onMarkTaken();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${medication.name} marked as taken ✓'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark as Taken'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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