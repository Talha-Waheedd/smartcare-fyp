// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/medication_screen.dart
// PURPOSE: Shows patient's medication list. Each card shows name, dosage,
//          times. Patient can mark as taken, edit, or delete.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final uid = user.uid;
    final medicationService = MedicationService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medications'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.button),
        ),
      ),
      // FAB to add new medication
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.button(AppColors.primary),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Medication'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: StreamBuilder<List<MedicationModel>>(
        stream: medicationService.getMedications(uid),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_outlined,
                        size: 56, color: AppColors.primary),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No medications yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add your first medication\nand set daily reminders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
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
              return SlideInRight(
                delay: Duration(milliseconds: 50 * index),
                duration: const Duration(milliseconds: 350),
                from: 40,
                child: _MedicationCard(
                  medication: med,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddMedicationScreen(existingMed: med),
                    ),
                  ),
                  onDelete: () =>
                      _confirmDelete(context, med, medicationService),
                  onMarkTaken: () =>
                      medicationService.logMedicationTaken(uid, med.id),
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left gradient accent bar
              Container(
                width: 5,
                decoration: const BoxDecoration(gradient: AppGradients.button),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: name + menu ──────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medication_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medication.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  medication.dosage,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // 3-dot menu
                          PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                                    style:
                                        TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // ── Frequency ─────────────────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.repeat,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(medication.frequency,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Times (gradient pill chips) ───────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: medication.times.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time,
                                    size: 13, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(t,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // ── Instructions ──────────────────────────────────
                      if (medication.instructions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                medication.instructions,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // ── Mark as Taken button ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onMarkTaken();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${medication.name} marked as taken'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 18),
                          label: const Text('Mark as Taken'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(
                                color: AppColors.success, width: 1.5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}