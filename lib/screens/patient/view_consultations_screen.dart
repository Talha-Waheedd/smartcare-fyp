import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'consult_doctors_screen.dart';
import 'add_review_screen.dart';

class ViewConsultationsScreen extends StatefulWidget {
  const ViewConsultationsScreen({super.key});

  @override
  State<ViewConsultationsScreen> createState() =>
      _ViewConsultationsScreenState();
}

class _ViewConsultationsScreenState extends State<ViewConsultationsScreen> {
  final _consultService = ConsultationService();
  String? _patientId;

  static const _accent = AppColors.doctor;

  @override
  void initState() {
    super.initState();
    _patientId = FirebaseAuth.instance.currentUser?.uid;
    if (_patientId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Color _statusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.active:
        return AppColors.success;
      case ConsultationStatus.completed:
        return AppColors.primary;
      case ConsultationStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.active:
        return 'Active';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_patientId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text('My Consultations',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ConsultationModel>>(
        stream: _consultService.getPatientConsultations(_patientId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: AppColors.error)),
            );
          }

          final consultations = snapshot.data ?? [];

          if (consultations.isEmpty) {
            return RefreshIndicator(
              color: _accent,
              onRefresh: () async => setState(() {}),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.history_rounded,
                              size: 56,
                              color: _accent.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 20),
                        Text('No consultations yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Tap Consult Doctors to start your first consultation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ConsultDoctorsScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.people_alt_outlined),
                          label: Text('Consult Doctors',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _accent,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: consultations.length,
              itemBuilder: (_, i) {
                final c = consultations[i];
                final statusColor = _statusColor(c.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: 'consultation_${c.id}',
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    _accent.withValues(alpha: 0.12),
                                child: Text(
                                  c.doctorName.isNotEmpty
                                      ? c.doctorName[0].toUpperCase()
                                      : 'D',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: _accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. ${c.doctorName}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 13,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                          _formatDate(c.consultationDate),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(_statusLabel(c.status),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  )),
                            ),
                          ],
                        ),
                        if (c.diagnosis.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Diagnosis: ${c.diagnosis}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.warning,
                                )),
                          ),
                        ],
                        if (c.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(c.notes,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              )),
                        ],
                        if (c.status == ConsultationStatus.completed) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddReviewScreen(
                                    doctorId: c.doctorId,
                                    doctorName: c.doctorName,
                                    patientId: _patientId!,
                                    patientName: c.patientName,
                                    consultationId: c.id,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.star_outline_rounded,
                                  size: 18),
                              label: Text('Rate Doctor',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
