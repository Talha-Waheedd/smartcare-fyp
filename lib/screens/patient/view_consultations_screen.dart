import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'doctor_search_screen.dart';
import 'add_review_screen.dart';

class ViewConsultationsScreen extends StatefulWidget {
  const ViewConsultationsScreen({super.key});

  @override
  State<ViewConsultationsScreen> createState() =>
      _ViewConsultationsScreenState();
}

class _ViewConsultationsScreenState extends State<ViewConsultationsScreen> {
  final _apptService = AppointmentService();
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

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.accepted:
        return AppColors.success;
      case AppointmentStatus.rescheduled:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.doctor;
      case AppointmentStatus.rejected:
      case AppointmentStatus.cancelled:
        return AppColors.error;
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
        title: Text('My Appointments',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _apptService.getPatientAppointments(_patientId!),
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

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
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
                          child: Icon(Icons.calendar_month_outlined,
                              size: 56,
                              color: _accent.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 20),
                        Text('No appointments yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Use Find Doctors on your dashboard to book your first appointment.',
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
                                builder: (_) => const DoctorSearchScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.search_rounded),
                          label: Text('Find Doctors',
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
              itemCount: appointments.length,
              itemBuilder: (_, i) {
                final a = appointments[i];
                final statusColor = _statusColor(a.status);

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
                              tag: 'appointment_${a.id}',
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    _accent.withValues(alpha: 0.12),
                                child: Text(
                                  a.doctorName.isNotEmpty
                                      ? a.doctorName[0].toUpperCase()
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
                                  Text('Dr. ${a.doctorName}',
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
                                          '${_formatDate(a.slotDate)} · ${a.slotLabel}',
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
                              child: Text(a.status.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  )),
                            ),
                          ],
                        ),
                        if (a.reason.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Reason: ${a.reason}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                )),
                          ),
                        ],
                        if (a.status == AppointmentStatus.completed) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddReviewScreen(
                                    doctorId: a.doctorId,
                                    doctorName: a.doctorName,
                                    patientId: _patientId!,
                                    patientName: a.patientName.isNotEmpty
                                        ? a.patientName
                                        : 'Patient',
                                    consultationId: a.consultationId.isNotEmpty
                                        ? a.consultationId
                                        : a.id,
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
