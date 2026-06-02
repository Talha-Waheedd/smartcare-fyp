// FILE: lib/screens/doctor/appointments_screen.dart
// PURPOSE: Doctor manages appointment requests: accept / reject / reschedule /
//          complete / cancel. Three tabs: Pending, Upcoming, Past.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _service = AppointmentService();
  String? _doctorId;

  static const _c1 = AppColors.doctor;

  @override
  void initState() {
    super.initState();
    _doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (_doctorId == null) {
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

  Future<void> _setStatus(AppointmentModel appt, AppointmentStatus status) async {
    try {
      await _service.updateStatus(appt.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Appointment ${status.label.toLowerCase()}'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Action failed: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _reschedule(AppointmentModel appt) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appt.slotDate.isAfter(DateTime.now())
          ? appt.slotDate
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.slotDate),
    );
    if (time == null) return;

    final newSlot =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final endMinutes = time.hour * 60 + time.minute + 30;
    final endLabel =
        '${(endMinutes ~/ 60).toString().padLeft(2, '0')}:${(endMinutes % 60).toString().padLeft(2, '0')}';
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - $endLabel';

    try {
      await _service.reschedule(appt.id, newSlot, label);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment rescheduled'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reschedule failed: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doctorId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: _c1,
          foregroundColor: Colors.white,
          title: const Text('Appointments'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: StreamBuilder<List<AppointmentModel>>(
          stream: _service.getDoctorAppointments(_doctorId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _c1));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error)));
            }
            final all = snapshot.data ?? [];
            final now = DateTime.now();

            final pending = all
                .where((a) => a.status == AppointmentStatus.pending)
                .toList();
            final upcoming = all
                .where((a) =>
                    (a.status == AppointmentStatus.accepted ||
                        a.status == AppointmentStatus.rescheduled) &&
                    a.slotDate.isAfter(now))
                .toList();
            final past = all
                .where((a) =>
                    a.status == AppointmentStatus.completed ||
                    a.status == AppointmentStatus.rejected ||
                    a.status == AppointmentStatus.cancelled ||
                    ((a.status == AppointmentStatus.accepted ||
                            a.status == AppointmentStatus.rescheduled) &&
                        !a.slotDate.isAfter(now)))
                .toList();

            return TabBarView(
              children: [
                _list(pending, 'No pending requests'),
                _list(upcoming, 'No upcoming appointments'),
                _list(past, 'No past appointments'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(List<AppointmentModel> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appt: items[i],
        onAccept: () => _setStatus(items[i], AppointmentStatus.accepted),
        onReject: () => _setStatus(items[i], AppointmentStatus.rejected),
        onComplete: () => _setStatus(items[i], AppointmentStatus.completed),
        onCancel: () => _setStatus(items[i], AppointmentStatus.cancelled),
        onReschedule: () => _reschedule(items[i]),
      ),
    );
  }
}

Color _statusColor(AppointmentStatus s) {
  switch (s) {
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

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  const _AppointmentCard({
    required this.appt,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onCancel,
    required this.onReschedule,
  });

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appt.status);
    final isPending = appt.status == AppointmentStatus.pending;
    final isActive = appt.status == AppointmentStatus.accepted ||
        appt.status == AppointmentStatus.rescheduled;

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
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.doctor.withOpacity(0.12),
                  child: Text(
                    appt.patientName.isNotEmpty
                        ? appt.patientName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                        color: AppColors.doctor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.patientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${_fmtDate(appt.slotDate)}  ·  ${appt.slotLabel}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(appt.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            if (appt.reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Reason: ${appt.reason}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ],
            if (isPending || isActive) ...[
              const Divider(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isPending) ...[
                    _actionBtn('Accept', Icons.check, AppColors.success, onAccept),
                    _actionBtn('Reject', Icons.close, AppColors.error, onReject),
                  ],
                  if (isActive) ...[
                    _actionBtn('Complete', Icons.done_all, AppColors.doctor,
                        onComplete),
                    _actionBtn('Cancel', Icons.cancel_outlined,
                        AppColors.error, onCancel),
                  ],
                  _actionBtn('Reschedule', Icons.event_repeat,
                      AppColors.primary, onReschedule),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
